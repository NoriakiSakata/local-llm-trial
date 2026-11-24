"""PRの差分をローカルLLM（OpenAI互換API）に読ませて、行ごとの指摘をレビューコメントとして付ける。

標準ライブラリと gh コマンドだけで動く（Python 3.9 以上）。
"""
import json
import os
import re
import subprocess
import sys
import urllib.request

REPO = os.environ["REPO"]
PR = os.environ["PR_NUMBER"]
HEAD_SHA = os.environ["HEAD_SHA"]
BASE_URL = os.environ["LLM_BASE_URL"].rstrip("/")
API_KEY = os.environ["LLM_API_KEY"]
MODEL = os.environ["LLM_MODEL"]

MAX_DIFF_CHARS = 60000  # これより大きいPRはスキップ
MAX_FINDINGS = 5
SKIP_FILES = re.compile(r"(\.lock$|\.g\.dart$|\.freezed\.dart$|\.(png|jpg|jpeg|gif|svg|ico|pdf)$|^pubspec\.lock$)")

SYSTEM = """あなたは経験豊富なコードレビュアーです。
PRの差分を読み、本当に直すべき問題だけを指摘してください。

指摘してよいもの:
- バグになりそうな処理（null、境界値、例外、非同期、状態の不整合など）
- PRの説明に書かれた目的と食い違う実装
- セキュリティ上の問題

指摘しないもの:
- 好みの問題、命名、フォーマット、細かいリファクタリング提案
- 差分に含まれない行についての推測

ルール:
- 指摘は最大5件。なければ0件でよい。
- line には差分の行頭にある R の番号（変更後のファイルの行番号）をそのまま使う。
- 日本語で、1件につき2〜3文で簡潔に書く。
- 出力は次のJSONだけ。前後に説明文を付けない。

{"summary": "PR全体の所感を1〜2文", "findings": [{"path": "ファイルパス", "line": 123, "body": "指摘内容"}]}
"""


def gh(*args, input_text=None):
    return subprocess.run(["gh", *args], check=True, capture_output=True, text=True, input=input_text).stdout


def annotate(diff):
    """差分の各行に変更後の行番号を付ける。コメント可能な (path, line) の集合も返す。"""
    out, valid = [], set()
    path, skip, right = None, False, 0
    for line in diff.splitlines():
        if line.startswith("diff --git"):
            path, skip = None, False
            continue
        if line.startswith("+++ "):
            p = line[4:]
            path = p[2:] if p.startswith("b/") else None
            skip = path is None or bool(SKIP_FILES.search(path))
            if not skip:
                out.append(f"\n=== {path} ===")
            continue
        if line.startswith(("--- ", "index ", "new file", "deleted file", "similarity", "rename ", "Binary")):
            continue
        if skip or path is None:
            continue
        m = re.match(r"@@ -\d+(?:,\d+)? \+(\d+)(?:,\d+)? @@", line)
        if m:
            right = int(m.group(1))
            out.append(line)
            continue
        if line.startswith("-"):
            out.append(f"      {line}")
        elif line.startswith("+") or line.startswith(" "):
            out.append(f"R{right:<5}{line}")
            valid.add((path, right))
            right += 1
    return "\n".join(out), valid


def ask_llm(prompt):
    body = json.dumps({
        "model": MODEL,
        "messages": [{"role": "system", "content": SYSTEM}, {"role": "user", "content": prompt}],
        "temperature": 0.2,
        "max_tokens": 4000,
    }).encode()
    req = urllib.request.Request(
        f"{BASE_URL}/chat/completions",
        data=body,
        headers={"Content-Type": "application/json", "Authorization": f"Bearer {API_KEY}"},
    )
    with urllib.request.urlopen(req, timeout=1500) as res:
        data = json.load(res)
    text = data["choices"][0]["message"]["content"] or ""
    text = re.sub(r"<think>.*?</think>", "", text, flags=re.S)
    m = re.search(r"\{.*\}", text, flags=re.S)
    if not m:
        raise ValueError("LLMの出力からJSONを取り出せませんでした")
    return json.loads(m.group(0))


def post_review(body, comments):
    payload = {"commit_id": HEAD_SHA, "event": "COMMENT", "body": body, "comments": comments}
    gh("api", f"repos/{REPO}/pulls/{PR}/reviews", "--method", "POST", "--input", "-", input_text=json.dumps(payload))


def main():
    info = json.loads(gh("pr", "view", PR, "--repo", REPO, "--json", "title,body"))
    diff = gh("pr", "diff", PR, "--repo", REPO)
    annotated, valid = annotate(diff)

    if not valid:
        post_review("🤖 ローカルLLMレビュー: レビュー対象の差分がありませんでした。", [])
        return
    if len(annotated) > MAX_DIFF_CHARS:
        post_review(f"🤖 ローカルLLMレビュー: 差分が大きいためスキップしました（{len(annotated):,}文字 / 上限 {MAX_DIFF_CHARS:,}文字）。", [])
        return

    prompt = f"# PRタイトル\n{info['title']}\n\n# PRの説明\n{info['body'] or '（なし）'}\n\n# 差分\n{annotated}"
    result = ask_llm(prompt)

    comments, orphans = [], []
    for f in (result.get("findings") or [])[:MAX_FINDINGS]:
        try:
            key = (f["path"], int(f["line"]))
        except (KeyError, TypeError, ValueError):
            continue
        if key in valid:
            comments.append({"path": key[0], "line": key[1], "side": "RIGHT", "body": f["body"]})
        else:
            orphans.append(f"- `{f.get('path')}` L{f.get('line')}: {f.get('body')}")

    body = f"🤖 ローカルLLMレビュー（{MODEL}）\n\n{result.get('summary', '')}"
    if not comments and not orphans:
        body += "\n\n指摘はありませんでした。"
    if orphans:
        body += "\n\n差分の行に付けられなかった指摘:\n" + "\n".join(orphans)
    body += "\n\n<sub>自動レビューです。最終判断は人が行ってください。</sub>"
    post_review(body, comments)
    print(f"posted: {len(comments)} inline, {len(orphans)} orphan")


if __name__ == "__main__":
    try:
        main()
    except Exception as e:  # 失敗してもPRに理由を残す
        print(f"error: {e}", file=sys.stderr)
        try:
            post_review(f"🤖 ローカルLLMレビュー: 失敗しました（{type(e).__name__}）。Actionsのログを確認してください。", [])
        except Exception:
            pass
        sys.exit(1)

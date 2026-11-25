"""PRの差分をローカルLLM（OpenAI互換API）に読ませて、行ごとの指摘をレビューコメントとして付ける。

REVIEW_MODE=basic : PRのタイトル・説明・差分だけを渡す
REVIEW_MODE=rich  : さらに、プロジェクトのルール、lib/ の構成、変更ファイルの全文、
                    変更したシンボルの参照箇所、関連イシュー、analyze/test の結果を渡す

標準ライブラリと gh コマンドだけで動く（Python 3.9 以上）。
"""
import json
import os
import re
import subprocess
import sys
import time
import urllib.request
from pathlib import Path

REPO = os.environ["REPO"]
PR = os.environ["PR_NUMBER"]
HEAD_SHA = os.environ["HEAD_SHA"]
BASE_URL = os.environ["LLM_BASE_URL"].rstrip("/")
API_KEY = os.environ["LLM_API_KEY"]
MODEL = os.environ["LLM_MODEL"]
MODE = os.environ.get("REVIEW_MODE", "basic")

MAX_DIFF_CHARS = 60000
MAX_FILE_LINES = 800
MAX_CONTEXT_CHARS = 120000
MAX_FINDINGS = 6
SKIP_FILES = re.compile(r"(\.lock$|\.g\.dart$|\.freezed\.dart$|\.(png|jpg|jpeg|gif|svg|ico|pdf)$)")
RULES_FILE = Path(__file__).resolve().parents[1] / "ai-review.md"

SYSTEM = """あなたは経験豊富なFlutterのコードレビュアーです。
PRの差分を読み、本当に直すべき問題だけを指摘してください。

指摘してよいもの:
- バグ（null、境界値、例外、非同期、状態の不整合、ほかのファイルからの呼び出しへの影響など）
- 関連するイシューの要件の抜け漏れ（イシューが与えられた場合）
- プロジェクトのルール・ディレクトリの役割に反する実装やファイルの置き場所（ルールが与えられた場合）
- テストが必要な変更にテストがない

指摘しないもの:
- 好みの問題、命名、フォーマット、細かいリファクタリング提案
- 根拠のない推測

ルール:
- 指摘は最大6件。なければ0件でよい。
- line には差分の行頭にある R の番号（変更後のファイルの行番号）を使う。差分にない箇所が原因の場合も、関係する差分の行を選ぶ。
- category は「バグ」「要件」「設計」「テスト」のいずれか。
- 日本語で、1件につき2〜3文で簡潔に書く。
- 出力は次のJSONだけ。前後に説明文を付けない。

{"summary": "PR全体の所感を1〜2文", "findings": [{"category": "バグ", "path": "ファイルパス", "line": 123, "body": "指摘内容"}]}
"""


def gh(*args, input_text=None):
    return subprocess.run(["gh", *args], check=True, capture_output=True, text=True, input=input_text).stdout


def annotate(diff):
    """差分の各行に変更後の行番号を付ける。コメント可能な (path, line) と、変更ファイル・変更行も返す。"""
    out, valid, files, changed = [], set(), [], []
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
                files.append(path)
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
            changed.append((path, line))
        elif line.startswith("+") or line.startswith(" "):
            out.append(f"R{right:<5}{line}")
            valid.add((path, right))
            if line.startswith("+"):
                changed.append((path, line))
            right += 1
    return "\n".join(out), valid, files, changed


# ---------- rich モード用のコンテキスト ----------

DEF_RE = re.compile(
    r"^[+-]\s*(?:static\s+|final\s+|const\s+)*"
    r"(?:class\s+(?P<cls>[A-Z]\w*)|"
    r"(?:Future<[^>]*>|Stream<[^>]*>|List<[^>]*>|Map<[^>]*>|[A-Z]\w*(?:<[^>]*>)?\??|int|double|String|bool|void|num)\s+"
    r"(?:get\s+)?(?P<fn>[a-zA-Z]\w*)\s*(?:\(|=>|\{))"
)


def changed_symbols(changed):
    syms = {}
    for path, line in changed:
        if not path.endswith(".dart"):
            continue
        m = DEF_RE.match(line)
        if m:
            name = m.group("cls") or m.group("fn")
            if name and name not in {"build", "toString", "toJson", "copyWith", "main"}:
                syms.setdefault(name, path)
    return syms


def usages(syms):
    blocks = []
    for name, own in list(syms.items())[:10]:
        try:
            out = subprocess.run(["grep", "-rn", "-w", name, "lib", "test"], capture_output=True, text=True).stdout
        except Exception:
            continue
        hits = [h for h in out.splitlines() if not h.startswith(own + ":")][:8]
        if not hits:
            continue
        parts = [f"## `{name}`（{own} で変更）の参照箇所"]
        for h in hits:
            f, ln, _ = h.split(":", 2)
            ln = int(ln)
            lines = Path(f).read_text(encoding="utf-8").splitlines()
            lo, hi = max(0, ln - 4), min(len(lines), ln + 3)
            snippet = "\n".join(f"{i + 1:>5}| {lines[i]}" for i in range(lo, hi))
            parts.append(f"{f}:{ln}\n{snippet}")
        blocks.append("\n\n".join(parts))
    return "\n\n".join(blocks)


def full_files(files):
    parts = []
    for f in files:
        p = Path(f)
        if not p.exists() or not f.endswith(".dart"):
            continue
        lines = p.read_text(encoding="utf-8").splitlines()
        if len(lines) > MAX_FILE_LINES:
            continue
        body = "\n".join(f"{i + 1:>5}| {l}" for i, l in enumerate(lines))
        parts.append(f"## {f}（変更後の全文）\n{body}")
    return "\n\n".join(parts)


def lib_tree():
    files = sorted(str(p) for p in Path("lib").rglob("*.dart"))
    return "\n".join(files)


def linked_issues(body):
    parts = []
    for n in sorted(set(re.findall(r"#(\d+)", body or "")))[:3]:
        try:
            info = json.loads(gh("issue", "view", n, "--repo", REPO, "--json", "title,body"))
            parts.append(f"## #{n} {info['title']}\n{info['body']}")
        except Exception:
            continue
    return "\n\n".join(parts)


def tool_results():
    parts = []
    for env, title, tail in (("ANALYZE_LOG", "flutter analyze", 60), ("TEST_LOG", "flutter test", 80)):
        path = os.environ.get(env)
        if path and Path(path).exists():
            lines = Path(path).read_text(encoding="utf-8", errors="replace").splitlines()
            if env == "TEST_LOG":
                fails = [l for l in lines if "[E]" in l or "Expected" in l or "Actual" in l or "Error" in l]
                lines = fails[:40] + ["..."] + lines[-5:] if fails else lines[-3:]
            else:
                lines = lines[-tail:]
            parts.append(f"## {title}\n" + "\n".join(lines))
    return "\n\n".join(parts)


def build_prompt(info, annotated, files, changed):
    head = f"# PRタイトル\n{info['title']}\n\n# PRの説明\n{info['body'] or '（なし）'}\n\n"
    diff = f"# 差分\n{annotated}"
    if MODE != "rich":
        return head + diff
    ctx = []
    if RULES_FILE.exists():
        ctx.append("# プロジェクトのルール\n" + RULES_FILE.read_text(encoding="utf-8"))
    ctx.append("# lib/ のファイル一覧\n" + lib_tree())
    issues = linked_issues(info["body"])
    if issues:
        ctx.append("# 関連するイシュー\n" + issues)
    tools = tool_results()
    if tools:
        ctx.append("# 静的解析とテストの結果（このPRの変更後）\n" + tools)
    use = usages(changed_symbols(changed))
    if use:
        ctx.append("# 変更したシンボルの、ほかのファイルでの参照箇所\n" + use)
    full = full_files(files)
    if full:
        ctx.append("# 変更したファイルの全文\n" + full)
    context = "\n\n".join(ctx)
    if len(context) > MAX_CONTEXT_CHARS:
        context = context[:MAX_CONTEXT_CHARS] + "\n（長いため以降は省略）"
    return head + context + "\n\n" + diff


# ---------- LLM とGitHub ----------

def _chat(prompt, max_tokens, thinking=True):
    payload = {
        "model": MODEL,
        "messages": [{"role": "system", "content": SYSTEM}, {"role": "user", "content": prompt}],
        "temperature": 0.2,
        "max_tokens": max_tokens,
    }
    if not thinking:
        payload["chat_template_kwargs"] = {"enable_thinking": False}
    req = urllib.request.Request(
        f"{BASE_URL}/chat/completions",
        data=json.dumps(payload).encode(),
        headers={"Content-Type": "application/json", "Authorization": f"Bearer {API_KEY}"},
    )
    with urllib.request.urlopen(req, timeout=1800) as res:
        return json.load(res)


def ask_llm(prompt):
    """考える過程（thinking）が長すぎて回答まで届かなかったときは、thinking なしでやり直す。"""
    data = _chat(prompt, 16000)
    choice = data["choices"][0]
    text = re.sub(r"<think>.*?</think>", "", choice["message"].get("content") or "", flags=re.S)
    note = ""
    if not re.search(r"\{.*\}", text, flags=re.S):
        print(f"retry without thinking (finish_reason={choice.get('finish_reason')})", file=sys.stderr)
        data = _chat(prompt, 4000, thinking=False)
        text = data["choices"][0]["message"].get("content") or ""
        note = "（thinkingなしで再実行）"
    m = re.search(r"\{.*\}", text, flags=re.S)
    if not m:
        raise ValueError("LLMの出力からJSONを取り出せませんでした")
    usage = data.get("usage") or {}
    usage["note"] = note
    return json.loads(m.group(0)), usage


def post_review(body, comments):
    payload = {"commit_id": HEAD_SHA, "event": "COMMENT", "body": body, "comments": comments}
    gh("api", f"repos/{REPO}/pulls/{PR}/reviews", "--method", "POST", "--input", "-", input_text=json.dumps(payload))


def main():
    label = "rich" if MODE == "rich" else "basic"
    info = json.loads(gh("pr", "view", PR, "--repo", REPO, "--json", "title,body"))
    diff = gh("pr", "diff", PR, "--repo", REPO)
    annotated, valid, files, changed = annotate(diff)

    if not valid:
        post_review(f"🤖 ローカルLLMレビュー（{label}）: レビュー対象の差分がありませんでした。", [])
        return
    if len(annotated) > MAX_DIFF_CHARS:
        post_review(f"🤖 ローカルLLMレビュー（{label}）: 差分が大きいためスキップしました（{len(annotated):,}文字）。", [])
        return

    prompt = build_prompt(info, annotated, files, changed)
    t0 = time.time()
    result, usage = ask_llm(prompt)
    elapsed = time.time() - t0

    comments, orphans = [], []
    for f in (result.get("findings") or [])[:MAX_FINDINGS]:
        cat = f.get("category") or "指摘"
        text = f"**[{cat}]** {f.get('body', '')}"
        try:
            key = (f["path"], int(f["line"]))
        except (KeyError, TypeError, ValueError):
            orphans.append(f"- {text}")
            continue
        if key in valid:
            comments.append({"path": key[0], "line": key[1], "side": "RIGHT", "body": text})
        else:
            orphans.append(f"- `{f.get('path')}` L{f.get('line')}: {text}")

    body = f"🤖 ローカルLLMレビュー（{label} / {MODEL}）\n\n{result.get('summary', '')}"
    if not comments and not orphans:
        body += "\n\n指摘はありませんでした。"
    if orphans:
        body += "\n\n差分の行に付けられなかった指摘:\n" + "\n".join(orphans)
    body += (
        f"\n\n<sub>入力 {usage.get('prompt_tokens', '?')} / 出力 {usage.get('completion_tokens', '?')} トークン・"
        f"LLM {elapsed:.0f}秒{usage.get('note', '')}。自動レビューです。最終判断は人が行ってください。</sub>"
    )
    post_review(body, comments)
    print(json.dumps({"mode": label, "inline": len(comments), "orphan": len(orphans), "sec": round(elapsed),
                      "usage": usage}, ensure_ascii=False))


if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        print(f"error: {e}", file=sys.stderr)
        try:
            post_review(f"🤖 ローカルLLMレビュー: 失敗しました（{type(e).__name__}）。Actionsのログを確認してください。", [])
        except Exception:
            pass
        sys.exit(1)

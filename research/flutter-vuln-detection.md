# Flutter / Dart 脆弱性パッチの検知ソース まとめ

検証日: 2026-10-30(以下すべての endpoint はこの日に実際に叩いて結果を確認)

## TL;DR

- **1箇所で全部は揃わない。** 経路は「① SDK 自体の advisories」「② pub パッケージの advisories」「③ ロックファイルスキャン」の3系統。
- **単一ソースで最も速いのは `flutter/flutter` の `CHANGELOG.md`**。`#### Security advisory [GHSA-...]` という見出しで修正バージョンと対応要否がそのまま書かれる。
- ⚠️ **Flutter SDK / Dart SDK 向けの advisories はグローバル GHSA DB にも OSV にもミラーされない**(実測 404)。`ecosystem=pub` だけ定期取得すると SDK 本体の修正を丸ごと取りこぼす。
- hotfix リリースは advisories より先に出ることがある。**リリース検知(advisory 検知)の2本立て**が必須。

## 検知ソース一覧(実測)

| # | 対象 | 経路 | 実測結果 |
|---|---|---|---|
| 1 | **Flutter SDK のセキュリティ修正** | `https://raw.githubusercontent.com/flutter/flutter/master/CHANGELOG.md` | ✅ `Security advisory` 記述あり。CVE-2023-6345 / CVE-2023-4863 / libpng 更新も |
| 2 | **Dart/Flutter SDK の advisories** | `https://api.github.com/repos/dart-lang/sdk/security-advisories` | ✅ 取得可(直近: `GHSA-frr6-h895-5pxp` 2026-10-23 high) |
| 3 | pub パッケージ advisories | `https://api.github.com/advisories?ecosystem=pub` | ✅ 取得可(`dio`, `jose`, `http`, `archive`, `serverpod*`, `shared_preferences_android`, `pubnub`, `agent_dart`, `personnummer`) |
| 4 | 特定パッケージに絞る | `https://pub.dev/api/packages/<pkg>/advisories` | ✅ 200。OSV schema_version `1.7.3` 形式 |
| 5 | バージョン解決時の内蔵検知 | `dart pub get` / `dart pub outdated` | GHSA へのリンク付きで警告。`pubspec.yaml` の `ignored_advisories` で抑制可 |
| 6 | 依存ピン版への突合 | `POST https://api.osv.dev/v1/query` + `ecosystem:"Pub"` | ✅ ヒット(`dio` 2.3.0 → `GHSA-9324-jv53-9cc8`)。不正 ecosystem は `invalid ecosystem` を返す |
| 7 | CI で lockfile スキャン | [osv-scanner](https://github.com/google/osv-scanner)(Dart / `pubspec.lock` 対応を README で確認) | ⚠️ README 記載ベース(本番未実行) |
| 8 | リポジトリに紐づく警告/PR 自動化 | Dependabot `package-ecosystem: "pub"` | ✅ dependabot-core に `pub/` ディレクトリ存在 |
| 9 | **ビルド/hotfix の即時検知** | `https://storage.googleapis.com/flutter_infra_release/releases/releases_{linux,macos,windows}.json` | ✅ `current_release.stable` + `hotfix_version` フィールドあり |
| 10 | リリースノート一覧 | `https://github.com/flutter/flutter/releases.atom` | ✅ `[3.47] Changelog for 3.47.9 (#195509)` まで取る |
| 11 | 公式方針 | [docs.flutter.dev/security](https://docs.flutter.dev/security) | 「stable ブランチのみセキュリティ更新」「重大版は beta or stable hotfix で修正」 |

### 使えなかった / 不適だったもの

- `api.github.com/repos/flutter/flutter/security-advisories` → `[]`、`flutter/engine` → `[]`。**監視先は `dart-lang/sdk` に寄せる**のが正解。`flutter/packages` は 3 件。
- `github.com/advisories?...&atom` → HTML を返すだけ(**Atom feed なし**)。
- `https://api.osv.dev/v1/ecosystems` / `/v1/list` → 404 / 400。
- `endoflife.date/api/flutter.json` → データなし。`api.deps.dev/v3/systems/pub/...` → 404(Pub 未対応)。
- NVD `keywordSearch=flutter` → `totalResults: 14` のみ。網羅性不足で主要経路に不適。
- `security.dart.dev` → このマシンでは TLS が reset され疎通不可(`ECONNRESET`)。dart.dev のドキュメント上、advisories のソースは GitHub Advisory Database と明記されているので上記でカバー可能。

## ⚠️ 最大の落とし穴

SDK 向けの advisories は **リポジトリ側 GHS** に `ecosystem: "other"` / `package.name: "Flutter SDK"` で出る:

```json
// GET https://api.github.com/repos/dart-lang/sdk/security-advisories/GHSA-frr6-h895-5pxp
{"vulnerabilities":[
  {"package":{"ecosystem":"other","name":"Dart SDK"},
   "vulnerable_version_range":"< 3.13.7 (stable), < 3.14.0-315.3.beta (beta)",
   "patched_versions":"3.13.7, 3.14.0-315.3.beta"},
  {"package":{"ecosystem":"other","name":"Flutter SDK"},
   "vulnerable_version_range":"< 3.47.8 (stable), < 3.50.0-0.2.pre",
   "patched_versions":"3.47.8, 3.50.0-0.2.pre"}
],"severity":"high","published_at":"2026-10-23T18:51:07Z","cve_id":null}
```

そして実測でいずれも空:

- `https://api.github.com/advisories/GHSA-frr6-h895-5pxp` → **404**
- `https://api.osv.dev/v1/vulns/GHSA-frr6-h895-5pxp` → **404**(`Vulnerability not found`)
- `https://api.github.com/advisories?affects=Flutter SDK` → **0 件**

該当修正は CHANGELOG.md にこう書かれている(これが一番読める):

```
### [3.47.8](https://github.com/flutter/flutter/releases/tag/3.47.8)
#### Security advisory [GHSA-frr6-h895-5pxp](https://github.com/dart-lang/sdk/security/advisories/GHSA-frr6-h895-5pxp):
- [dart/568000] Updates BoringSSL in the Dart runtime (3.13.7) to block compromised eMudhra intermediate CA certificates.
- [dart/64696] Updates `dart:io` on Android 14+ to use the updatable Conscrypt APEX root certificate store.
- Developers shipping Android, Windows, or Linux applications should upgrade to Flutter 3.47.8 and rebuild their apps.
```

**hotfix = セキュリティ修正とは限らない**点にも注意。直後の `3.47.9`(2026-10-29 公開)は crash fix のみでセキュリティ記述なしだった。

## 監視スクリプト(動作確認済み)

どちらも初回実行は全件吐きます(ブートストラップ)。2回目以降は差分のみ。

### 1. advisories 新着検知 — `check.sh`

```bash
#!/usr/bin/env bash
# 15分cron想定。state ファイルと比較して新着だけ出力
S="$(cd "$(dirname "$0")" && pwd)/.vuln-state"; touch "$S"
curl -sS -H "Accept: application/vnd.github+json" \
  'https://api.github.com/repos/dart-lang/sdk/security-advisories?per_page=50' \
| jq -r '.[] | select(.state=="published") | .ghsa_id' > "$S.new"
curl -sS -H "Accept: application/vnd.github+json" \
  'https://api.github.com/advisories?ecosystem=pub&per_page=50' \
| jq -r '.[].ghsa_id' >> "$S.new"
comm -13 <(sort -u "$S") <(sort -u "$S.new") | while read -r id; do
  echo "NEW advisory: https://github.com/advisories/$id"
done
sort -u "$S.new" > "$S"
```

実測: 1回目 22 件 → 2回目 0 件(差分なしを確認)。

### 2. Flutter stable ビルド検知 — `flutter-hotfix.sh`

```bash
#!/usr/bin/env bash
# Flutter stable ビルド検知 (15分cron想定)。hash+version のみ比較し再掲出タイムスタンプで誤検知しない
case "$(uname -s)" in Darwin) OS=macos;; Linux) OS=linux;; *) OS=windows;; esac
S="$(cd "$(dirname "$0")" && pwd)/.flutter-state"; touch "$S"
curl -sS "https://storage.googleapis.com/flutter_infra_release/releases/releases_${OS}.json" \
| jq -r '.current_release.stable as $h | .releases[] | select(.hash==$h) | "\($h) \(.version)"' \
| sort -u > "$S.new"
comm -13 "$S" "$S.new" | sed 's/^/NEW flutter stable: /'
cp "$S.new" "$S"
```

実測: `NEW flutter stable: c197ca5199... 3.47.9` を検知、2回目は差分なし。
`release_date` を比較に入れると同一ビルドの再掲出タイムスタンプで誤検知するので必ず `hash + version` の2項目に絞る。

### 3. ワンライナー(CHANGELOG のセキュリティ節だけ眺める)

```bash
curl -sSL https://raw.githubusercontent.com/flutter/flutter/master/CHANGELOG.md \
  | grep -iE '^### \[|Security advisory|CVE-[0-9]{4}-[0-9]+'
```

### cron 例

```cron
*/15 * * * * /path/to/check.sh          | tee -a /var/log/flutter-vuln.log
*/15 * * * * /path/to/flutter-hotfix.sh | tee -a /var/log/flutter-vuln.log
```

GitHub API は非認証だと 60 req/h 上限。15分間隔なら 4 req/h で余裕但没有余り。`GH_TOKEN` を付与するか、`If-None-Match`/ETag で絞ると安全。

## 自プロジェクト向け(実運用の推奨形)

1. CI で `osv-scanner --lockfile=pubspec.lock`(⑦) を回す → 自分のピン版にだけノイズが乗る
2. リポジトリに Dependabot `pub` を有効化(⑧) → patch PR まで自動
3. 上記スクリプトで**SDK 側とベンダー側**を監視 → アップグレード判断は `flutter --version` と `patched_versions` を突き合わせ

## 参考リンク

- https://docs.flutter.dev/security
- https://dart.dev/tools/pub/security-advisories
- https://github.com/dart-lang/sdk/security/advisories
- https://github.com/advisories?ecosystem=pub
- https://osv.dev / https://github.com/google/osv-scanner
- https://github.com/flutter/flutter/releases

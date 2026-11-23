# ローカルLLM（Qwen）お試しの成果物

DGX Spark 1台で動かしたローカルLLM（Qwen3.8-Flash-Next）と、クラウドのClaude Code（Opus 5.5）に同じお題を渡して比べたときの成果物です。

ブログ記事：（公開後にURLを追記）

## 中身

| フォルダ | 内容 |
|---|---|
| `prompt/` | 両方のモデルに渡した要件定義（同じもの） |
| `qwen/brew_log/` | Qwen（Qwen Code）が作ったFlutterアプリ |
| `opus/brew_log/` | Opus 5.5（Claude Code）が作ったFlutterアプリ |
| `research/` | Qwenにまとめてもらった、Flutter/Dartの脆弱性情報の検知ソース調査 |

各アプリの起動方法や設計の説明は、それぞれの `README.md` を見てください。

## 動かし方

```sh
cd qwen/brew_log   # または opus/brew_log
flutter pub get
flutter run
```

Flutterのバージョンは、Qwen版が3.47.9、Opus版が3.50.1です（各フォルダの `.fvmrc` を参照）。

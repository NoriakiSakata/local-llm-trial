# test_data/

テスト [`../test`](../test) とスクリーンショット [`../lib/demo`](../lib/demo) で使っているデータ例を、人の読める形に書き出したものです。**実行には読み込まれません**（アプリもテストも参照しない、ドキュメント専用の置き場）。

| ファイル | 内容 |
|---|---|
| [beans.md](beans.md) | 豆の一覧（名前・産地・焙煎度・焙煎日・経過日数・メモ）と、テスト本文で都度作る豆名 |
| [recipes.md](recipes.md) | レシピ5値から自動計算されるステップ内訳と、テストが依存している数値 |
| [extractions.md](extractions.md) | 抽出記録。test の5件は実値、demo の21件は生成式＋索引表＋集計値の検算 |
| [seed_state.json](seed_state.json) | test fixture をアプリの保存形式（`schema` 付きJSON）そのままにしたもの |

出所は2系統あります。

- **test** … [`test/helpers/harness.dart`](../test/helpers/harness.dart)。基準時刻を `DateTime(2026, 10, 30, 9)` に固定した決定論的 fixture
- **demo** … [`lib/demo/demo_data.dart`](../lib/demo/demo_data.dart)。スクショ用で日付は本日基準の相対値。保存領域には触れない

## seed_state.json の使い方（実ファイル経由の保存往復チェック）

シミュレータでアプリを落としてから、保存キーに1本書き込んで起動し直すだけです。

```bash
xcrun simctl spawn booted defaults write dev.brewlog.brewLog \
    brew_log.state.v1 -string "$(cat test_data/seed_state.json)"
xcrun simctl launch booted dev.brewlog.brewLog
```

豆・レシピ・記録が入った状態で行き、保存の**読み出し**経路を端末側で確認できます（この手順はまだ未実施。トップレベルの [README.md](../README.md) の「未検証」参照）。同じキーに壊れたJSONを入れると、退避 → 空状態 → 警告バナーの経路も確かめられます。

## 生成（裏取り）

```bash
fvm flutter test tool/dump_test_data_test.dart   # → build/test_data_dump.md
```

実コードから Markdown 表をダンプして `build/test_data_dump.md` に出します。このディレクトリの .md は読む用に整えた版なので**上書きしません**。fixture を変えたらダンプを突き合わせて、記事側も追随させてください。

> 注: ダンプもまだ実行できていません（このセッションではシェルツールの PTY 確保が失敗し、コマンドが打てない状態でした）。.md の中身は `harness.dart` / `demo_data.dart` / `brew_plan.dart` を読んで導出し、スクリーンショットに写った集計値（18杯・平均3.7・豆別 4.0/3.9/3.3）と照合して整合を取っています。

## 旧 .txt について

同じ内容を pipe 区切りで置いていた `beans.txt` / `recipes.txt` / `extractions.txt` / `README.txt` は **.md に置き換わったため不要**です（中身はポインタ1行にしてあります）。シェルが使える環境なら消してください:

```bash
rm brew_log/test_data/*.txt
```

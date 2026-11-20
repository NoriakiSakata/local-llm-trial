# 豆の一覧（テスト用 / 撮影用のデータ例）

| 出所 | id | 名前 | 産地 / 備考 | 焙煎度 | 焙煎日 | 経過日数 | メモ |
|---|---|---|---|---|---|---|---|
| test | `bean-a` | エチオピア ゲイシャ | イルガチェフェ | 浅煎り | 2026-10-22 | 8日 | 花のような香り |
| test | `bean-b` | グアテマラ アンティグア | アンティグア | 中煎り | 2026-10-02 | 28日 | — |
| demo | `demo-bean-1` | エチオピア ゲイシャ G1 | イルガチェフェ / ウォッシュド | 浅煎り | 本日−4日 | 4日 | ジャスミンのような香り。細挽きすぎたかも。 |
| demo | `demo-bean-2` | グアテマラ アンティグア | アンティグア バレー / SHB | 中煎り | 本日−12日 | 12日 | ナッツとチョコ。温度を下げると甘みが出る。 |
| demo | `demo-bean-3` | ブラジル セラード | ミナスジェライス | 深煎り | 本日−26日 | 26日 | 深煎り。濃い味わいだが雑味が出やすい。 |

## 出所の違い

- **test** … [`test/helpers/harness.dart`](../test/helpers/harness.dart) の fixture。基準時刻を `ManualBrewClock(DateTime(2026, 10, 30, 9))` に固定しているので、焙煎からの経過日数も毎回同じ値になります（決定論的なテストのため）
- **demo** … [`lib/demo/demo_data.dart`](../lib/demo/demo_data.dart) のデータ。スクリーンショット用で、焙煎日は「本日 − N日」の相対値。保存領域には書き込みません

## 焙煎度について

`RoastLevel` は [`lib/data/models/bean.dart`](../lib/data/models/bean.dart) で **`light`(浅煎り) / `medium`(中煎り) / `dark`(深煎り) の3値のみ**です。

品種・精製法・等級・標高を入れる専用フィールドはありません。必要なら `origin`（自由記述）に「イルガチェフェ / ウォッシュド」のように添えています。

## テスト本文で都度作っている豆

fixture ではなく、そのケース専用の値です。

| 使っているテスト | 名前 | 用途 |
|---|---|---|
| [`test/unit/app_data_test.dart`](../test/unit/app_data_test.dart) | 新しい豆（ブラジル / 深煎り / 2026-10-20） | id 採番と追加の確認 |
| 同上 | 名前の直した豆 | 同じ id の更新確認 |
| 同上 | 保存失敗のテスト | 保存失敗時に `saveError` が立つ確認 |
| 同上 | 消えたくない豆 | 未来スキーマで自動保存が止まる確認 |
| [`test/widget/beans_screen_test.dart`](../test/widget/beans_screen_test.dart) | テスト用の豆 | 空状態からの登録フロー |
| [`test/unit/stats_test.dart`](../test/unit/stats_test.dart) | Ａ / Ｂ / Ｃ（`b1` / `b2` / `b3`） | ランキングの順序確認 |
| 同上 | 消えた豆（beanId なし） | 豆を消しても名前で集まる確認 |
| [`test/unit/state_store_test.dart`](../test/unit/state_store_test.dart) | `roast: 'medium-dark'` | 不正な焙煎度 → `DataShapeException` |
| 同上 | 未知のキー入り | 未知キーの読み捨て（前方互換） |

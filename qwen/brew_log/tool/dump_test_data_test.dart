import 'dart:convert';
import 'dart:io';

import 'package:brew_log/application/brew_plan.dart';
import 'package:brew_log/data/models.dart';
import 'package:brew_log/demo/demo_data.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test/helpers/harness.dart';

/// fixture を Markdown 表にダンプして `build/test_data_dump.md` に出す。
///
///   fvm flutter test tool/dump_test_data_test.dart
///
/// `test_data/*.md` は人が読む用に整えた版なので、ここでは**上書きしない**。
/// fixture を変えたらこのダンプを突き合わせて、手元の記事も追随させる。
/// （`flutter test` のスイートには含まれず、パスを明示したときだけ動く）
void main() {
  test('build/test_data_dump.md を作る', () {
    final fixtureNow = DateTime.parse('2026-10-30 09:00');
    final fixtures = sampleState(now: fixtureNow);

    final out = StringBuffer()
      ..writeln('# test_data ダンプ（実コードから生成）')
      ..writeln()
      ..writeln('生成日時: ${DateTime.now()}　/　fixture 基準: $fixtureNow')
      ..writeln()
      ..writeln('## 豆')
      ..writeln()
      ..writeln('| 出所 | id | 名前 | 産地 | 焙煎度 | 焙煎日 | 経過 | メモ |')
      ..writeln('|---|---|---|---|---|---|---|---|')
      ..write(_beanRows(fixtures.beans, demoBeans, fixtureNow))
      ..writeln()
      ..writeln('## レシピとステップ')
      ..writeln()
      ..writeln('| 出所 | id | 名前 | 豆量 | 湯量 | 湯温 | 蒸らし | 回数 | 合計 | ステップ |')
      ..writeln('|---|---|---|---|---|---|---|---|---|---|')
      ..write(_recipeRows(fixtures.recipes, demoRecipes))
      ..writeln()
      ..writeln('## 抽出記録（test fixture）')
      ..writeln()
      ..writeln('| id | 日時 | 数日前 | 豆名 | 豆id | 評価 | 味(酸/苦/甘) | 所要 | メモ |')
      ..writeln('|---|---|---|---|---|---|---|---|---|')
      ..write(_extractionRows(fixtures.extractions, fixtureNow))
      ..writeln()
      ..writeln('## 保存形式そのもの（seed_state.json 相当）')
      ..writeln()
      ..writeln('```json')
      ..writeln(const JsonEncoder.withIndent('  ').convert(fixtures.toJson()))
      ..writeln('```');

    Directory('build').createSync(recursive: true);
    File('build/test_data_dump.md').writeAsStringSync(out.toString());

    expect(fixtures.beans.length, 2);
    expect(demoBeans.length, 3);
    expect(fixtures.extractions.length, 5);
  });
}

String _beanRows(List<Bean> fixtures, List<Bean> demos, DateTime fixtureNow) {
  final demoNow = DateTime.now();
  final b = StringBuffer();
  for (final (String tag, List<Bean> list, DateTime base) in <
    (String, List<Bean>, DateTime)
  >[
    ('test', fixtures, fixtureNow),
    ('demo', demos, demoNow),
  ]) {
    for (final Bean bean in list) {
      b.writeln(
        '| $tag | `${bean.id}` | ${bean.name} | ${bean.origin} | ${bean.roast.label} | '
        '${encodeDate(bean.roastDate)} | ${bean.daysSinceRoast(base)}日 | ${_dash(bean.note)} |',
      );
    }
  }
  return b.toString();
}

String _recipeRows(List<Recipe> fixtures, List<Recipe> demos) {
  final b = StringBuffer();
  for (final (String tag, List<Recipe> list) in <(String, List<Recipe>)>[
    ('test', fixtures),
    ('demo', demos),
  ]) {
    for (final Recipe recipe in list) {
      final plan = BrewPlan.from(recipe);
      final steps =
          plan.steps
              .map(
                (BrewStep s) =>
                    '${s.label}=${s.targetCumMl}ml/${s.durationMs ~/ 1000}s',
              )
              .join(' ・ ');
      b.writeln(
        '| $tag | `${recipe.id}` | ${recipe.name} | ${recipe.beanAmountG}g | '
        '${recipe.waterMl}ml | ${recipe.tempC}℃ | ${recipe.bloomSeconds}s | '
        '${recipe.pours}回 | ${plan.totalMs ~/ 1000}s | $steps |',
      );
    }
  }
  return b.toString();
}

String _extractionRows(List<Extraction> list, DateTime base) {
  final b = StringBuffer();
  for (final Extraction e in list) {
    final days = dateOnly(e.brewedAt).difference(dateOnly(base)).inDays;
    b.writeln(
      '| `${e.id}` | ${_hhmm(e.brewedAt)} | $days日前 | ${e.beanName} | '
      '`${e.beanId ?? '-'}` | ★${e.rating} | '
      '${e.taste.acidity.toStringAsFixed(2)}/${e.taste.bitterness.toStringAsFixed(2)}/'
      '${e.taste.sweetness.toStringAsFixed(2)} | ${e.totalSeconds}s | ${_dash(e.note)} |',
    );
  }
  return b.toString();
}

String _dash(String value) => value.isEmpty ? '—' : value;

String _hhmm(DateTime value) =>
    '${encodeDate(value)} ${value.hour.toString().padLeft(2, '0')}:'
    '${value.minute.toString().padLeft(2, '0')}';

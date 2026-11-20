/// スクリーンショット生成用のサンプルデータ。
///
/// 実機の保存領域には一切触れない。`lib/demo/demo_main.dart` からのみ読む。
library;

import 'package:flutter/material.dart' show ThemeMode;

import '../application/brew_plan.dart';
import '../application/brew_session.dart';
import '../data/models.dart';

final List<Bean> demoBeans = <Bean>[
  Bean(
    id: 'demo-bean-1',
    name: 'エチオピア ゲイシャ G1',
    origin: 'イルガチェフェ / ウォッシュド',
    roast: RoastLevel.light,
    roastDate: _daysAgo(4),
    note: 'ジャスミンのような香り。細挽きすぎたかも。',
  ),
  Bean(
    id: 'demo-bean-2',
    name: 'グアテマラ アンティグア',
    origin: 'アンティグア バレー / SHB',
    roast: RoastLevel.medium,
    roastDate: _daysAgo(12),
    note: 'ナッツとチョコ。温度を下げると甘みが出る。',
  ),
  Bean(
    id: 'demo-bean-3',
    name: 'ブラジル セラード',
    origin: 'ミナスジェライス',
    roast: RoastLevel.dark,
    roastDate: _daysAgo(26),
    note: '深煎り。濃い味わいだが雑味が出やすい。',
  ),
];

final List<Recipe> demoRecipes = <Recipe>[
  Recipe(
    id: 'demo-recipe-1',
    name: '朝の一杯',
    beanAmountG: 15,
    waterMl: 240,
    tempC: 92,
    bloomSeconds: 40,
    pours: 3,
    beanId: 'demo-bean-1',
  ),
  Recipe(
    id: 'demo-recipe-2',
    name: 'ゆっくり4投',
    beanAmountG: 18,
    waterMl: 300,
    tempC: 88,
    bloomSeconds: 45,
    pours: 4,
    beanId: 'demo-bean-2',
  ),
];

/// 直近約35日にまたがる抽出記録（新しい順に積む）。
List<Extraction> demoExtractions() {
  const List<int> ratings = <int>[
    5,
    4,
    4,
    3,
    5,
    4,
    2,
    4,
    5,
    3,
    4,
    4,
    1,
    3,
    5,
    4,
    4,
    2,
    5,
    3,
    4,
  ];
  const List<String> notes = <String>[
    '香りが立っていて良い。細挽きすぎたかも',
    '温度を2℃下げたら甘みが出た',
    '蒸らしが短く、薄い味わいになった',
    '雑味あり。注湯が荒かった',
    '今回いちばん良い当たり',
  ];

  final DateTime today = _daysAgo(0);
  final List<Extraction> items = <Extraction>[];
  for (int i = 0; i < ratings.length; i++) {
    // 直近は毎日、そのあとは日をおいて淹れたことにする。
    final int daysAgo = i < 7 ? i : 2 * i - 5;
    final Bean bean = demoBeans[i % demoBeans.length];
    final Recipe recipe = demoRecipes[i % demoRecipes.length];
    final BrewPlan plan = BrewPlan.from(recipe);
    items.add(
      Extraction(
        id: 'demo-ex-$i',
        brewedAt: today
            .subtract(Duration(days: daysAgo))
            .add(Duration(hours: 7 + (i % 10), minutes: 5 + (i % 4) * 13)),
        beanId: bean.id,
        beanName: bean.name,
        recipeName: recipe.name,
        rating: ratings[i],
        beanAmountG: recipe.beanAmountG,
        waterMl: recipe.waterMl,
        tempC: recipe.tempC,
        taste: TasteProfile(
          acidity: (0.25 + 0.06 * (i % 9)).clamp(0.0, 1.0),
          bitterness: (0.70 - 0.05 * (i % 11)).clamp(0.0, 1.0),
          sweetness: (0.35 + 0.05 * (i % 10)).clamp(0.0, 1.0),
        ),
        note: i.isEven ? notes[i % notes.length] : '',
        pours: <PourLog>[
          for (int s = 0; s < plan.steps.length; s++)
            PourLog(
              label: plan.steps[s].label,
              targetCumMl: plan.steps[s].targetCumMl,
              elapsedMs: plan.steps[s].startMs,
            ),
        ],
      ),
    );
  }
  return items;
}

PersistedState demoState() => PersistedState(
  beans: demoBeans,
  recipes: demoRecipes,
  extractions: demoExtractions(),
  settings: const AppSettings(
    themeMode: ThemeMode.system,
    lastRecipeId: 'demo-recipe-1',
  ),
);

/// 淹れている最中の画面を撮るための、途中経過のセッション。
BrewSession demoRunningSession() {
  final Recipe recipe = demoRecipes.first;
  final BrewPlan plan = BrewPlan.from(recipe);
  const int elapsed = 47000;
  final int index = plan.indexAt(elapsed);
  return BrewSession(
    recipe: recipe,
    plan: plan,
    phase: BrewPhase.running,
    elapsedMs: elapsed,
    marks: <PourLog>[
      for (int i = 0; i <= index; i++)
        PourLog(
          label: plan.steps[i].label,
          targetCumMl: plan.steps[i].targetCumMl,
          elapsedMs: plan.steps[i].startMs,
        ),
    ],
    startedAt: DateTime.now().subtract(const Duration(seconds: 47)),
  );
}

DateTime _daysAgo(int days) {
  final DateTime now = DateTime.now();
  return DateTime(now.year, now.month, now.day).subtract(Duration(days: days));
}

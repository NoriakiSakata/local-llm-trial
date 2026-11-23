import 'package:brew_log/app/app.dart';
import 'package:brew_log/data/models/bean.dart';
import 'package:brew_log/data/models/brew_record.dart';
import 'package:brew_log/data/models/recipe.dart';
import 'package:brew_log/data/repositories/brew_log_repository.dart';
import 'package:brew_log/data/storage/key_value_store.dart';
import 'package:brew_log/state/app_providers.dart';
import 'package:brew_log/state/device_services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// 端末機能の偽物。時計を手動で進め、ハプティクスなどの呼び出しを記録する。
class FakeDeviceServices implements DeviceServices {
  Duration clock = Duration.zero;
  int stepChangedCount = 0;
  int finishedCount = 0;
  final List<bool> keepScreenOnCalls = [];

  void advance(Duration d) => clock += d;

  @override
  Duration now() => clock;

  @override
  void stepChanged() => stepChangedCount++;

  @override
  void finished() => finishedCount++;

  @override
  Future<void> keepScreenOn(bool enabled) async =>
      keepScreenOnCalls.add(enabled);
}

Bean testBean({
  String id = 'b1',
  String name = 'テスト豆',
  RoastLevel roast = RoastLevel.medium,
  DateTime? roastedOn,
}) => Bean(
  id: id,
  name: name,
  origin: 'エチオピア',
  roast: roast,
  roastedOn: roastedOn ?? DateTime(2026, 11, 1),
  memo: '',
  createdAt: DateTime(2026, 11, 1),
);

BrewRecord testRecord({
  required String id,
  String? beanId = 'b1',
  String beanName = 'テスト豆',
  required DateTime at,
  int rating = 4,
}) => BrewRecord(
  id: id,
  beanId: beanId,
  beanName: beanName,
  recipe: Recipe.standard,
  brewedAt: at,
  elapsedSec: 150,
  rating: rating,
  acidity: 3,
  bitterness: 3,
  sweetness: 3,
  note: '',
);

/// テスト用にアプリ全体を起動する。
Future<({MemoryKeyValueStore store, FakeDeviceServices device})> pumpApp(
  WidgetTester tester, {
  Map<String, String>? stored,
  Size size = const Size(390, 844),
}) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  final store = MemoryKeyValueStore(stored);
  final device = FakeDeviceServices();
  final bootstrap = BootstrapData.load(BrewLogRepository(store));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        bootstrapProvider.overrideWithValue(bootstrap),
        deviceServicesProvider.overrideWithValue(device),
      ],
      child: const BrewLogApp(),
    ),
  );
  await tester.pumpAndSettle();
  return (store: store, device: device);
}

/// 下部ナビゲーションのタブを開く
Future<void> openTab(WidgetTester tester, String label) async {
  await tester.tap(
    find.descendant(of: find.byType(NavigationBar), matching: find.text(label)),
  );
  await tester.pumpAndSettle();
}

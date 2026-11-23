import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'app/app.dart';
import 'data/repositories/brew_log_repository.dart';
import 'data/storage/key_value_store.dart';
import 'dev/demo_data.dart';
import 'state/app_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final issues = <StorageIssue>[];
  KeyValueStore store;
  try {
    store = await SharedPrefsKeyValueStore.open(BrewLogRepository.allKeys);
  } on Object {
    // 保存領域を開けない場合もアプリは起動し、メモリ上で動かす
    store = MemoryKeyValueStore();
    issues.add(const StorageIssue('保存領域を開けませんでした。このまま使えますが、アプリを閉じると内容は失われます。'));
  }

  final repository = BrewLogRepository(store);
  await DemoData.seedIfRequested(repository);
  final bootstrap = BootstrapData.load(repository, extraIssues: issues);

  runApp(
    ProviderScope(
      overrides: [
        bootstrapProvider.overrideWithValue(bootstrap),
        if (DemoData.initialTab != null)
          homeTabProvider.overrideWith(
            () => InitialTabNotifier(DemoData.initialTab!),
          ),
      ],
      child: const BrewLogApp(),
    ),
  );
}

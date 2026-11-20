import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'application/app_data.dart';
import 'application/providers.dart';
import 'data/models.dart';
import 'data/state_store.dart';
import 'presentation/root_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 起動時に一度だけ読み込む。ここで失敗してもアプリは落とさず、
  // 「空のデータ + 警告」として立ち上げる。
  AppBootstrap bootstrap;
  try {
    final LoadOutcome outcome = await const SharedPreferencesStore().load();
    bootstrap = AppBootstrap(state: outcome.state, failure: outcome.failure);
  } on Exception catch (error) {
    bootstrap = AppBootstrap(
      state: PersistedState.empty,
      failure: StoreFailure(
        kind: StoreFailureKind.storageUnavailable,
        message:
            '保存データを読み出すことができませんでした。'
            '動作確認用に、空の状態から始めます。',
        detail: error.toString(),
      ),
    );
  }

  runApp(
    ProviderScope(
      overrides: [appBootstrapProvider.overrideWithValue(bootstrap)],
      child: const RootApp(),
    ),
  );
}

import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'data/storage.dart';
import 'state/app_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final repository = AppRepository(SharedPreferencesStore(SharedPreferencesAsync()));
  // 保存データを読んでから最初の画面を出す（起動直後に空→データありと切り替わらないように）
  final loaded = await repository.load();
  final store = AppStore(repository: repository, initial: loaded.data, startupNotice: loaded.recoveredFromError);
  runApp(BrewLogApp(store: store));
}

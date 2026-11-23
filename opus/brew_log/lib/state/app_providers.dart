import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/app_settings.dart';
import '../data/models/bean.dart';
import '../data/models/brew_record.dart';
import '../data/models/recipe.dart';
import '../data/repositories/brew_log_repository.dart';
import 'device_services.dart';

/// 起動時に読み込んだデータ。main() で生成して ProviderScope に渡す。
class BootstrapData {
  const BootstrapData({
    required this.repository,
    required this.beans,
    required this.records,
    required this.settings,
    required this.issues,
  });

  /// リポジトリから全データを読み込む。例外は投げず、問題は [issues] に集める。
  factory BootstrapData.load(
    BrewLogRepository repository, {
    List<StorageIssue> extraIssues = const [],
  }) {
    final beans = repository.loadBeans();
    final records = repository.loadRecords();
    final settings = repository.loadSettings();
    return BootstrapData(
      repository: repository,
      beans: beans.data,
      records: records.data,
      settings: settings.data,
      issues: [
        ...extraIssues,
        ...beans.issues,
        ...records.issues,
        ...settings.issues,
      ],
    );
  }

  final BrewLogRepository repository;
  final List<Bean> beans;
  final List<BrewRecord> records;
  final AppSettings settings;
  final List<StorageIssue> issues;
}

final bootstrapProvider = Provider<BootstrapData>(
  (ref) => throw UnimplementedError('ProviderScope で上書きしてください'),
);

final repositoryProvider = Provider<BrewLogRepository>(
  (ref) => ref.watch(bootstrapProvider).repository,
);

/// 端末機能（ハプティクス・スリープ抑止・時計）。テストで差し替える。
final deviceServicesProvider = Provider<DeviceServices>(
  (ref) => const PlatformDeviceServices(),
);

/// 保存・読み込みで起きた問題。ホーム画面上部のバナーに表示する。
class StorageIssuesNotifier extends Notifier<List<StorageIssue>> {
  @override
  List<StorageIssue> build() => ref.read(bootstrapProvider).issues;

  void report(String message) => state = [...state, StorageIssue(message)];

  void dismissAll() => state = const [];
}

final storageIssuesProvider =
    NotifierProvider<StorageIssuesNotifier, List<StorageIssue>>(
      StorageIssuesNotifier.new,
    );

/// 保存処理の共通ラッパー。失敗してもアプリは止めず、バナーで知らせる。
Future<void> _persist(Ref ref, Future<void> Function() save) async {
  try {
    await save();
  } on Object {
    ref
        .read(storageIssuesProvider.notifier)
        .report('データを保存できませんでした。端末の空き容量を確認してください。');
  }
}

class BeansNotifier extends Notifier<List<Bean>> {
  @override
  List<Bean> build() => ref.read(bootstrapProvider).beans;

  Future<void> _save() =>
      _persist(ref, () => ref.read(repositoryProvider).saveBeans(state));

  Future<void> add(Bean bean) {
    state = [bean, ...state];
    return _save();
  }

  Future<void> replace(Bean bean) {
    state = [for (final b in state) b.id == bean.id ? bean : b];
    return _save();
  }

  /// 削除して、元に戻すための位置を返す。
  Future<int> remove(String id) async {
    final index = state.indexWhere((b) => b.id == id);
    if (index < 0) return -1;
    state = [...state]..removeAt(index);
    await _save();
    return index;
  }

  Future<void> restore(Bean bean, int index) {
    final list = [...state];
    list.insert(index.clamp(0, list.length), bean);
    state = list;
    return _save();
  }

  void resetInMemory() => state = const [];
}

final beansProvider = NotifierProvider<BeansNotifier, List<Bean>>(
  BeansNotifier.new,
);

final beanByIdProvider = Provider.family<Bean?, String>((ref, id) {
  final beans = ref.watch(beansProvider);
  for (final b in beans) {
    if (b.id == id) return b;
  }
  return null;
});

class RecordsNotifier extends Notifier<List<BrewRecord>> {
  @override
  List<BrewRecord> build() => ref.read(bootstrapProvider).records;

  Future<void> _save() =>
      _persist(ref, () => ref.read(repositoryProvider).saveRecords(state));

  Future<void> add(BrewRecord record) {
    state = [record, ...state]
      ..sort((a, b) => b.brewedAt.compareTo(a.brewedAt));
    return _save();
  }

  Future<void> remove(String id) {
    state = state.where((r) => r.id != id).toList();
    return _save();
  }

  Future<void> restore(BrewRecord record) => add(record);

  void resetInMemory() => state = const [];
}

final recordsProvider = NotifierProvider<RecordsNotifier, List<BrewRecord>>(
  RecordsNotifier.new,
);

class SettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() => ref.read(bootstrapProvider).settings;

  Future<void> _save() =>
      _persist(ref, () => ref.read(repositoryProvider).saveSettings(state));

  Future<void> setTheme(ThemePreference theme) {
    state = state.copyWith(theme: theme);
    return _save();
  }

  Future<void> setLastRecipe(Recipe recipe) {
    if (recipe == state.lastRecipe) return Future.value();
    state = state.copyWith(lastRecipe: recipe);
    return _save();
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(
  SettingsNotifier.new,
);

/// ホームの下部ナビゲーションで選択中のタブ。
enum HomeTab { brew, beans, history, insights }

class HomeTabNotifier extends Notifier<HomeTab> {
  @override
  HomeTab build() => HomeTab.brew;

  void select(HomeTab tab) => state = tab;
}

final homeTabProvider = NotifierProvider<HomeTabNotifier, HomeTab>(
  HomeTabNotifier.new,
);

/// 履歴の豆フィルタ（null はすべて）。
class HistoryFilterNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String? beanId) => state = beanId;
}

final historyFilterProvider = NotifierProvider<HistoryFilterNotifier, String?>(
  HistoryFilterNotifier.new,
);

/// 豆と記録をすべて削除する。
Future<void> clearAllData(WidgetRef ref) async {
  try {
    await ref.read(repositoryProvider).clearAll();
  } on Object {
    ref
        .read(storageIssuesProvider.notifier)
        .report('データの削除に失敗しました。もう一度お試しください。');
    return;
  }
  ref.read(beansProvider.notifier).resetInMemory();
  ref.read(recordsProvider.notifier).resetInMemory();
  ref.read(historyFilterProvider.notifier).select(null);
}

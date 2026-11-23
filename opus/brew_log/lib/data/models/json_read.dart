/// JSON から型安全に値を取り出すための小さなヘルパー。
/// 型が合わなければ [FormatException] を投げ、呼び出し側で「壊れたデータ」として扱う。
extension JsonRead on Map<String, dynamic> {
  T req<T>(String key) {
    final value = this[key];
    if (value is T) return value;
    throw FormatException('"$key" の型が不正です（${value.runtimeType}）');
  }

  T? opt<T>(String key) {
    final value = this[key];
    if (value == null) return null;
    if (value is T) return value;
    throw FormatException('"$key" の型が不正です（${value.runtimeType}）');
  }

  int reqInt(String key) => req<num>(key).toInt();

  double reqDouble(String key) => req<num>(key).toDouble();

  DateTime reqDate(String key) {
    final parsed = DateTime.tryParse(req<String>(key));
    if (parsed == null) throw FormatException('"$key" の日付が不正です');
    return parsed;
  }
}

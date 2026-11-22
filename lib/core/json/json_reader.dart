/// Hand-written JSON plumbing. No code generation: each model reads its own
/// fields through a [JsonReader] and writes them with a literal map.
library;

/// A decoded JSON object.
typedef Json = Map<String, Object?>;

/// A payload that does not match what the model expects.
final class JsonFormatException implements Exception {
  const JsonFormatException(this.path, this.message);

  /// Where in the payload, for example `$.items[2].id`.
  final String path;

  /// What was expected.
  final String message;

  @override
  String toString() => 'JsonFormatException: $path: $message';
}

/// Typed access to one JSON object, with the path kept for error messages.
/// "Absent" and `null` read the same for every `...OrNull` accessor.
final class JsonReader {
  const JsonReader(this.json, [this.path = r'$']);

  /// Wraps [value], which must be a JSON object.
  factory JsonReader.of(Object? value, [String path = r'$']) {
    if (value is Map<String, Object?>) return JsonReader(value, path);
    if (value is Map<Object?, Object?>) {
      return JsonReader(value.cast<String, Object?>(), path);
    }
    throw JsonFormatException(path, 'expected an object');
  }

  /// A list (the whole payload, or any value) whose items are objects read by
  /// [read]; the `data` of a list endpoint.
  static List<T> listOf<T>(
    Object? value,
    T Function(JsonReader item) read, [
    String path = r'$',
  ]) {
    if (value is! List<Object?>) {
      throw JsonFormatException(path, 'expected a list');
    }
    return List<T>.unmodifiable([
      for (var i = 0; i < value.length; i++)
        read(JsonReader.of(value[i], '$path[$i]')),
    ]);
  }

  final Json json;
  final String path;

  bool has(String key) => json.containsKey(key);

  Never _bad(String key, String expected) =>
      throw JsonFormatException('$path.$key', 'expected $expected');

  String string(String key) {
    final value = json[key];
    return value is String ? value : _bad(key, 'a string');
  }

  String? stringOrNull(String key) {
    final value = json[key];
    if (value == null) return null;
    return value is String ? value : _bad(key, 'a string or null');
  }

  int integer(String key) {
    final value = json[key];
    if (value is int) return value;
    if (value is num && value == value.truncateToDouble()) return value.toInt();
    return _bad(key, 'an integer');
  }

  int? integerOrNull(String key) => json[key] == null ? null : integer(key);

  bool boolean(String key) {
    final value = json[key];
    return value is bool ? value : _bad(key, 'a boolean');
  }

  JsonReader object(String key) {
    final value = json[key];
    if (value == null) _bad(key, 'an object');
    return JsonReader.of(value, '$path.$key');
  }

  JsonReader? objectOrNull(String key) =>
      json[key] == null ? null : object(key);

  /// A required list whose items are objects read by [read].
  List<T> list<T>(String key, T Function(JsonReader item) read) {
    final value = json[key];
    if (value is! List<Object?>) return _bad(key, 'a list');
    return listOf(value, read, '$path.$key');
  }

  /// A required list of strings.
  List<String> strings(String key) {
    final value = json[key];
    if (value is! List<Object?>) return _bad(key, 'a list');
    for (final item in value) {
      if (item is! String) return _bad(key, 'a list of strings');
    }
    return List<String>.unmodifiable(value.cast<String>());
  }
}

part of simple_dart_json;

class JSONObject {
  static final num _negative_zero = -0.0;

  static final NULL Null = NULL();

  final LinkedHashMap<String, Object> _nameValuePairs;

  JSONObject._() : this._nameValuePairs = new LinkedHashMap();

  JSONObject({Object data}) : this._nameValuePairs = new LinkedHashMap() {
    if (data != null) {
      if (data is Map) _fromMap(data);
    } else if (data is String) {}
  }

  _fromMap(Map<dynamic, dynamic> data) {
    data.forEach((dynamic key, dynamic value) {
      if (key == null) {
        throw new NullThrownError();
      }
      _nameValuePairs[key] = wrap(value);
    });
  }

  /// Wraps the given object if necessary.
  ///
  /// <p>If the object is null or , returns {@link #NULL}.
  /// If the object is a {@code JSONArray} or {@code JSONObject}, no wrapping is necessary.
  /// If the object is {@code NULL}, no wrapping is necessary.
  /// If the object is an array or {@code Collection}, returns an equivalent {@code JSONArray}.
  /// If the object is a {@code Map}, returns an equivalent {@code JSONObject}.
  /// If the object is a primitive wrapper type or {@code String}, returns the object.
  /// Otherwise if the object is from a {@code java} package, returns the result of {@code toString}.
  /// If wrapping fails, returns null.
  static Object wrap(Object o) {
    if (o == null) {
      return NULL;
    }
    if (o is JSONArray || o is JSONObject) {
      return o;
    }
    if (o == Null) {
      return o;
    }
    try {
      if (o is List) {
        return new JSONArray(copyFrom: o);
      }
      if (o is Map) {
        return new JSONObject(data: o);
      }
      if (o is bool || o is num || o is String) {
        return o;
      }
    } catch (e) {}
    return null;
  }

  void put(String name, Object value) {}
}

class NULL extends Object {
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NULL && runtimeType == other.runtimeType;

  @override
  int get hashCode => 0;

  @override
  String toString() {
    return "null";
  }
}

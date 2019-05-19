part of simple_dart_json;

class JSONObject {
  static final num _negative_zero = -0.0;

  static final NULL Null = NULL();

  final LinkedHashMap<String, Object> _nameValuePairs;

  JSONObject._() : this._nameValuePairs = new LinkedHashMap();

  JSONObject([Object data]) : this._nameValuePairs = new LinkedHashMap() {
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

  /// Returns the number of name/value mappings in this object.
  int length() {
    return _nameValuePairs.length;
  }

  JSONObject put(String name, dynamic value) {
    if (value is bool) {
      _nameValuePairs[checkName(name)] = value;
    } else if (value is double) {
      _nameValuePairs[checkName(name)] = JSON.checkDouble(value);
    } else if (value is num) {
      _nameValuePairs[checkName(name)] = value;
    } else {
      if (value == null) {
        _nameValuePairs.remove(name);
        return this;
      }
      if (value is num) {
        // deviate from the original by checking all Numbers, not just floats & doubles
        JSON.checkDouble(value.toDouble());
      }
      _nameValuePairs[checkName(name)] = value;
    }
    return this;
  }

  JSONObject putOpt(String name, Object value) {
    if (name == null || value == null) {
      return this;
    }
    return put(name, value);
  }

  JSONObject accumulate(String name, Object value) {
    Object current = _nameValuePairs[checkName(name)];
    if (current == null) {
      return put(name, value);
    }
    if (current is JSONArray) {
      current.checkedPut(value);
    } else {
      JSONArray array = new JSONArray();
      array.checkedPut(current);
      array.checkedPut(value);
      _nameValuePairs[name] = array;
    }
    return this;
  }

  JSONObject append(String name, Object value) {
    Object current = _nameValuePairs[checkName(name)];
    JSONArray array;
    if (current is JSONArray) {
      array = current;
    } else if (current == null) {
      JSONArray newArray = new JSONArray();
      _nameValuePairs[name] = newArray;
      array = newArray;
    } else {
      throw new JSONException("Key " + name + " is not a JSONArray");
    }
    array.checkedPut(value);
    return this;
  }

  String checkName(String name) {
    if (name == null) {
      throw new JSONException("Names must be non-null");
    }
    return name;
  }

  Object remove(String name) {
    return _nameValuePairs.remove(name);
  }

  /// Returns true if this object has no mapping for {@code name} or if it has
  /// a mapping whose value is {@link #NULL}.
  bool isNull(String name) {
    Object value = _nameValuePairs[name];
    return value == null || value == NULL;
  }

  /// Returns true if this object has a mapping for {@code name}. The mapping
  /// may be {@link #NULL}.
  bool has(String name) {
    return _nameValuePairs.containsKey(name);
  }

  /// Returns the value mapped by {@code name}, or throws if no such mapping exists.
  /// @throws JSONException if no such mapping exists.
  Object get(String name) {
    Object result = _nameValuePairs[name];
    if (result == null) {
      throw new JSONException("No value for " + name);
    }
    return result;
  }

  /// Returns the value mapped by {@code name}, or null if no such mapping
  /// exists.
  Object opt(String name) {
    return _nameValuePairs[name];
  }

  /// Returns the value mapped by {@code name} if it exists and is a boolean or
  /// can be coerced to a boolean, or throws otherwise.
  ///
  /// @throws JSONException if the mapping doesn't exist or cannot be coerced
  ///     to a boolean.

  bool getBool(String name) {
    Object object = get(name);
    bool result = JSON.toBoolean(object);
    if (result == null) {
      throw JSON.typeMismatch(
        object,
        "boolean",
        name,
      );
    }
    return result;
  }

  /// Returns the value mapped by {@code name} if it exists and is a boolean or
  /// can be coerced to a boolean, or false otherwise.
  bool optBoolean(String name, [bool fallback]) {
    Object object = opt(name);
    bool result = JSON.toBoolean(object);
    return result != null ? result : fallback;
  }

  double getDouble(String name) {
    Object object = get(name);
    double result = JSON.toDouble(object);

    if (result == null) {
      throw JSON.typeMismatch(name, object, "double");
    }
    return result;
  }

  /// Returns the value mapped by {@code name} if it exists and is a double or
  /// can be coerced to a double, or {@code fallback} otherwise.
  double optDouble(String name, [double fallback]) {
    Object object = opt(name);
    double result = JSON.toDouble(object);

    if (result == null && fallback == null) {
      throw JSON.typeMismatch(object, "double", name);
    }
    return result != null ? result : fallback;
  }

  /// Returns the value mapped by {@code name} if it exists and is an int or
  /// can be coerced to an int, or throws otherwise.
  ///
  /// @throws JSONException if the mapping doesn't exist or cannot be coerced
  ///     to an int.
  int getInt(String name) {
    Object object = get(name);
    int result = JSON.toInteger(object);
    if (result == null) {
      throw JSON.typeMismatch( object, "int",name);
    }
    return result;
  }

  /// Returns the value mapped by {@code name} if it exists, coercing it if
  /// necessary, or throws if no such mapping exists.
  ///
  /// @throws JSONException if no such mapping exists.
  String getString(String name) {
    Object object = get(name);
    String result = JSON.toString(object);
    if (result == null) {
      throw JSON.typeMismatch(object, "String",name);
    }
    return result;
  }

  /// Returns the value mapped by {@code name} if it exists, coercing it if
  /// necessary, or {@code fallback} if no such mapping exists.
  String optString(String name, [String fallback]) {
    Object object = opt(name);
    String result = JSON.toString(object);
    return result != null ? result : fallback;
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
        return new JSONArray(o);
      }
      if (o is Map) {
        return new JSONObject(o);
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

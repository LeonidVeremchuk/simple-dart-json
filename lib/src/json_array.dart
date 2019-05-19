part of simple_dart_json;

class JSONArray {
  final List<Object> _values;

  JSONArray([List data]) : _values = List() {
    if (data != null) {
      for (Iterator it = data.iterator; it.moveNext();) {
        put(JSONObject.wrap(it.current));
      }
    }
  }

  ///Same as {@link #put}, with added validity checks.
  void checkedPut(Object value) {
    if (value is num) {
      JSON.checkDouble(value.toDouble());
    }
    put(value);
  }

  put(Object o) {
    _values.add(o);
  }
}

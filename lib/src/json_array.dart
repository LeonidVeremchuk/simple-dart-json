part of simple_dart_json;

class JSONArray {
  final List<Object> _values;

  JSONArray({List copyFrom}) : _values = List() {
    if (copyFrom != null) {
      for (Iterator it = copyFrom.iterator; it.moveNext();) {
        put(JSONObject.wrap(it.current));
      }
    }
  }

  put(Object o) {
    _values.add(o);
  }
}

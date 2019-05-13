class JSONException implements Exception {
  final String error;

  JSONException(this.error);

  @override
  String toString() {
    return "JSONException: " + error;
  }
}

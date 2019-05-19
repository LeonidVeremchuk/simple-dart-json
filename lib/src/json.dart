/*
 * Copyright (C) 2010 The Android Open Source Project
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'package:simple_dart_json/src/json_exception.dart';

class JSON {
  /// Returns the input if it is a JSON-permissible value; throws otherwise.
  static double checkDouble(double d) {
    if (isInfinite(d) || double.nan == d) {
      throw JSONException("Forbidden numeric value: ");
    }
    return d;
  }

  static bool toBoolean(Object value) {
    if (value is bool) {
      return value;
    } else if (value is String) {
      if ("true" == value.toLowerCase()) {
        return true;
      } else if ("false" == value.toLowerCase()) {
        return false;
      }
    }
    return null;
  }

  static double toDouble(Object value) {
    if (value is double) {
      return value;
    } else if (value is num) {
      return value.toDouble();
    } else if (value is String) {
      return (double.tryParse(value) ?? null);
    }
    return null;
  }

  static int toInteger(Object value) {
    if (value is num) {
      return value;
    } else if (value is String) {
      return (int.tryParse(value));
    }
    return null;
  }

  static String toString(Object value) {
    if (value is String) {
      return value;
    } else if (value != null) {
      return value.toString();
    }
    return null;
  }

  static JSONException typeMismatch(Object actual, String requiredType,
      [Object indexOrName]) {
    if (actual == null) {
      throw new JSONException("Value at " + indexOrName + " is null.");
    } else {
      throw new JSONException("Value " +
          actual +
          "${indexOrName != null ? "at  $indexOrName" : ""}" +
          " of type " +
          actual.runtimeType.toString() +
          " cannot be converted to " +
          requiredType);
    }
  }
}

bool isInfinite(double value) {
  return double.infinity == value || double.negativeInfinity == value;
}

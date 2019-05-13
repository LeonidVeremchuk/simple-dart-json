import 'package:simple_dart_json/src/json_exception.dart';

import '../simple_dart_json.dart';

class JSONTokener {
  /// '\n';
  static const int N = 10;

  /// '\t';
  static const int T = 9;

  ///  '\r';
  static const int R = 13;

  ///  '\b';
  static const int B = 8;

  ///  '\f';
  static const int F = 12;

  /// ' ';
  static const int space = 32;

  /// '/';
  static const slash = 47;

  /// '#';
  static const hash = 35;

  /// '///';
  static const asterisk = 42;

  /// '{';
  static const bracer_left = 123;

  /// '}';
  static const bracer_right = 125;

  /// '[';
  static const brackets_left = 125;

  /// ']';
  static const brackets_right = 125;

  /// '"';
  static const empty = 34;

  /// '\'';
  static const backslash = 39;

  /// '\\'
  static const double_backslash = 92;

  /// ':';
  static const colon = 58;

  /// ';';
  static const semicolon = 59;

  /// '=';
  static const equal = 61;

  /// '>';
  static const greater_than = 62;

  /// ',';
  static const coma = 44;

  String _input;
  int _pos;

  JSONTokener(String input) {
    // consume an optional byte order mark (BOM) if it exists
    if (input != null && input.startsWith("\ufeff")) {
      input = input.substring(1);
    }
    _input = input;
  }

  Object _nextValue() {
    int c = _nextCleanInternal();
    switch (c) {
      case -1:
        throw _syntaxError("End of input");
      case bracer_left:
        return _readObject();
      case brackets_left:
        return _readArray();
      case backslash:
      case empty:
        return _nextString(c);

      default:
        _pos--;
        return _readLiteral();
    }
  }

  int _nextCleanInternal() {
    while (_pos < _input.length) {
      int c = _input.codeUnitAt(_pos++);
      switch (c) {
        case T:
        case space:
        case N:
        case R:
        case slash:
          if (_pos == _input.length) {
            return c;
          }
          int peek = _input.codeUnitAt(_pos++);
          switch (peek) {
            case asterisk:
              // skip a /* c-style comment */
              _pos++;
              int commentEnd = _input.indexOf("*/", _pos);
              if (commentEnd == -1) {
                throw _syntaxError("Unterminated comment");
              }
              _pos = commentEnd + 2;
              continue;

            case slash:

              /// skip a // end-of-line comment
              _pos++;
              _skipToEndOfLine();
              continue;
            default:
              return c;
          }
          return c;
        case hash:

          /// Skip a # hash end-of-line comment. The JSON RFC doesn't
          /// specify this behavior, but it's required to parse
          /// existing documents. See http://b/2571423.
          _skipToEndOfLine();
          continue;

        default:
          return c;
      }
    }
    return -1;
  }

  /// Reads a sequence of key/value pairs and the trailing closing brace '}' of
  /// an object. The opening brace '{' should have already been read.
  JSONObject _readObject() {
    JSONObject result = new JSONObject();

    /* Peek to see if this is the empty object. */
    int first = _nextCleanInternal();
    if (first == bracer_right) {
      return result;
    } else if (first != -1) {
      _pos--;
    }

    while (true) {
      Object name = _nextValue();
      if (!(name is String)) {
        if (name == null) {
          throw _syntaxError("Names cannot be null");
        } else {
          throw _syntaxError("Names must be strings, but " +
                  name +
                  " is of type " +
                  name.runtimeType?.toString() ??
              'unknow');
        }
      }

      /*
        * Expect the name/value separator to be either a colon ':', an
        * equals sign '=', or an arrow "=>". The last two are bogus but we
        * include them because that's what the original implementation did.
        */
      int separator = _nextCleanInternal();
      if (separator != colon && separator != equal) {
        throw _syntaxError("Expected ':' after " + name);
      }
      if (_pos < _input.length && _input.codeUnitAt(_pos) == greater_than) {
        _pos++;
      }

      result.put(name as String, _nextValue());

      switch (_nextCleanInternal()) {
        case bracer_right:
          return result;
        case semicolon:
        case coma:
          continue;
        default:
          throw _syntaxError("Unterminated object");
      }
    }
  }

  /// Reads a sequence of values and the trailing closing brace ']' of an
  /// array. The opening brace '[' should have already been read. Note that
  /// "[]" yields an empty array, but "[,]" returns a two-element array
  /// equivalent to "[null,null]".
  JSONArray _readArray() {
    JSONArray result = new JSONArray();

    /* to cover input that ends with ",]". */
    bool hasTrailingSeparator = false;

    while (true) {
      switch (_nextCleanInternal()) {
        case -1:
          throw _syntaxError("Unterminated array");
        case brackets_right:
          if (hasTrailingSeparator) {
            result.put(null);
          }
          return result;
        case coma:
        case semicolon:
          /* A separator without a value first means "null". */
          result.put(null);
          hasTrailingSeparator = true;
          continue;
        default:
          _pos--;
      }

      result.put(_nextValue());

      switch (_nextCleanInternal()) {
        case brackets_right:
          return result;
        case coma:
        case semicolon:
          hasTrailingSeparator = true;
          continue;
        default:
          throw _syntaxError("Unterminated array");
      }
    }
  }

  /// Returns the string up to but not including {@code quote}, unescaping any
  /// character escape sequences encountered along the way. The opening quote
  /// should have already been read. This consumes the closing quote, but does
  /// not include it in the returned string.
  ///
  /// @param quote either ' or ".
  String _nextString(int quote) {
    /*
     * For strings that are free of escape sequences, we can just extract
     * the result as a substring of the input. But if we encounter an escape
     * sequence, we need to use a StringBuilder to compose the result.
     */
    StringBuffer builder;

    /* the index of the first character not yet appended to the builder. */
    int start = _pos;

    while (_pos < _input.length) {
      int c = _input.codeUnitAt(_pos++);
      if (c == quote) {
        if (builder == null) {
          // a new string avoids leaking memory
          return _input.substring(start, _pos - 1);
        } else {
          builder.write(_input.substring(start, _pos - 1));
          return builder.toString();
        }
      }

      if (c == double_backslash) {
        if (_pos == _input.length) {
          throw _syntaxError("Unterminated escape sequence");
        }
        if (builder == null) {
          builder = new StringBuffer();
        }
        builder.write(_input.substring(start, _pos - 1));
        builder.write(_readEscapeCharacter());
        start = _pos;
      }
    }
    throw _syntaxError("Unterminated string");
  }

  /// Unescapes the character identified by the character or characters that
  /// immediately follow a backslash. The backslash '\' should have already
  /// been read. This supports both unicode escapes "u000A" and two-character
  /// escapes "\n".
  String _readEscapeCharacter() {
    int escaped = _input.codeUnitAt(_pos++);
    switch (escaped) {
      case 117:
        if (_pos + 4 > _input.length) {
          throw _syntaxError("Unterminated escape sequence");
        }
        String hex = _input.substring(_pos, _pos + 4);
        _pos += 4;
        try {
          return String.fromCharCode(int.parse(hex, radix: 16));
        } catch (error) {
          throw _syntaxError("Invalid escape sequence: " + hex);
        }
        return null;

      case 116:
        return String.fromCharCode(T);

      case 98:
        return String.fromCharCode(B);
      case 110:
        return String.fromCharCode(N);
      case 114:
        return String.fromCharCode(R);
      case 102:
        return String.fromCharCode(F);
      case backslash:
      case empty:
      case double_backslash:
      default:
        return String.fromCharCode(escaped);
    }
  }

  /// Reads a null, boolean, numeric or unquoted string literal value. Numeric
  /// values will be returned as an Integer, Long, or Double, in that order of
  /// preference.
  Object _readLiteral() {
    String literal = _nextToInternal("{}[]/\\:,=;# \t\f");

    if (literal.length == 0) {
      throw _syntaxError("Expected literal value");
    } else if ("null" == literal.toLowerCase()) {
      return JSONObject.Null;
    } else if ("true" == literal.toLowerCase()) {
      return true;
    } else if ("false" == literal.toLowerCase()) {
      return false;
    }

    /* try to parse as an integral type... */
    if (literal.indexOf('.') == -1) {
      int base = 10;
      String number = literal;
      if (number.startsWith("0x") || number.startsWith("0X")) {
        number = number.substring(2);
        base = 16;
      } else if (number.startsWith("0") && number.length > 1) {
        number = number.substring(1);
        base = 8;
      }

      try {
        return int.tryParse(number, radix: base);
      } catch (error) {
        /*
          * This only happens for integral numbers greater than
          * Long.MAX_VALUE, numbers in exponential form (5e-10) and
          * unquoted strings. Fall through to try floating point.
          */
      }
    }

    /* ...next try to parse as a floating point... */
    try {
      return double.parse(literal);
    } catch (error) {}
    /* ... finally give up. We have an unquoted string */
    return literal;
  }

  /// Returns the string up to but not including any of the given characters or
  /// a newline character. This does not consume the excluded character.
  String _nextToInternal(String excluded) {
    int start = _pos;
    for (; _pos < _input.length; _pos++) {
      int c = _input.codeUnitAt(_pos);
      if (c == R || c == N || excluded.indexOf(String.fromCharCode(c)) != -1) {
        return _input.substring(start, _pos);
      }
    }
    return _input.substring(start);
  }

  _skipToEndOfLine() {
    for (; _pos < _input.length; _pos++) {
      var c = _input[_pos];
      if (c == '\r' || c == '\n') {
        _pos++;
        break;
      }
    }
  }

  JSONException _syntaxError(String error) {
    return JSONException(error);
  }
}

import 'dart:async';
import 'dart:convert';

import 'exceptions.dart';
import 'tokens.dart';

/// A stream transformer that converts Strings to [Token]s.
///
/// This transformer reads a strings from a source stream and emits
/// the [Token]s that were parsed from the strings.
class Lexer extends StreamTransformerBase<String, Token> {
  /// Path to the source file being tokenized
  final String? path;

  const Lexer({
    this.path
  });

  @override
  Stream<Token> bind(Stream<String> stream) => Stream<Token>.eventTransformed(
      stream.transform(LineSplitter()),
      (sink) => TokenEventSink(sink, path: path)
  );
}

/// Indicates the token currently being parsed
enum _LexState {
  /// A string literal
  string,
}

/// Reads [String]s from a source stream and emits [Token]s to the output stream.
class TokenEventSink implements EventSink<String> {
  /// List of consumer functions to call
  late final _consumeFns = [
    _consumeId,
    _consumeTerminator,
    _consumeSeparator,
    _consumeNum,
    _startString,
    _consumeParen,
    _consumeBrace,
    _consumeWhiteSpace,
    _consumeLineComment
  ];

  /// Regex matching characters which do not form part of identifiers
  static const _nonIdChars = r'\s;,(){}#"';

  /// Path to the source file being tokenized
  final String? path;

  /// Identifies the token currently being parsed
  _LexState? _state;

  /// Has this stream been closed?
  var _closed = false;

  /// The data associated with the current token
  var _data = '';

  var _line = 0;
  var _column = 0;

  /// The location of the current character being processed
  Location get _location => Location(
      path: path,
      line: _line,
      column: _column
  );

  /// The output [Token] stream
  final EventSink<Token> _output;

  TokenEventSink(this._output, {
    this.path
  });

  @override
  void add(String event) {
    if (_closed) {
      return;
    }

    var start = 0;

    while (start < event.length) {
      _column = _consumeToken(event, start);

      if (_column == start) {
        _emitError(
            InvalidTokenError(
                location: _location,
                data: event.substring(start)
            )
        );

        return;
      }

      start = _column;
    }

    switch (_state) {
      case null:
        _emitToken(
            Terminator(
                soft: true,
                location: _location,
            )
        );

      case _LexState.string:
        _data += '\n';
    }

    _line++;
  }

  @override
  void addError(Object error, [StackTrace? stackTrace]) {
    if (_closed) {
      return;
    }

    _output.addError(error, stackTrace);
  }

  @override
  void close() {
    if (_state == _LexState.string) {
      _emitError(
          UnclosedStringError(
              location: _location,
          )
      );
    }

    _output.close();
  }

  /// Consume a token from [data] starting at [start].
  ///
  /// This function consumes the token of the type specified
  /// by the current state of the tokenizer
  int _consumeToken(String data, int start) => switch (_state) {
    null => _start(data, start),
    _LexState.string => _consumeString(data, start),
  };

  /// Consume and emit a new token.
  ///
  /// This method should be called when the lexer state is not currently
  /// parsing a token of a given type.
  ///
  /// Returns the position of the next character after the consumed token
  int _start(String data, int start) {
    for (final fn in _consumeFns) {
      final end = fn(data, start);

      if (end > start) {
        return end;
      }
    }

    return start;
  }

  /// Consume and emit an identifier.
  int _consumeId(String data, int start) {
    final regex = RegExp('[^0-9$_nonIdChars][^$_nonIdChars]*');
    final match = regex.matchAsPrefix(data, start);

    if (match != null) {
      _emitToken(
        IdToken(
          name: match.group(0)!,
          location: Location(
              path: path,
              line: _line,
              column: start
          ),
        )
      );

      return match.end;
    }

    return start;
  }

  /// Consume and emit a hard terminator.
  int _consumeTerminator(String data, int start) {
    final regex = RegExp(';+');
    final match = regex.matchAsPrefix(data, start);

    if (match != null) {
      _emitToken(
          Terminator(
              soft: false,
              location: Location(
                  path: path,
                  line: _line,
                  column: start
              ),
          )
      );

      return match.end;
    }

    return start;
  }

  /// Consume and emit a numeric literal
  int _consumeNum(String data, int start) {
    final regex = RegExp(r'([+-]?[0-9]+)(\.[0-9]+)?');
    final match = regex.matchAsPrefix(data, start);

    if (match != null) {
      final isFloat = match.group(2) != null;

      if (isFloat) {
        _emitToken(
            Literal(
                value: num.parse(match.group(0)!),
                location: Location(
                    path: path,
                    line: _line,
                    column: start
                ),
            )
        );
      }
      else {
        _emitToken(
            Literal(
                value: int.parse(match.group(0)!),
                location: Location(
                    path: path,
                    line: _line,
                    column: start
                ),
            )
        );
      }

      return match.end;
    }

    return start;
  }

  /// Consume a new string
  int _startString(String data, int start) {
    if (data[start] == '"') {
      _state = _LexState.string;
      _data = '';
      return start + 1;
    }

    return start;
  }

  /// Continue consuming a string and emit a string literal token
  ///
  /// This method should only be called if [_state] is [_LexState.string].
  int _consumeString(String data, int start) {
    for (var i = start; i < data.length; i++) {
      if (data[i] == '"') {
        _data += data.substring(start, i);
        _state = null;

        _emitToken(
            Literal(
                value: _data,
                location: Location(
                    path: path,
                    line: _line,
                    column: start
                ),
            )
        );

        return i+1;
      }
    }

    _data += data;
    return data.length;
  }

  /// Consume and emit a parenthesis
  int _consumeParen(String data, int start) {
    if (data[start] == '(') {
      _emitToken(
          ParenOpen(
            location: Location(
                path: path,
                line: _line,
                column: start
            ),
          )
      );

      return start + 1;
    }
    else if (data[start] == ')') {
      _emitToken(
          ParenClose(
            location: Location(
                path: path,
                line: _line,
                column: start
            ),
          )
      );

      return start + 1;
    }

    return start;
  }

  /// Consume and emit a brace
  int _consumeBrace(String data, int start) {
    if (data[start] == '{') {
      _emitToken(
          BraceOpen(
            location: Location(
                path: path,
                line: _line,
                column: start
            ),
          )
      );

      return start + 1;
    }
    else if (data[start] == '}') {
      _emitToken(
          BraceClose(
            location: Location(
                path: path,
                line: _line,
                column: start
            ),
          )
      );

      return start + 1;
    }

    return start;
  }

  /// Consume white space
  int _consumeWhiteSpace(String data, int start) {
    final regex = RegExp(r'\s+');
    final match = regex.matchAsPrefix(data, start);

    if (match != null) {
      return match.end;
    }

    return start;
  }

  /// Consume line comments
  int _consumeLineComment(String data, int start) {
    if (data[start] == '#') {
      return data.length;
    }

    return start;
  }

  /// Consume and emit a separator token
  int _consumeSeparator(String data, int start) {
    if (data[start] == ',') {
      _emitToken(
          Separator(
            location: _location
          )
      );
      return start + 1;
    }

    return start;
  }

  /// Emit a [token] to the output stream
  void _emitToken(Token token) =>
      _output.add(token);

  /// Emit an error to the output stream and close the event sink
  void _emitError(Object error) {
    _output.addError(error);
    _output.close();
    _closed = true;
  }
}
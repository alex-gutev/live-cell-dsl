import 'dart:async';
import 'dart:convert';

import 'package:live_cell/lexer/tokens.dart';

/// A stream transfer that converts Strings to [Token]s.
///
/// This transformer reads a strings from a source stream and emits
/// the [Token]s that were parsed from the strings.
class Lexer extends StreamTransformerBase<String, Token> {
  @override
  Stream<Token> bind(Stream<String> stream) => Stream<Token>.eventTransformed(
      stream.transform(LineSplitter()),
      (sink) => TokenEventSink(sink)
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
    _consumeNum,
    _startString,
    _consumeParen,
    _consumeBrace,
    _consumeWhiteSpace
  ];

  /// Identifies the token currently being parsed
  _LexState? _state;

  /// The data associated with the current token
  var _data = '';

  /// The output [Token] stream
  final EventSink<Token> _output;

  TokenEventSink(this._output);

  @override
  void add(String event) {
    var start = 0;

    while (start < event.length) {
      start = _consumeToken(event, start);
    }

    // TODO: If inside a string token add line breaks to data
    _emitToken(Terminator(soft: true));
  }

  @override
  void addError(Object error, [StackTrace? stackTrace]) {
    _output.addError(error, stackTrace);
  }

  @override
  void close() {
    if (_state != null) {
      // TODO: Proper exception type
      // TODO: Add to output stream instead of throwing
      throw Exception('Unclosed string');
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

    // TODO: Proper exception type
    // TODO: Add error to output stream
    throw Exception('Unrecognized token: "${data.substring(start)}"');
  }

  /// Consume and emit an identifier.
  int _consumeId(String data, int start) {
    final regex = RegExp('[a-zA-z_\$][a-zA-Z0-9_\$]*');
    final match = regex.matchAsPrefix(data, start);

    if (match != null) {
      _emitToken(
        IdToken(name: match.group(0)!)
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
      _emitToken(Terminator(soft: false));
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

      _emitToken(isFloat
          ? Literal(value: num.parse(match.group(0)!))
          : Literal(value: int.parse(match.group(0)!))
      );

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

        _emitToken(Literal(value: _data));

        return i+1;
      }
    }

    _data += data;
    return data.length;
  }

  /// Consume and emit a parenthesis
  int _consumeParen(String data, int start) {
    if (data[start] == '(') {
      _emitToken(const ParenOpen());
      return start + 1;
    }
    else if (data[start] == ')') {
      _emitToken(const ParenClose());
    }

    return start;
  }

  /// Consume and emit a brace
  int _consumeBrace(String data, int start) {
    if (data[start] == '{') {
      _emitToken(const BraceOpen());
      return start + 1;
    }
    else if (data[start] == ')') {
      _emitToken(const BraceClose());
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

  /// Emit a [token] to the output stream
  void _emitToken(Token token) =>
      _output.add(token);
}
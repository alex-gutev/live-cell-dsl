import 'tokens.dart';

/// Visitor for [Literal] tokens.
///
/// The only method that needs to be implemented is [visitLiteral]. The
/// remaining methods throw [UnimplementedError] if called.
///
/// Extend this class, instead of implementing [TokenVisitor], when you're
/// only interested in [Literal] tokens.
abstract class LiteralVisitor<R> implements TokenVisitor<R> {
  /// Visit a [Literal] token.
  ///
  /// Only this method needs to be implemented by subclasses.
  @override
  R visitLiteral<T>(Literal<T> token);

  @override
  R visitBraceClose(BraceClose token) {
    throw UnimplementedError();
  }

  @override
  R visitBraceOpen(BraceOpen token) {
    throw UnimplementedError();
  }

  @override
  R visitEndOfInput(EndOfInput token) {
    throw UnimplementedError();
  }

  @override
  R visitId(IdToken id) {
    throw UnimplementedError();
  }

  @override
  R visitParenClose(ParenClose token) {
    throw UnimplementedError();
  }

  @override
  R visitParenOpen(ParenOpen token) {
    throw UnimplementedError();
  }

  @override
  R visitSeparator(Separator token) {
    throw UnimplementedError();
  }

  @override
  R visitTerminator(Terminator token) {
    throw UnimplementedError();
  }
}
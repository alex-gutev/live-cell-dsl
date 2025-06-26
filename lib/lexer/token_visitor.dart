part of 'tokens.dart';

/// Visitor interface for [Token] objects
abstract interface class TokenVisitor<R> {
  R visitId(IdToken id);
  R visitLiteral<T>(Literal<T> token);
  R visitTerminator(Terminator token);
  R visitSeparator(Separator token);
  R visitEndOfInput(EndOfInput token);
  R visitParenOpen(ParenOpen token);
  R visitParenClose(ParenClose token);
  R visitBraceOpen(BraceOpen token);
  R visitBraceClose(BraceClose token);
}
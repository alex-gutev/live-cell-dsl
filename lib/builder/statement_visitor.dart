part of 'effect_spec.dart';

/// Visitor interface for [StatementSpec]s
abstract interface class StatementVisitor<R> {
  R visitExpression(ExpressionStatement statement);
  R visitAssign(AssignStatement statement);
  R visitBlock(BlockStatement statement);
}

/// A visitor that visits every node of a [StatementSpec] tree.
abstract class StatementTreeVisitor extends StatementVisitor<void> {
  @override
  void visitAssign(AssignStatement statement) {
    return statement.value.accept(this);
  }

  @override
  void visitBlock(BlockStatement statement) {
    for (final stmt in statement.statements) {
      stmt.accept(this);
    }
  }

  @override
  void visitExpression(ExpressionStatement statement) {
  }
}
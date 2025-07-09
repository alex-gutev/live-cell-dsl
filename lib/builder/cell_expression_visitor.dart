part of 'cell_spec.dart';

/// Visitor interface for [ValueSpec]s.
abstract interface class ValueSpecVisitor<R> {
  R visitStub(StubExpression expression);
  R visitConstant<T>(Constant<T> expression);
  R visitVariableValue(VariableValue expression);
  R visitRef(CellRef expression);
  R visitApplication(CellApplication expression);
  R visitDeferred(DeferredExpression expression);
  R visitFunction(FunctionExpression expression);
}

/// A visitor that visits every node of a [ValueSpec] tree.
abstract class ValueSpecTreeVisitor extends ValueSpecVisitor<void> {
  @override
  void visitApplication(CellApplication expression) {
    expression.operator.accept(this);
    
    for (final operand in expression.operands) {
      operand.accept(this);
    }
  }

  @override
  void visitConstant<T>(Constant<T> expression) {
  }

  @override
  void visitDeferred(DeferredExpression expression) {
    expression.build().accept(this);
  }

  @override
  void visitFunction(FunctionExpression expression) {
    expression.definition.accept(this);
  }

  @override
  void visitRef(CellRef expression) {
  }

  @override
  void visitStub(StubExpression expression) {
  }

  @override
  void visitVariableValue(VariableValue expression) {
  }
}
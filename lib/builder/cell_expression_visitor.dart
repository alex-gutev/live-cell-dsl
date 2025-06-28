part of 'cell_spec.dart';

/// Visitor interface for [CellExpression]s.
abstract interface class CellExpressionVisitor<R> {
  R visitStub(StubExpression expression);
  R visitConstantValue<T>(ConstantValue<T> expression);
  R visitRef(CellRef expression);
  R visitApplication(CellApplication expression);
  R visitDeferred(DeferredExpression expression);
  R visitFunction(FunctionExpression expression);
}
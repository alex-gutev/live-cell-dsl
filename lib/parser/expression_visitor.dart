part of 'declarations.dart';

/// Visitor interface for [Expression] objects
abstract interface class ExpressionVisitor<R> {
  R visitNamedCell(NamedCell expression);
  R visitConstant<T>(Constant<T> expression);
  R visitOperation(Operation expression);
}

/// Visitor for [Constant] expressions.
///
/// The only method that needs to be implemented is [visitConstant]. The
/// remaining methods throw [UnimplementedError] if called.
///
/// Extend this class, instead of implementing [ExpressionVisitor], when you're
/// only interested in [Constant] expressions.
abstract class ConstantVisitor<R> implements ExpressionVisitor<R> {
  /// Visit a [Constant] expression.
  ///
  /// Only this method needs to be implemented by subclasses.
  @override
  R visitConstant<T>(Constant<T> expression);

  @override
  R visitNamedCell(NamedCell expression) {
    throw UnimplementedError();
  }

  @override
  R visitOperation(Operation expression) {
    throw UnimplementedError();
  }
}
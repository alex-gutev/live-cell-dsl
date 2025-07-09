part of 'ast.dart';

/// Visitor interface for [AstNode] objects
abstract interface class AstVisitor<R> {
  R visitName(Name expression);
  R visitConstant<T>(Constant<T> expression);
  R visitApplication(Application expression);
  R visitBlock(Block expression);
}

/// Visitor for [Constant] nodes.
///
/// The only method that needs to be implemented is [visitConstant]. The
/// remaining methods throw [UnimplementedError] if called.
///
/// Extend this class, instead of implementing [AstVisitor], when you're
/// only interested in visiting [Constant] nodes.
abstract class ConstantVisitor<R> implements AstVisitor<R> {
  /// Visit a [Constant] node.
  ///
  /// Only this method needs to be implemented by subclasses.
  @override
  R visitConstant<T>(Constant<T> expression);

  @override
  R visitName(Name expression) {
    throw UnimplementedError();
  }

  @override
  R visitApplication(Application expression) {
    throw UnimplementedError();
  }

  @override
  R visitBlock(Block expression) {
    throw UnimplementedError();
  }
}
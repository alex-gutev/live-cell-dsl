part of 'cell_spec.dart';

/// Visitor interface for [ValueSpec]s.
abstract interface class ValueSpecVisitor<R> {
  R visitStub(Stub spec);
  R visitConstant<T>(Constant<T> spec);
  R visitVariable(Variable spec);
  R visitRef(CellRef spec);
  R visitApply(ApplySpec spec);
  R visitFunction(FunctionSpec expression);
}

/// A visitor that visits every node of a [ValueSpec] tree.
abstract class ValueSpecTreeVisitor extends ValueSpecVisitor<void> {
  @override
  void visitApply(ApplySpec spec) {
    spec.operator.accept(this);
    
    for (final operand in spec.operands) {
      operand.accept(this);
    }
  }

  @override
  void visitConstant<T>(Constant<T> spec) {
  }

  @override
  void visitFunction(FunctionSpec spec) {
    spec.definition.accept(this);
  }

  @override
  void visitRef(CellRef spec) {
  }

  @override
  void visitStub(Stub spec) {
  }

  @override
  void visitVariable(Variable spec) {
  }
}
import 'package:live_cells_core/live_cells_core.dart';

import 'cell_table.dart';
import '../util/equality.dart';

part 'cell_expression_visitor.dart';
part 'cell_spec.g.dart';

/// Base class representing a cell identifier
sealed class CellId {
  const CellId();
}

/// A cell identified by a string name
@DataClass()
class NamedCellId extends CellId {
  /// The name identifying the cell
  final String name;

  const NamedCellId(this.name);

  @override
  bool operator ==(Object other) => _$NamedCellIdEquals(this, other);

  @override
  int get hashCode => _$NamedCellIdHashCode(this);
}

/// Identifies a cell consisting of an [operator] applied on one or more [operands].
@DataClass()
class AppliedCellId extends CellId {
  final CellId operator;

  @listField
  final List<CellId> operands;

  const AppliedCellId({
    required this.operator,
    required this.operands
  });

  @override
  bool operator ==(Object other) => _$AppliedCellIdEquals(this, other);

  @override
  int get hashCode => _$AppliedCellIdHashCode(this);
}

/// Identifies a constant value
///
/// This isn't used to identify a cell, but represents constant values where
/// a cell is expected.
class ValueCellId extends CellId {
  final dynamic value;

  const ValueCellId(this.value);

  @override
  bool operator ==(Object other) =>
      other is ValueCellId &&
      value == other.value;

  @override
  int get hashCode => value.hashCode;
}

/// A specification for a cell
class CellSpec {
  /// Cell identifier
  final CellId id;

  /// The specified definition of the cell
  final CellExpression definition;

  /// The scope in which this cell is defined
  final CellTable? scope;

  const CellSpec({
    required this.id,
    required this.definition,
    required this.scope
  });
}

/// Specification for a cell holding a constant value
class ValueCellSpec extends CellSpec {
  const ValueCellSpec({
    required super.id,
    required super.definition,
    super.scope
  });

  /// Create a [ValueCellSpec] holding a given constant [value].
  static ValueCellSpec forValue<T>(T value) => ValueCellSpec(
      id: ValueCellId(value),
      definition: ConstantValue(value)
  );
}

/// Base class representing a cell expression specification
sealed class CellExpression {
  const CellExpression();

  /// Visit this expression with [visitor].
  R accept<R>(CellExpressionVisitor<R> visitor);
}

/// Represents a cell which hasn't been defined yet
class StubExpression extends CellExpression {
  const StubExpression();

  @override
  R accept<R>(CellExpressionVisitor<R> visitor) =>
      visitor.visitStub(this);
}

/// Represents a constant value
class ConstantValue<T> extends CellExpression {
  /// The value
  final T value;

  const ConstantValue(this.value);

  @override
  R accept<R>(CellExpressionVisitor<R> visitor) =>
      visitor.visitConstantValue(this);
}

/// Base class representing a reference to a cell's value
abstract class CellRef extends CellExpression {
  /// Get the specification of the referenced cell
  CellSpec get get;

  const CellRef();

  @override
  R accept<R>(CellExpressionVisitor<R> visitor) =>
      visitor.visitRef(this);
}

/// Represents an expression consisting of an [operator] applied on one or more [operands].
class CellApplication extends CellExpression {
  /// The operator that is applied
  final CellExpression operator;

  /// The operands on which the [operator] is applied
  final List<CellExpression> operands;

  const CellApplication({
    required this.operator,
    required this.operands
  });

  @override
  R accept<R>(CellExpressionVisitor<R> visitor) =>
      visitor.visitApplication(this);
}

/// An expression that is built at a later stage
abstract class DeferredExpression extends CellExpression {
  const DeferredExpression();

  /// Build the expression
  ///
  /// *NOTE*: This method should cache the expression after it is built for
  /// the first time, rather than building it every time this method called.
  CellExpression build();

  @override
  R accept<R>(CellExpressionVisitor<R> visitor) =>
      visitor.visitDeferred(this);
}

/// Represents a function definition
class FunctionExpression extends CellExpression {
  /// List of argument cell identifiers
  final List<CellId> arguments;

  /// The function's local scope
  final CellTable scope;

  /// Expression defining the result of the function
  final CellExpression definition;

  /// Set of cells referenced by this function
  Set<CellSpec> get referencedCells {
    if (_external == null) {
      _external = {};

      for (final spec in scope.cells) {
        _walkSpec(
            spec: spec,
            external: _external!
        );
      }
    }

    return _external!;
  }

  FunctionExpression({
    required this.arguments,
    required this.scope,
    required this.definition
  });

  @override
  R accept<R>(CellExpressionVisitor<R> visitor) =>
      visitor.visitFunction(this);

  // Private

  /// Set of cells referenced by this function
  Set<CellSpec>? _external;

  /// Determine the external cells referenced by a cell specification.
  ///
  /// The cells referenced by the cell represented by [spec], that are not
  /// contained in the function's local [scope] are added to [external].
  void _walkSpec({
    required CellSpec spec,
    required Set<CellSpec> external,
  }) {
    _walkExpression(
        expression: spec.definition,
        external: external
    );
  }


  /// Determine the external cells referenced in an [expression].
  ///
  /// The cells referenced in the [expression], that are not
  /// contained in the function's local [scope] are added to [external].
  void _walkExpression({
    required CellExpression expression,
    required Set<CellSpec> external,
  }) {
    switch (expression) {
      case StubExpression():
      case ConstantValue():
        break;

      case CellRef(get: final cell):
        if (cell.scope != scope) {
          external.add(cell);
        }

      case CellApplication(
        :final operator,
        :final operands
      ):
        _walkExpression(
            expression: operator,
            external: external,
        );

        for (final operand in operands) {
          _walkExpression(
              expression: operand,
              external: external,
          );
        }

      case final FunctionExpression function:
        external.addAll(
            function.referencedCells
                .where((c) => c.scope != scope)
        );

      case final DeferredExpression deferred:
        _walkExpression(
            expression: deferred.build(),
            external: external,
        );
    }
  }
}
import 'package:live_cells_core/live_cells_core.dart';

import '../util/equality.dart';

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
}

/// A specification for a cell
class CellSpec {
  /// Cell identifier
  final CellId id;

  /// The specified definition of the cell
  final CellExpression definition;

  const CellSpec({
    required this.id,
    required this.definition
  });
}

/// Base class representing a cell expression specification
sealed class CellExpression {
  const CellExpression();
}

/// Represents a cell which hasn't been defined yet
class StubExpression extends CellExpression {
  const StubExpression();
}

/// Represents a constant value
class ConstantValue<T> extends CellExpression {
  /// The value
  final T value;

  const ConstantValue(this.value);
}

/// Base class representing a reference to a cell's value
abstract class CellRef extends CellExpression {
  /// Get the specification of the referenced cell
  CellSpec get get;

  const CellRef();
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
}
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

  @override
  String toString() => name;
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

  @override
  String toString() => '$operator(${operands.join(', ')})';
}

/// Identifies a constant value
///
/// This isn't used to identify a cell, but represents constant values where
/// a [CellId] is expected.
class ValueCellId extends CellId {
  final dynamic value;

  const ValueCellId(this.value);

  @override
  bool operator ==(Object other) =>
      other is ValueCellId &&
      value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'Value($value)';
}

/// A specification for a cell
class CellSpec {
  /// Cell identifier
  final CellId id;

  /// Specification defining how the cell's value is computed
  final ValueSpec definition;

  /// The scope in which this cell is defined
  final CellTable? scope;

  /// The line in the source where the cell is defined?
  final int? line;

  /// The column in the source where the cell is defined?
  final int? column;

  /// Has this cell been defined?
  ///
  /// If false then this cell has been declared but not defined.
  final bool defined;

  const CellSpec({
    required this.id,
    required this.definition,
    required this.scope,
    this.line,
    this.column,
    this.defined = false
  });

  /// Get the value of an [attribute] applying to this cell
  dynamic getAttribute(String attribute) =>
      scope?.getAttribute(id, attribute);

  /// Set the value of an [attribute] applying to this cell
  void setAttribute(String attribute, value) {
    scope?.setAttribute(
        id: id,
        attribute: attribute,
        value: value
    );
  }
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
      definition: Constant(value)
  );
}

/// Base class specifying the definition of a cell's value
sealed class ValueSpec {
  const ValueSpec();

  /// Visit this spec with [visitor].
  R accept<R>(ValueSpecVisitor<R> visitor);
}

/// Represents the lack of a definition.
/// 
/// This class is used as the definition of a cell when a cell is first
/// declared but hasn't been defined yet. It is also used as the definition
/// of cells that represent function arguments.
class Stub extends ValueSpec {
  const Stub();

  @override
  R accept<R>(ValueSpecVisitor<R> visitor) =>
      visitor.visitStub(this);
}

/// Represents a constant [value]
class Constant<T> extends ValueSpec {
  /// The value
  final T value;

  const Constant(this.value);

  @override
  R accept<R>(ValueSpecVisitor<R> visitor) =>
      visitor.visitConstant(this);
}

/// Represents a variable value definition.
/// 
/// This class is used as the definition of mutable cells.
class Variable extends ValueSpec {
  const Variable();

  @override
  R accept<R>(ValueSpecVisitor<R> visitor) =>
      visitor.visitVariable(this);
}

/// Base class representing a reference to a cell's value
abstract class CellRef extends ValueSpec {
  /// Get the specification of the referenced cell
  CellSpec get get;

  const CellRef();

  @override
  R accept<R>(ValueSpecVisitor<R> visitor) =>
      visitor.visitRef(this);
}

/// Represents the application of an [operator] on one or more [operands].
class ApplySpec extends ValueSpec {
  /// The operator that is applied
  final ValueSpec operator;

  /// The operands on which the [operator] is applied
  final List<ValueSpec> operands;

  const ApplySpec({
    required this.operator,
    required this.operands
  });

  @override
  R accept<R>(ValueSpecVisitor<R> visitor) =>
      visitor.visitApply(this);
}

/// A [ValueSpec] that is built at a later stage.
///
/// The building of the spec is deferred to when [build] is called.
abstract class DeferredSpec extends ValueSpec {
  const DeferredSpec();

  /// Build the specification
  ///
  /// *NOTE*: This method should cache the specification after it is built for
  /// the first time, rather than building it every time this method called.
  ValueSpec build();

  @override
  R accept<R>(ValueSpecVisitor<R> visitor) =>
      visitor.visitDeferred(this);
}

/// Represents a function definition
class FunctionSpec extends ValueSpec {
  /// List of argument cell identifiers
  final List<CellId> arguments;

  /// The function's local scope
  final CellTable scope;

  /// Specification defining the result of the function
  final ValueSpec definition;

  /// Set of cells referenced by this function
  Set<CellSpec> get referencedCells {
    if (_external == null) {
      _external = {};

      for (final spec in scope.cells) {
        spec.definition.accept(
          _ExternalCellVisitor(
              scope: scope,
              external: _external!
          )
        );
      }
    }

    return _external!;
  }

  FunctionSpec({
    required this.arguments,
    required this.scope,
    required this.definition
  });

  @override
  R accept<R>(ValueSpecVisitor<R> visitor) =>
      visitor.visitFunction(this);

  // Private

  /// Set of cells referenced by this function
  Set<CellSpec>? _external;
}

/// Visitor that determines set of referenced cells that are external to [scope].
///
/// Cells referenced within [scope], which are not defined in [scope] are
/// added to the set [external].
class _ExternalCellVisitor extends ValueSpecTreeVisitor {
  final CellTable scope;
  final Set<CellSpec> external;

  _ExternalCellVisitor({
    required this.scope,
    required this.external
  });

  @override
  void visitRef(CellRef spec) {
    final cell = spec.get;

    if (cell.scope != scope) {
      external.add(cell);
    }
  }

  @override
  void visitFunction(FunctionSpec spec) {
    external.addAll(
        spec.referencedCells
            .where((c) => c.scope != scope)
    );
  }
}
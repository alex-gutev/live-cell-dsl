import 'cell_spec.dart';
import 'cell_table.dart';
import '../parser/index.dart';

/// Builds cell specifications from parsed cell [Expression]s
class CellBuilder {
  /// The table holding all cells defined in the global scope
  final globalTable = CellTable();

  /// Build the cell specifications from the given [declarations].
  Future<void> build(Stream<Expression> declarations) async {
    await for (final declaration in declarations) {
      _buildCell(declaration);
    }
  }

  // Private

  /// Build a cell from a given [declaration] and add it to [globalTable].
  void _buildCell(Expression declaration) {
    switch (declaration) {
      case NamedCell(:final name):
        globalTable.add(
            CellSpec(
                id: NamedCellId(name),
                definition: const StubExpression()
            )
        );

      case Constant():
        break;

      // TODO: Match proper definition operator
      // TODO: Handle function definitions
      case Operation(
        operator: NamedCell(name: '='),
        args: [NamedCell(:final name), final definition]
      ):
        globalTable.add(
          CellSpec(
              id: NamedCellId(name),
              definition: _NamedCellRef(
                  table: globalTable,
                  id: _idForExpression(definition)
              )
          )
        );

        _buildCell(definition);

      case Operation(:final operator, :final args):
        globalTable.add(
          CellSpec(
              id: _idForExpression(declaration),
              definition: _buildExpression(declaration)
          )
        );

        _buildCell(operator);
        args.forEach(_buildCell);
    }
  }

  /// Get the identifier for a cell defined by [expression].
  CellId _idForExpression(Expression expression) => switch (expression) {
    NamedCell(:final name) => NamedCellId(name),

    Constant(:final value) => ValueCellId(value),

    Operation(:final operator, :final args) =>
      AppliedCellId(
        operator: _idForExpression(operator),
        operands: args.map(_idForExpression).toList()
      ),
  };

  /// Build the [CellExpression] specification for a given [expression].
  CellExpression _buildExpression(Expression expression) => switch (expression) {
    NamedCell() => _NamedCellRef(
      table: globalTable,
      id: _idForExpression(expression)
    ),

    Constant<int>(:final value) =>
        ConstantValue(value),

    Constant<num>(:final value) =>
        ConstantValue(value),

    Constant<String>(:final value) =>
        ConstantValue(value),

    Operation(:final operator, :final args) => CellApplication(
      operator: _buildExpression(operator),
      operands: args.map(_buildExpression).toList()
    ),

    _ => throw UnimplementedError()
  };
}

/// A reference to a cell within a given cell [table].
class _NamedCellRef extends CellRef {
  /// Table in which the cell is referenced
  final CellTable table;

  /// ID of the referenced cell
  final CellId id;

  const _NamedCellRef({
    required this.table,
    required this.id
  });

  @override
  CellSpec get get => table.get(id);
}
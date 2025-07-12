import 'cell_builder.dart';
import 'cell_spec.dart';
import 'modules.dart';
import '../parser/index.dart';

/// Contains the special operators in the core module
class Operators {
  /// Import module operator
  static const import = NamedCellId('import',
    module: 'live_cell.core'
  );

  /// Define cell operator
  static const define = NamedCellId('=',
    module: 'live_cell.core'
  );

  /// Declare externally defined cell operator
  static const external = NamedCellId('external',
    module: 'live_cell.core'
  );

  /// Map from top-level special operator identifiers to the processor functions.
  static final topLevelOperators = {
    import: importModule
  };

  /// Set of all special operator ids
  static Set<NamedCellId> get operatorIds =>
      topLevelOperators.keys.toSet();

  /// Is [id] the name of a special top-level operator
  static bool isTopLevelOperator(NamedCellId id) =>
    topLevelOperators.containsKey(id);

  /// Process a top-level special declaration.
  ///
  /// This function runs the processor function associated with the top-level
  /// special operator identifier by [id], on the given [operands].
  static Future<void> processTopLevel({
    required NamedCellId id,
    required CellBuilder builder,
    required List<AstNode> operands
  }) => topLevelOperators[id]!(builder, operands);

  // Special operator definitions

  /// Import special operator processor function.
  static Future<void> importModule(CellBuilder builder, List<AstNode> args) async {
    if (args case [Name(:final name)]) {
      if (builder.loadModule == null) {
        // TODO: Proper exception type
        throw Exception('No load module function');
      }

      final src = builder.loadModule!(name);

      final moduleBuilder = CellBuilder(
        scope: builder.scope,
        module: ModuleSpec(src.name),
        loadModule: builder.loadModule
      );

      await moduleBuilder.processSource(src.nodes);

      builder.module.importAll(moduleBuilder.module);
    }
    else {
      throw Exception('Malformed import declaration');
    }
  }
}
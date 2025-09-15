import 'cell_builder.dart';
import 'cell_spec.dart';
import 'exceptions.dart';
import 'modules.dart';
import '../parser/index.dart';

/// Signature of top-level special declaration processor.
typedef TopLevelProcessor = 
  Future<void> Function(CellBuilder, List<AstNode>);

/// Contains the special operators in the core module
class Operators {
  /// Import module operator
  static const import = NamedCellId('import',
    module: 'live_cell.core'
  );

  /// Declare infix/prefix/postfix operator
  static const operator = NamedCellId('operator',
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
  static final topLevelOperators = <NamedCellId, TopLevelProcessor>{
    import: _ModuleImporter().call,
    operator: _registerOperator
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


  /// Special operator processors

  /// Process operator declaration
  static Future<void> _registerOperator(
      CellBuilder builder,
      List<AstNode> args
      ) async {
    switch (args) {
      case [
        Name(:final name),
        Name(name: ('infix' || 'prefix') && final type),
        Value<int>(value: final precedence),
        Name(name: ('left' || 'right') && final associativity)
      ]:

        builder.operatorTable.add(
          Operator(
              name: name,
              type: OperatorType.fromName(type),
              precedence: precedence,
              leftAssoc: associativity == 'left'
          )
        );

      case [
        Name(:final name),
        Name(name: ('infix' || 'prefix') && final type),
        Value<int>(value: final precedence),
      ]:
        builder.operatorTable.add(
            Operator(
                name: name,
                type: OperatorType.fromName(type),
                precedence: precedence,
                leftAssoc: true
            )
        );

      default:
        throw MalformedOperatorDeclarationError();
    }
  }
}

// Special Operator Processor Functions

class _ModuleImporter {
  /// Set of modules currently being imported
  /// 
  /// This is used to detect circular imports
  final _importingModules = <String>{};

  Future<void> call(CellBuilder builder, List<AstNode> args) async {
    if (args case [Name(:final name)]) {
      if (builder.loadModule == null) {
        // TODO: Proper exception type
        throw Exception('No load module function');
      }

      final src = builder.loadModule!(name);

      if (_importingModules.contains(src.name)) {
        throw CircularImportError(name: src.name);
      }
      
      var module = builder.scope.getModuleSpec(src.name);

      if (module == null) {
        module = ModuleSpec(src.name);

        builder.scope.addModuleSpec(module);

        final moduleBuilder = CellBuilder(
            scope: builder.scope,
            module: module,
            loadModule: builder.loadModule,
            operatorTable: builder.operatorTable
        );

        try {
          _importingModules.add(src.name);
          await moduleBuilder.processSource(src.nodes);
        }
        finally {
          _importingModules.remove(src.name);
        }
      }

      builder.module.importAll(module);
    }
    else {
      throw MalformedImportError();
    }
  }
}
import 'package:code_builder/code_builder.dart';

/// Wrap [expression] in a 'thunk.
Expression makeThunk(Expression expression) =>
    refer('Thunk').call([
      Method((b) => b
          ..lambda = true
          ..body = expression.code
      ).closure
    ]);
import 'package:live_cell/builder/cell_spec.dart';

/// Container for constants identifying cell attributes
class Attributes {
  /// Externally defined flag attribute
  static const external = 'external';

  /// Cell represents a function argument
  static const argument = 'argument';

  /// Should this cell be folded?
  static const fold = 'fold';
}

/// Provides methods for querying commonly used attributes
extension CellAttributeExtension on CellSpec {
  /// Is this an externally defined cell?
  bool isExternal() => getAttribute(Attributes.external) ?? false;

  /// Is this a function argument cell?
  bool isArgument() => getAttribute(Attributes.argument) ?? false;

  /// Can this cell be folded?
  bool foldable() => getAttribute(Attributes.fold) ?? false;
}
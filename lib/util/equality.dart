import 'package:collection/collection.dart';
import 'package:live_cells_core/live_cells_core.dart';

/// Annotate a property to use list equality and hash functions
const listField = DataField(
    equals: listEquals,
    hash: listHashCode
);

/// Annotate a property to use map equality and hash functions
const mapField = DataField(
    equals: mapEquals,
    hash: mapHashCode
);

/// Annotate a property to use set equality and hash functions
const setField = DataField(
  equals: setEquals,
  hash: setHashCode
);

/// Compare two lists for equality
bool listEquals<T>(List<T> a, List<T> b) => const ListEquality().equals(a, b);

/// Compute the hash code of a list
int listHashCode<T>(List<T> o) => const ListEquality().hash(o);

/// Compare two maps for equality
bool mapEquals<K,V>(Map<K,V> a, Map<K,V> b) => const MapEquality().equals(a, b);

/// Compute the hash code of a map
int mapHashCode<K,V>(Map<K,V> o) => const MapEquality().hash(o);

/// Compare two sets for equality
bool setEquals<E>(Set<E> a, Set<E> b) => const SetEquality().equals(a, b);

/// Compute the hash code of a set
int setHashCode<E>(Set<E> o) => const SetEquality().hash(o);
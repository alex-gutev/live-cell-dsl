import 'thunk.dart';

// Arithmetic

/// The `+` function
num add(Argument a, Argument b) =>
    a.get<num>() + b.get<num>();

/// The `-` function
num sub(Argument a, Argument b) =>
    a.get<num>() - b.get<num>();

/// The `*` function
num mul(Argument a, Argument b) =>
    a.get<num>() * b.get<num>();

/// The `/` function
num div(Argument a, Argument b) =>
    a.get<num>() / b.get<num>();

/// The `%` function
num mod(Argument a, Argument b) =>
    a.get<num>() % b.get<num>();

// Equality

/// The `==` comparison function
bool eq(Argument a, Argument b) =>
    a.get() == b.get();

/// The `!=` comparison function
bool neq(Argument a, Argument b) =>
    a.get() != b.get();

// Comparison

/// The `<` comparison function
bool lt(Argument a, Argument b) =>
    a.get<num>() < b.get<num>();

/// The `>` comparison function
bool gt(Argument a, Argument b) =>
    a.get<num>() > b.get<num>();

/// The `<=` comparison function
bool lte(Argument a, Argument b) =>
    a.get<num>() <= b.get<num>();

/// The `>=` comparison function
bool gte(Argument a, Argument b) =>
    a.get<num>() >= b.get<num>();

// Boolean

/// The `!` negation function
bool not(Argument a) =>
    !a.get<bool>();

/// The `and` function
bool and(Argument a, Argument b) =>
    a.get<bool>() && b.get<bool>();

/// The `or` function
bool or(Argument a, Argument b) =>
    a.get<bool>() || b.get<bool>();

// Branching

dynamic select(
    Argument condition,
    Argument ifTrue,
    Argument ifFalse
) => condition.get<bool>()
    ? ifTrue.get()
    : ifFalse.get();

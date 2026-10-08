/// Wraps a value for a nullable `copyWith` parameter so "not passed" (keep)
/// and "set to null" (clear) can be told apart.
///
/// Omit to keep, `const Nullable(null)` to clear, `Nullable(value)` to set.
/// See `.cursor/rules/copywith-nullable-fields.mdc`.
class Nullable<T> {
  final T? _value;

  // Positional on purpose (exception to the named-params rule): a
  // single-value wrapper reads best as `Nullable(null)`.
  const Nullable(this._value);

  T? get value => _value;
}

extension NullableX<T> on T {
  Nullable<T> get asNullable => Nullable<T>(this);
}

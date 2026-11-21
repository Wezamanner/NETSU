class PhoneNumber {
  const PhoneNumber._();

  static final _e164 = RegExp(r'^\+2519\d{8}$');

  /// Accepts 09XXXXXXXX, 2519XXXXXXXX, or +2519XXXXXXXX.
  static String? normalize(String input) {
    final compact = input.trim().replaceAll(RegExp(r'[\s-]'), '');
    final candidate = switch (compact) {
      _ when RegExp(r'^09\d{8}$').hasMatch(compact) => '+251${compact.substring(1)}',
      _ when RegExp(r'^2519\d{8}$').hasMatch(compact) => '+$compact',
      _ => compact,
    };
    return _e164.hasMatch(candidate) ? candidate : null;
  }

  /// Decision 9: phone plus password through a synthetic email.
  static String syntheticEmail(String e164) => '${e164.replaceAll('+', '')}@jimma-waste.app';
}

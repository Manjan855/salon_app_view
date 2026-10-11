/// Pure helper for the Explore "Gender" filter.
///
/// [gender] is one of the sheet's labels: `'All'`, `'Men'`, `'Women'` or
/// `'Unisex'`. [gendersBySalon] maps a `public.salons.id` to the set of
/// `public.services.gender` values ('men' | 'women' | 'unisex') that salon
/// offers. Salons with no facet data (offline/demo rows) are treated as
/// unisex, i.e. gender-neutral.
///
/// Kept free of any Flutter/Supabase dependency so it is unit-testable.
bool salonMatchesGender(
  Map<String, Set<String>> gendersBySalon,
  String? salonId,
  String gender,
) {
  if (gender == 'All') return true;

  final known = salonId == null ? null : gendersBySalon[salonId];
  if (known == null || known.isEmpty) {
    // No facet data (offline/demo rows): gender-neutral, so only the
    // 'Unisex' filter keeps them.
    return gender == 'Unisex';
  }

  switch (gender) {
    case 'Men':
      // A men-only salon, plus any unisex salon (it serves men too).
      return known.contains('men') || known.contains('unisex');
    case 'Women':
      return known.contains('women') || known.contains('unisex');
    case 'Unisex':
      return known.contains('unisex');
    default:
      return true;
  }
}
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'locale_controller.dart';

// NOTE: Currency conversion is display-only — the app switches the symbol and
// digit style based on locale, but does NOT apply a live EUR→IRR exchange rate.
// When real conversion is needed, inject the rate here before formatting.
//
// ─────────────────────────────────────────────────────────────────────────────
// CurrencyFormatter
// ─────────────────────────────────────────────────────────────────────────────
//
// Single source of truth for every number shown in the UI.
// Reads [LocaleController] once per call — no parameters needed at call sites,
// and the output changes automatically the moment the user switches language.
//
// CURRENCY
//   EN (Euro)   — prefix symbol, 2 decimal places, Latin digits
//                 €12.50  |  €12  |  €1.2k  |  €2.50/kg
//   FA (Toman)  — suffix unit, same decimal places as EN, Persian digits
//                 ۱۲٫۵۰ تومان  |  ۱۲ تومان  |  ۱۲ هزار تومان  |  کیلویی ۲٫۵۰ تومان
//   Only the digits/label change per locale — the underlying amount (and its
//   precision) is identical in both, since there's no real EUR→IRR rate
//   applied (see the NOTE above). `round()`/`compact()` intentionally drop
//   decimals in both locales; plain `format()` must not, in either — losing
//   the cents on a real charge (e.g. a €1.40 delivery fee) is a bug, not a
//   presentation choice.
//
// NON-CURRENCY NUMBERS
//   localizeDigits converts any ASCII digit string to Persian when locale=FA.
//   Use it for ratings, counts, weights, percentages — anything not a price.
//   EN: 4.8 / 15% / 1.5 kg      FA: ۴.۸ / ۱۵٪ / ۱.۵ کیلو
//
// QUICK REFERENCE
//   CurrencyFormatter.format(amount)            €12.50       ۱۲٫۵۰ تومان
//   CurrencyFormatter.round(amount)             €12          ۱۲ تومان
//   CurrencyFormatter.compact(amount)           €1.2k        ۱۲ هزار تومان
//   CurrencyFormatter.perKg(amount)             €2.50/kg     کیلویی ۲٫۵۰ تومان
//   CurrencyFormatter.symbol                    €            تومان
//   CurrencyFormatter.symbolAfter               false        true
//   CurrencyFormatter.formatPercent(15.1)       +15.1%       +۱۵.۱٪
//   CurrencyFormatter.formatPercentPlain(15.0)  15%          ۱۵٪
//   CurrencyFormatter.formatWeight(1.5)         1.5 kg       ۱.۵ کیلو
//   CurrencyFormatter.localizeDigits('4.8')     4.8          ۴.۸
abstract class CurrencyFormatter {
  static bool get _isFarsi =>
      Get.find<LocaleController>().locale.value.languageCode == 'fa';

  // ── Farsi label constants — edit here to change everywhere ────────────────

  /// Currency unit label.
  static const String faToman = 'تومان';

  /// Thousands abbreviation (e.g. ۵ هزار تومان).
  static const String faThousand = 'هزار';

  /// Millions abbreviation (e.g. ۵.۲ م تومان).
  static const String faMillion = 'م';

  /// Prefix label for per-kg prices (e.g. کیلویی ۵٬۰۰۰ تومان).
  static const String faPerKgLabel = 'کیلویی';

  /// Weight unit label used in quantities and weight inputs.
  static const String faKgUnit = 'کیلو';

  // ── Currency ──────────────────────────────────────────────────────────────

  /// Full format with [decimals] decimal places (default 2).
  /// EN: €12.50    FA: ۱۲٬۵۰۰.۵۰ تومان
  ///
  /// The FA branch only swaps digit glyphs/label — the underlying amount is
  /// still the real Euro figure (see the note at the top of this file), so it
  /// must keep [decimals] like the EN branch does. Rounding it away here
  /// would silently drop real fractional charges (e.g. a €1.40 delivery fee
  /// showing as ۱ تومان) whenever the app is in Farsi.
  static String format(double amount, {int decimals = 2}) {
    if (_isFarsi) return '${_faDecimal(amount, decimals)} $faToman';
    return _euroFormat(decimals).format(amount);
  }

  static final Map<int, NumberFormat> _euroFormats = {};

  static NumberFormat _euroFormat(int decimals) => _euroFormats.putIfAbsent(
    decimals,
    () => NumberFormat.currency(symbol: '€', decimalDigits: decimals),
  );

  static final Map<int, NumberFormat> _faDecimalFormats = {};

  static NumberFormat _faDecimalFormat(int decimals) =>
      _faDecimalFormats.putIfAbsent(
        decimals,
        () => NumberFormat(
          decimals > 0 ? '#,##0.${'0' * decimals}' : '#,###',
          'fa',
        ),
      );

  static String _faDecimal(double amount, int decimals) =>
      _faDecimalFormat(decimals).format(amount);

  /// Zero decimal places — for dashboard stats and large figures.
  /// EN: €12    FA: ۱۲٬۵۰۰ تومان
  static String round(double amount) => format(amount, decimals: 0);

  /// Abbreviated for chart bar labels and tight spaces.
  /// EN: €1.2k / €245    FA: ۱۲ هزار تومان / ۲۴۵ تومان
  static String compact(double amount) {
    if (_isFarsi) {
      if (amount >= 1000000) {
        final m = (amount / 1000000).toStringAsFixed(1);
        return '${localizeDigits(m)} $faMillion $faToman';
      }
      if (amount >= 1000) {
        return '${localizeDigits('${(amount / 1000).round()}')} $faThousand $faToman';
      }
      return '${localizeDigits('${amount.round()}')} $faToman';
    }
    if (amount >= 1000) return '€${(amount / 1000).toStringAsFixed(1)}k';
    return '€${amount.toStringAsFixed(0)}';
  }

  /// Per-kg price label.
  /// EN: €2.50/kg    FA: کیلویی ۲٬۵۰۰ تومان
  static String perKg(double amount) =>
      _isFarsi ? '$faPerKgLabel ${format(amount)}' : '${format(amount)}/kg';

  /// Just the currency symbol/unit.
  /// EN: €    FA: تومان
  static String get symbol => _isFarsi ? faToman : '€';

  /// True when the current locale is Farsi. Use this in widgets that need to
  /// switch layout (e.g. prefix vs suffix positioning) rather than just text.
  static bool get isFarsi => _isFarsi;

  /// True when the unit label appears after the number (always true for FA).
  static bool get symbolAfter => _isFarsi;

  // ── General number helpers ────────────────────────────────────────────────

  /// Converts every ASCII digit in [text] to its Persian equivalent when in
  /// FA locale; returns [text] unchanged in EN locale.
  /// Use for ratings, counts, percentages, weights — any non-currency number.
  ///   localizeDigits('4.8')    → '۴.۸'   (FA)  |  '4.8'   (EN)
  ///   localizeDigits('15%')    → '۱۵%'   (FA)  |  '15%'   (EN)
  ///   localizeDigits('1.5')    → '۱.۵'   (FA)  |  '1.5'   (EN)
  static String localizeDigits(String text) {
    if (!_isFarsi) return text;
    return text.splitMapJoin(
      RegExp(r'[0-9]'),
      onMatch: (m) => _l2p[m.group(0)]!,
      onNonMatch: (s) => s,
    );
  }

  /// Formats a percentage value with digit localization.
  /// EN: 15.1%    FA: ۱۵.۱٪
  static String formatPercent(double value, {int decimals = 1}) {
    final sign = value >= 0 ? '+' : '−';
    final str = '${value.abs().toStringAsFixed(decimals)}%';
    return '$sign${localizeDigits(str)}';
  }

  /// Formats a percentage without sign (for labels like service fee "15%").
  static String formatPercentPlain(double value, {int decimals = 0}) {
    return localizeDigits('${value.toStringAsFixed(decimals)}%');
  }

  /// Formats a weight with digit localization.
  /// EN: 1.5 kg    FA: ۱.۵ کیلو
  static String formatWeight(double kg, {int decimals = 1}) {
    final num = localizeDigits(kg.toStringAsFixed(decimals));
    return _isFarsi ? '$num $faKgUnit' : '$num kg';
  }

  /// Parses a number string that may contain Persian digits or commas.
  /// Use this wherever form fields are initialized with [localizeDigits].
  static double parseLocalizedDouble(String text) {
    final normalized = text
        .replaceAll(',', '.')
        .splitMapJoin(
          RegExp(r'[۰-۹]'),
          onMatch: (m) => _p2l[m.group(0)] ?? m.group(0)!,
          onNonMatch: (s) => s,
        );
    return double.tryParse(normalized) ?? 0;
  }

  // ── Internal ─────────────────────────────────────────────────────────────

  static const _l2p = {
    '0': '۰',
    '1': '۱',
    '2': '۲',
    '3': '۳',
    '4': '۴',
    '5': '۵',
    '6': '۶',
    '7': '۷',
    '8': '۸',
    '9': '۹',
  };

  static const _p2l = {
    '۰': '0',
    '۱': '1',
    '۲': '2',
    '۳': '3',
    '۴': '4',
    '۵': '5',
    '۶': '6',
    '۷': '7',
    '۸': '8',
    '۹': '9',
  };
}

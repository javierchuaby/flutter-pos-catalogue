/// Utility class for formatting prices consistently across the app
class PriceFormatter {
  /// Formats a price string to ensure it has 2 decimal places
  /// Handles edge cases like null, empty strings, and invalid formats
  static String formatPrice(String price) {
    if (price.isEmpty) return '0.00';
    
    final parsedPrice = double.tryParse(price);
    if (parsedPrice == null) {
      // If parsing fails, try to clean the string and parse again
      final cleaned = price.replaceAll(RegExp(r'[^\d.]'), '');
      final retry = double.tryParse(cleaned);
      return retry?.toStringAsFixed(2) ?? '0.00';
    }
    
    return parsedPrice.toStringAsFixed(2);
  }

  /// Formats a price string with currency symbol
  static String formatPriceWithCurrency(String price) {
    return '\$${formatPrice(price)}';
  }
}


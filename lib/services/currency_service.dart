import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class Currency {
  final String code;
  final String symbol;
  final String name;

  const Currency({
    required this.code,
    required this.symbol,
    required this.name,
  });
}

final availableCurrencies = [
  Currency(code: 'USD', symbol: '\$', name: 'US Dollar'),
  Currency(code: 'EUR', symbol: '€', name: 'Euro'),
  Currency(code: 'GBP', symbol: '£', name: 'British Pound'),
  Currency(code: 'JPY', symbol: '¥', name: 'Japanese Yen'),
  Currency(code: 'INR', symbol: '₹', name: 'Indian Rupee'),
  Currency(code: 'CNY', symbol: '¥', name: 'Chinese Yuan'),
  Currency(code: 'AUD', symbol: 'A\$', name: 'Australian Dollar'),
  Currency(code: 'CAD', symbol: 'C\$', name: 'Canadian Dollar'),
  Currency(code: 'CHF', symbol: 'Fr', name: 'Swiss Franc'),
  Currency(code: 'HKD', symbol: 'HK\$', name: 'Hong Kong Dollar'),
  Currency(code: 'SGD', symbol: 'S\$', name: 'Singapore Dollar'),
  Currency(code: 'SEK', symbol: 'kr', name: 'Swedish Krona'),
  Currency(code: 'KRW', symbol: '₩', name: 'South Korean Won'),
  Currency(code: 'BRL', symbol: 'R\$', name: 'Brazilian Real'),
  Currency(code: 'RUB', symbol: '₽', name: 'Russian Ruble'),
];

// Provider for the list of available currencies
final currenciesProvider = Provider<List<Currency>>((ref) => availableCurrencies);

// Provider for the selected currency
final currencyProvider = StateNotifierProvider<CurrencyNotifier, Currency>((ref) {
  return CurrencyNotifier();
});

class CurrencyNotifier extends StateNotifier<Currency> {
  static const _key = 'currency_code';
  
  CurrencyNotifier() : super(availableCurrencies[0]) {
    _loadCurrency();
  }

  Future<void> _loadCurrency() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currencyCode = prefs.getString(_key);
      if (currencyCode != null) {
        final currency = availableCurrencies.firstWhere(
          (c) => c.code == currencyCode,
          orElse: () => availableCurrencies[0],
        );
        state = currency;
      }
    } catch (e) {
      debugPrint('Error loading currency: $e');
    }
  }

  Future<void> setCurrency(Currency currency) async {
    try {
      state = currency;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, currency.code);
    } catch (e) {
      debugPrint('Error saving currency: $e');
    }
  }

  String format(double amount) {
    return NumberFormat.currency(
      symbol: state.symbol,
      decimalDigits: state.code == 'JPY' ? 0 : 2,
    ).format(amount);
  }
} 
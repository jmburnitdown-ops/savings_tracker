import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class CurrencyProvider extends ChangeNotifier {
  Map<String, double> _rates = {};
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  
  // Get specific rates
  double? getRate(String currency) => _rates[currency];

  Future<void> fetchPhpRates() async {
    _isLoading = true;
    notifyListeners();
    try {
      // Fetch rates with PHP as the base currency
      final url = Uri.parse('https://api.exchangerate-api.com/v4/latest/PHP');
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final Map<String, dynamic> rates = data['rates'];
        _rates = {
          'USD': rates['USD'].toDouble(),
          'JPY': rates['JPY'].toDouble(),
          'KRW': rates['KRW'].toDouble(),
          'GBP': rates['GBP'].toDouble(),
        };
      }
    } catch (e) {
      debugPrint("Error fetching rates: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';

class CurrencyService {
  static Map<String, double>? rates;

  Future<void> fetchRates(String base) async {
    final response = await http.get(
      Uri.parse(
        'https://v6.exchangerate-api.com/v6/${Config.exchangeRateApiKey}/latest/$base',
      ),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      rates = (data['conversion_rates'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, (value as num).toDouble()),
      );
    } else {
      throw Exception('Failed to load exchange rates');
    }
  }

  double convert(double amount, String from, String to) {
    if (rates == null || !rates!.containsKey(from) || !rates!.containsKey(to)) {
      throw Exception('Exchange rates not available for $from or $to');
    }
    double fromRate = rates![from]!;
    double toRate = rates![to]!;
    return amount / fromRate * toRate;
  }
}

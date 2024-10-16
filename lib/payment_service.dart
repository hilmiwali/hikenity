//payment_service.dart
import 'dart:convert';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;

class PaymentService {
  static Future<void> makePayment(int amount) async {
    try {
      // 1. Create payment intent on the backend
      final url = Uri.parse('http://localhost:4242/create-payment-intent'); // Change to your actual backend URL when deployed
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'amount': amount}),
      );

      final paymentIntentData = jsonDecode(response.body);

      // 2. Initialize payment sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: paymentIntentData['clientSecret'],
          merchantDisplayName: 'Hikenity',
        ),
      );

      // 3. Display payment sheet
      await Stripe.instance.presentPaymentSheet();
    } catch (e) {
      throw Exception('Error making payment: $e');
    }
  }
}


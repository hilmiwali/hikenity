const functions = require('firebase-functions');
const stripe = require('stripe')('sk_test_51Q8t4GHoyDahNOUZMlYMd4BHJz2mzABpmv2SXPF9G5Q2rIrfaaPqLUBvMnPeHS0fCCw5yYykgH5aTy1h8xipVEiU00dwExeonX'); // Ensure this is the correct test key

exports.createPaymentIntent = functions.https.onRequest(async (req, res) => {
  const { amount } = req.body;

  try {
    // Ensure amount is passed correctly
    if (!amount) {
      throw new Error('Amount is required');
    }

    // Create PaymentIntent with amount and currency
    const paymentIntent = await stripe.paymentIntents.create({
      amount: amount, // Amount in cents (or smallest currency unit)
      currency: 'myr', // Adjust as needed for MYR (Malaysian Ringgit)
      payment_method_types: ['card'],
    });

    // Send the clientSecret back to the Flutter app
    res.status(200).send({
      clientSecret: paymentIntent.client_secret,
    });
  } catch (error) {
    // Log the error and send the response
    console.error('Error creating PaymentIntent:', error);
    res.status(500).send({ error: error.message });
  }
});

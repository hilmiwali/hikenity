//index.js
const functions = require('firebase-functions');
const stripe = require('stripe')('sk_test_51Q8t4GHoyDahNOUZMlYMd4BHJz2mzABpmv2SXPF9G5Q2rIrfaaPqLUBvMnPeHS0fCCw5yYykgH5aTy1h8xipVEiU00dwExeonX');

// Function to create Payment Intent
exports.createPaymentIntent = functions.https.onRequest(async (req, res) => {
  const { amount } = req.body;

  try {
    const paymentIntent = await stripe.paymentIntents.create({
      amount: amount, // Amount in cents
      currency: 'usd',
      payment_method_types: ['card'],
    });

    console.log('PaymentIntent created:', paymentIntent.id);

    res.status(200).send({
      clientSecret: paymentIntent.client_secret,
      paymentIntentId: paymentIntent.id, // Return this for later receipt retrieval
    });
  } catch (error) {
    console.error('Error creating Payment Intent:', error);
    res.status(500).send({ error: error.message });
  }
});

// Function to retrieve receipt
// Modified retrieveReceipt with fallback for missing receipt
// Updated retrieveReceipt function to handle charge retrieval
exports.retrieveReceipt = functions.https.onRequest(async (req, res) => {
  const { paymentIntentId } = req.body;
  console.log('Received PaymentIntent ID:', paymentIntentId);

  try {
    // Retrieve the PaymentIntent from Stripe
    const paymentIntent = await stripe.paymentIntents.retrieve(paymentIntentId);
    console.log('PaymentIntent Retrieved:', paymentIntent);

    // Get the latest charge ID from the PaymentIntent
    const latestChargeId = paymentIntent.latest_charge;
    console.log('Latest Charge ID:', latestChargeId);

    if (latestChargeId) {
      // Retrieve the Charge object using the Charge ID
      const charge = await stripe.charges.retrieve(latestChargeId);
      console.log('Charge Retrieved:', charge);

      // Check if the receipt URL is present in the charge
      const receiptUrl = charge.receipt_url;
      if (receiptUrl) {
        console.log('Receipt URL:', receiptUrl);
        res.status(200).send({ receiptUrl });
      } else {
        console.log('No receipt URL found in the charge');
        res.status(404).send({ error: 'No receipt available' });
      }
    } else {
      console.log('No charge found for the PaymentIntent');
      res.status(404).send({ error: 'No charge data found for this PaymentIntent' });
    }
  } catch (error) {
    console.error('Error retrieving receipt:', error);
    res.status(500).send({ error: error.message });
  }
});

//server.js
const express = require('express');
const stripe = require('stripe')('sk_test_51Q8t4GHoyDahNOUZMlYMd4BHJz2mzABpmv2SXPF9G5Q2rIrfaaPqLUBvMnPeHS0fCCw5yYykgH5aTy1h8xipVEiU00dwExeonX'); // Replace with your Stripe secret key
const bodyParser = require('body-parser');
const app = express();

app.use(bodyParser.json());

// Endpoint to create payment intent
app.post('/create-payment-intent', async (req, res) => {
  let { amount } = req.body;

  console.log("Amount received for payment intent:", amount);

  amount = amount * 100;
  try {
    // Convert amount from RM to sen by multiplying by 100
    console.log("Amount in cents:", amount); // Log the amount in sen before sending to Stripe

    // Create a PaymentIntent with the correct amount in sen
    const paymentIntent = await stripe.paymentIntents.create({
      amount: amount, // Amount in the smallest unit (sen)
      currency: 'usd', // Set currency to Malaysian Ringgit (MYR)
      payment_method_types: ['card'],
    });

    res.status(200).send({
      clientSecret: paymentIntent.client_secret,
    });
  } catch (error) {
    res.status(500).send({ error: error.message });
  }
});

// Start the server
app.listen(4242, () => console.log('Node server listening on port 4242'));

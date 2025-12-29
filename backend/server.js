//server.js
const express = require('express');
const stripe = require('stripe')('sk_test_51Q8t4GHoyDahNOUZMlYMd4BHJz2mzABpmv2SXPF9G5Q2rIrfaaPqLUBvMnPeHS0fCCw5yYykgH5aTy1h8xipVEiU00dwExeonX'); // Replace with your Stripe secret key

const app = express();
app.use(express.json());

app.post('/create-payment-intent', async (req, res) => {
  const { amount } = req.body;

  try {
    const paymentIntent = await stripe.paymentIntents.create({
      amount: amount, // Amount in the smallest currency unit (e.g., cents)
      currency: 'usd',
      payment_method_types: ['card'],
    });

    //const charge = paymentIntent.charges.data[0]; // Retrieve the first charge associated with the payment intent
    //const receiptUrl = charge ? charge.receipt_url : null; // Get the receipt URL

    res.status(200).send({
      clientSecret: paymentIntent.client_secret,
      paymentIntentId: paymentIntent.id, // Include this to retrieve the receipt later
      //receiptUrl: receiptUrl,
    });
  } catch (error) {
    res.status(500).send({ error: error.message });
  }
});

app.post('/retrieve-receipt', async (req, res) => {
  const { paymentIntentId } = req.body;

  try {
    // Step 2: Retrieve the Payment Intent after payment is confirmed
    const paymentIntent = await stripe.paymentIntents.retrieve(paymentIntentId);

    // Step 3: Access the charge and receipt URL
    if (paymentIntent.charges.data.length > 0) {
      const charge = paymentIntent.charges.data[0]; // Get the first charge (in case of multiple)
      const receiptUrl = charge.receipt_url; // Stripe provides a receipt URL

      res.status(200).send({ receiptUrl });
    } else {
      res.status(404).send({ receiptUrl: 'No receipt available' });
    }
  } catch (error) {
    res.status(500).send({ error: error.message });
  }
});

app.listen(4242, () => console.log('Server is running on port 4242'));

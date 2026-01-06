//server.js
require('dotenv').config(); // Load environment variables
const express = require('express');
const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY); // Use environment variable

const app = express();
app.use(express.json());

// Health check endpoint
app.get('/', (req, res) => {
  res.json({ 
    status: 'ok', 
    message: 'Hikenity Backend Server is running!',
    version: '1.0.0'
  });
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ status: 'healthy', timestamp: new Date().toISOString() });
});

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

const PORT = process.env.PORT || 4242;
app.listen(PORT, () => console.log(`Server is running on port ${PORT}`));

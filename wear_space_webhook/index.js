// =========================================
// Paystack Webhook Server
// =========================================
const express = require('express');
const bodyParser = require('body-parser');
const crypto = require('crypto');

const app = express();
const PORT = process.env.PORT || 3000;

// Use body-parser to parse JSON bodies
app.use(bodyParser.json());

// Replace with your Paystack secret key
const PAYSTACK_SECRET_KEY = process.env.PAYSTACK_SECRET_KEY || 'your_paystack_secret_key_here';

// Webhook route
app.post('/webhook', (req, res) => {
  const hash = crypto
    .createHmac('sha512', PAYSTACK_SECRET_KEY)
    .update(JSON.stringify(req.body))
    .digest('hex');

  // Compare signature
  const signature = req.headers['x-paystack-signature'];
  if (signature !== hash) {
    console.log('❌ Invalid signature');
    return res.status(400).send('Invalid signature');
  }

  const event = req.body;

  console.log('✅ Webhook received:', event);

  // Handle different events
  switch (event.event) {
    case 'charge.success':
      console.log(`💰 Payment successful for ${event.data.reference}`);
      // Here, update your database / wallet etc.
      break;

    case 'charge.failed':
      console.log(`❌ Payment failed for ${event.data.reference}`);
      break;

    default:
      console.log(`ℹ️ Unhandled event type: ${event.event}`);
  }

  // Respond to Paystack quickly
  res.status(200).send('Webhook received');
});

// Health check route (optional)
app.get('/healthz', (req, res) => {
  res.status(200).send('Server is up and running!');
});

// Start server
app.listen(PORT, () => {
  console.log(`🚀 Paystack Webhook Server running on port ${PORT}`);
});

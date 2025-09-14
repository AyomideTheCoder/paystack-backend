const express = require('express');
const axios = require('axios');
const dotenv = require('dotenv');
const cors = require('cors');

// Load environment variables
dotenv.config();

const app = express();
const port = process.env.PORT || 3000;

app.use(express.json());
app.use(cors()); // Allow cross-origin requests from Flutter app

// Root route for sanity check
app.get('/', (req, res) => {
  res.send('✅ Paystack backend is running!');
});

/**
 * Initialize a Paystack transaction
 * Flutter sends: { email, amount }
 * Backend returns: { authorization_url, reference }
 */
app.post('/initialize-transaction', async (req, res) => {
  const { email, amount } = req.body;

  if (!email || !amount) {
    return res.status(400).json({ success: false, error: 'Email and amount are required' });
  }

  try {
    const response = await axios.post(
      'https://api.paystack.co/transaction/initialize',
      {
        email,
        amount: amount * 100, // Paystack accepts kobo
      },
      {
        headers: {
          Authorization: `Bearer ${process.env.PAYSTACK_SECRET_KEY}`,
          'Content-Type': 'application/json',
        },
      }
    );

    res.json({
      success: true,
      authorization_url: response.data.data.authorization_url,
      reference: response.data.data.reference,
    });
  } catch (error) {
    console.error('Initialization failed:', error.response?.data || error.message);
    res.status(500).json({ success: false, error: 'Transaction initialization failed' });
  }
});

/**
 * Verify a Paystack transaction
 * Flutter sends: /verify-transaction?reference=xxxx
 */
app.get('/verify-transaction', async (req, res) => {
  const { reference } = req.query;

  if (!reference) {
    return res.status(400).json({ success: false, error: 'Reference is required' });
  }

  try {
    const response = await axios.get(`https://api.paystack.co/transaction/verify/${reference}`, {
      headers: { Authorization: `Bearer ${process.env.PAYSTACK_SECRET_KEY}` },
    });

    if (response.data.data.status === 'success') {
      res.json({
        success: true,
        amount: response.data.data.amount / 100, // Convert kobo to naira
        customer: response.data.data.customer,
      });
    } else {
      res.json({ success: false, error: 'Transaction not successful' });
    }
  } catch (error) {
    console.error('Verification failed:', error.response?.data || error.message);
    res.status(500).json({ success: false, error: 'Verification failed' });
  }
});

app.listen(port, () => {
  console.log(`🚀 Server running on port ${port}`);
});

const express = require('express');
const axios = require('axios');
const dotenv = require('dotenv');
const cors = require('cors');

// Load environment variables from .env file
dotenv.config();

const app = express();
const port = process.env.PORT || 3000;

app.use(express.json());
app.use(cors()); // Allow cross-origin requests from Flutter app

// Endpoint to verify Paystack transactions
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
      res.json({ success: true, amount: response.data.data.amount / 100 }); // Convert kobo to naira
    } else {
      res.json({ success: false, error: 'Transaction not successful' });
    }
  } catch (error) {
    console.error('Verification failed:', error.message);
    res.status(500).json({ success: false, error: 'Verification failed' });
  }
});

app.listen(port, () => {
  console.log(`Server running on port ${port}`);
});
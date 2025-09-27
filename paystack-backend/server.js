import express from "express";
import axios from "axios";
import cors from "cors";
import dotenv from "dotenv";

dotenv.config();
const app = express();

app.use(cors());
app.use(express.json());

// ================================
// ROOT CHECK
// ================================
app.get("/", (req, res) => {
  res.send("✅ Paystack backend is running!");
});

// ================================
// Initialize transaction
// ================================
app.post("/initialize-transaction", async (req, res) => {
  const { email, amount } = req.body;

  try {
    const response = await axios.post(
      "https://api.paystack.co/transaction/initialize",
      { email, amount: amount * 100 }, // Paystack expects kobo
      {
        headers: {
          Authorization: `Bearer ${process.env.PAYSTACK_SECRET_KEY}`,
        },
      }
    );

    res.json({
      success: true,
      authorization_url: response.data.data.authorization_url,
      reference: response.data.data.reference,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      status: "error",
      error: error.response?.data || error.message,
    });
  }
});

// ================================
// Verify transaction
// ================================
app.get("/verify-transaction/:reference", async (req, res) => {
  try {
    const { reference } = req.params;

    console.log("📡 Verifying transaction:", reference);

    const response = await axios.get(
      `https://api.paystack.co/transaction/verify/${reference}`,
      {
        headers: {
          Authorization: `Bearer ${process.env.PAYSTACK_SECRET_KEY}`,
          "Content-Type": "application/json",
        },
      }
    );

    const data = response.data;
    console.log("🟢 Paystack verify response:", data);

    if (data.status && data.data.status === "success") {
      res.json({
        success: true,
        status: "success",
        reference: data.data.reference,
        amount: data.data.amount / 100, // convert from kobo to naira
        customer: data.data.customer.email,
      });
    } else {
      res.json({
        success: false,
        error: data.message || "Verification failed",
      });
    }
  } catch (err) {
    console.error("❌ Verification error:", err);
    res
      .status(500)
      .json({ success: false, error: "Server error verifying transaction" });
  }
});

// ================================
// Start server
// ================================
const PORT = process.env.PORT || 10000;
app.listen(PORT, () => {
  console.log(`🚀 Server running on port ${PORT}`);
});

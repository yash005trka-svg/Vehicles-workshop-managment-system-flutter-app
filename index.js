const express = require('express');
const cors = require('cors');
const admin = require('firebase-admin');

const app = express();
app.use(cors());
app.use(express.json());

// 🔐 Firebase Admin Setup
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

// 🧾 CREATE BILL API
app.post('/create-bill', async (req, res) => {
  try {
    const bill = req.body;

    bill.createdAt = admin.firestore.FieldValue.serverTimestamp();
    bill.paid = false;

    const ref = await db.collection('bills').add(bill);

    res.json({
      success: true,
      billId: ref.id,
    });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

app.listen(3000, () => {
  console.log('🚀 API running on http://localhost:3000');
});

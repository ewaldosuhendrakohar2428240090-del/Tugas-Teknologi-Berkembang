const express = require('express');
const cors = require('cors');
require('dotenv').config();

const { checkConnection } = require('./config/db');
const orderRoutes = require('./routes/orderRoutes');
const petRoutes = require('./routes/petRoutes');
const serviceRoutes = require('./routes/serviceRoutes');
const authRoutes = require('./routes/authRoutes');
const salesRoutes = require('./routes/salesRoutes');

const app = express();
const PORT = process.env.PORT || 5000;

// Middleware
app.use(cors());
app.use(express.json());

// Root test endpoint
app.get('/', (req, res) => {
  res.json({
    status: 'ONLINE',
    message: '🐾 Pet Care Tracking API is running',
    version: '2.0.0',
    endpoints: {
      auth: '/api/auth',
      orders: '/api/orders',
      pets: '/api/pets',
      services: '/api/services',
      sales: '/api/sales'
    }
  });
});

// Routes API
app.use('/api/auth', authRoutes);
app.use('/api/orders', orderRoutes);
app.use('/api/pets', petRoutes);
app.use('/api/services', serviceRoutes);
app.use('/api/sales', salesRoutes);

// Global Error Handler
app.use((err, req, res, next) => {
  console.error('Unhandled Server Error:', err);
  res.status(500).json({ success: false, message: 'Terjadi kesalahan pada server internal' });
});

// Start Server
app.listen(PORT, async () => {
  console.log(`=======================================================`);
  console.log(`🚀 Pet Care Server aktif di: http://localhost:${PORT}`);
  console.log(`=======================================================`);
  await checkConnection();
});

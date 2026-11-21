const express = require('express');
const router = express.Router();
const salesController = require('../controllers/salesController');

// Routes
router.get('/', salesController.getAllSales);
router.get('/summary', salesController.getSalesSummary);
router.patch('/:id', salesController.updateSale);

module.exports = router;

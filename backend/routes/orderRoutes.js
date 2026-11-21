const express = require('express');
const router = express.Router();
const orderController = require('../controllers/orderController');

// Routes
router.get('/', orderController.getAllOrders);
router.get('/:id', orderController.getOrderById);
router.get('/customer/:customerId', orderController.getCustomerOrders);
router.post('/', orderController.createOrder);
router.patch('/:id/status', orderController.updateOrderStatus);
router.patch('/step/:stepId', orderController.updateTrackingStep);
router.post('/:id/on-the-way', orderController.signalOwnerOnTheWay);
router.post('/:id/verify-pickup', orderController.verifyPickup);

module.exports = router;

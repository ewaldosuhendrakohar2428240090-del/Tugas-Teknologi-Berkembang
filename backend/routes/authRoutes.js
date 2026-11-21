const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController');

// Routes
router.post('/login', authController.login);
router.get('/profile/:id', authController.getProfile);
router.get('/users', authController.getAllUsers);

module.exports = router;

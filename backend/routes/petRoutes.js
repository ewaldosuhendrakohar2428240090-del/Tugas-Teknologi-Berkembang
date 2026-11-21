const express = require('express');
const router = express.Router();
const petController = require('../controllers/petController');

router.get('/user/:userId', petController.getPetsByUser);
router.post('/', petController.addPet);

module.exports = router;

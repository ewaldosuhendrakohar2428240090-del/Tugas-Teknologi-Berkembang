const { pool } = require('../config/db');

exports.getPetsByUser = async (req, res) => {
  try {
    const { userId } = req.params;
    const [pets] = await pool.query(
      'SELECT * FROM pets WHERE user_id = ? ORDER BY created_at DESC',
      [userId]
    );
    res.json({ success: true, count: pets.length, data: pets });
  } catch (error) {
    console.error('Error fetching pets:', error);
    res.status(500).json({ success: false, message: error.message });
  }
};

exports.addPet = async (req, res) => {
  try {
    const { userId, name, species, breed, gender, ageYears, weightKg, photoUrl, specialNotes } = req.body;
    const [result] = await pool.query(`
      INSERT INTO pets (user_id, name, species, breed, gender, age_years, weight_kg, photo_url, special_notes)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    `, [userId, name, species || 'Kucing', breed, gender || 'Jantan', ageYears || 1, weightKg || 3.0, photoUrl, specialNotes]);

    res.status(201).json({
      success: true,
      message: 'Hewan peliharaan berhasil ditambahkan!',
      petId: result.insertId
    });
  } catch (error) {
    console.error('Error adding pet:', error);
    res.status(500).json({ success: false, message: error.message });
  }
};

const { pool } = require('../config/db');

exports.getAllServices = async (req, res) => {
  try {
    const { category } = req.query;
    let query = 'SELECT * FROM services';
    const params = [];

    if (category) {
      query += ' WHERE category = ?';
      params.push(category);
    }
    query += ' ORDER BY id ASC';

    const [services] = await pool.query(query, params);
    res.json({ success: true, count: services.length, data: services });
  } catch (error) {
    console.error('Error fetching services:', error);
    res.status(500).json({ success: false, message: error.message });
  }
};

const { pool } = require('../config/db');

// 1. Ambil semua penjualan (orders PICKED_UP) - untuk Owner Dashboard
exports.getAllSales = async (req, res) => {
  try {
    const { startDate, endDate, category } = req.query;

    let query = `
      SELECT 
        o.id,
        o.order_code,
        o.customer_id,
        o.pet_id,
        o.service_id,
        o.status,
        o.notes,
        o.total_price,
        o.check_in_time,
        o.picked_up_at,
        o.created_at,
        u.name AS customer_name,
        u.phone AS customer_phone,
        p.name AS pet_name,
        p.species AS pet_species,
        s.name AS service_name,
        s.category AS service_category,
        s.base_price AS original_price
      FROM orders o
      JOIN users u ON o.customer_id = u.id
      JOIN pets p ON o.pet_id = p.id
      JOIN services s ON o.service_id = s.id
      WHERE o.status = 'PICKED_UP'
    `;
    const params = [];

    if (startDate) {
      query += ` AND DATE(o.picked_up_at) >= ?`;
      params.push(startDate);
    }
    if (endDate) {
      query += ` AND DATE(o.picked_up_at) <= ?`;
      params.push(endDate);
    }
    if (category) {
      query += ` AND s.category = ?`;
      params.push(category);
    }

    query += ` ORDER BY o.picked_up_at DESC`;

    const [rows] = await pool.query(query, params);

    // Hitung total pendapatan
    const totalRevenue = rows.reduce((sum, r) => sum + parseFloat(r.total_price), 0);

    res.json({
      success: true,
      count: rows.length,
      totalRevenue,
      data: rows
    });
  } catch (error) {
    console.error('Error fetching sales:', error);
    res.status(500).json({ success: false, message: error.message });
  }
};

// 2. Update data penjualan (Owner mengubah total_price dan notes)
exports.updateSale = async (req, res) => {
  try {
    const { id } = req.params;
    const { totalPrice, notes } = req.body;

    // Pastikan order ada dan sudah PICKED_UP
    const [orderRows] = await pool.query(
      'SELECT * FROM orders WHERE id = ? AND status = ?',
      [id, 'PICKED_UP']
    );

    if (orderRows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'Data penjualan tidak ditemukan atau belum berstatus PICKED_UP'
      });
    }

    const updateFields = [];
    const updateParams = [];

    if (totalPrice !== undefined && totalPrice !== null) {
      updateFields.push('total_price = ?');
      updateParams.push(parseFloat(totalPrice));
    }
    if (notes !== undefined) {
      updateFields.push('notes = ?');
      updateParams.push(notes);
    }

    if (updateFields.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Tidak ada data yang diubah. Kirim totalPrice dan/atau notes.'
      });
    }

    updateParams.push(id);

    await pool.query(
      `UPDATE orders SET ${updateFields.join(', ')} WHERE id = ?`,
      updateParams
    );

    // Ambil data terbaru setelah update
    const [updatedRows] = await pool.query(`
      SELECT 
        o.*,
        u.name AS customer_name,
        p.name AS pet_name,
        s.name AS service_name,
        s.category AS service_category
      FROM orders o
      JOIN users u ON o.customer_id = u.id
      JOIN pets p ON o.pet_id = p.id
      JOIN services s ON o.service_id = s.id
      WHERE o.id = ?
    `, [id]);

    res.json({
      success: true,
      message: 'Data penjualan berhasil diperbarui',
      data: updatedRows[0]
    });
  } catch (error) {
    console.error('Error updating sale:', error);
    res.status(500).json({ success: false, message: error.message });
  }
};

// 3. Ringkasan penjualan (summary) untuk Owner Dashboard
exports.getSalesSummary = async (req, res) => {
  try {
    // Total pendapatan hari ini
    const [todayRows] = await pool.query(`
      SELECT COALESCE(SUM(total_price), 0) AS total_today, COUNT(*) AS count_today
      FROM orders
      WHERE status = 'PICKED_UP' AND DATE(picked_up_at) = CURDATE()
    `);

    // Total pendapatan bulan ini
    const [monthRows] = await pool.query(`
      SELECT COALESCE(SUM(total_price), 0) AS total_month, COUNT(*) AS count_month
      FROM orders
      WHERE status = 'PICKED_UP' 
        AND MONTH(picked_up_at) = MONTH(CURDATE()) 
        AND YEAR(picked_up_at) = YEAR(CURDATE())
    `);

    // Total keseluruhan
    const [allRows] = await pool.query(`
      SELECT COALESCE(SUM(total_price), 0) AS total_all, COUNT(*) AS count_all
      FROM orders
      WHERE status = 'PICKED_UP'
    `);

    // Per kategori
    const [categoryRows] = await pool.query(`
      SELECT 
        s.category,
        COUNT(*) AS total_orders,
        COALESCE(SUM(o.total_price), 0) AS total_revenue
      FROM orders o
      JOIN services s ON o.service_id = s.id
      WHERE o.status = 'PICKED_UP'
      GROUP BY s.category
      ORDER BY total_revenue DESC
    `);

    res.json({
      success: true,
      data: {
        today: todayRows[0],
        thisMonth: monthRows[0],
        allTime: allRows[0],
        byCategory: categoryRows
      }
    });
  } catch (error) {
    console.error('Error fetching sales summary:', error);
    res.status(500).json({ success: false, message: error.message });
  }
};

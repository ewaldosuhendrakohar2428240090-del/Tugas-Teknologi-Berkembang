const { pool } = require('../config/db');

// 1. Ambil semua pesanan (Untuk Dashboard Staf)
exports.getAllOrders = async (req, res) => {
  try {
    const { status, category } = req.query;
    let query = `
      SELECT 
        o.*,
        u.name AS customer_name,
        u.phone AS customer_phone,
        p.name AS pet_name,
        p.species AS pet_species,
        p.breed AS pet_breed,
        p.photo_url AS pet_photo,
        s.name AS service_name,
        s.category AS service_category,
        s.base_price,
        TIMESTAMPDIFF(MINUTE, o.ready_at, NOW()) AS minutes_since_ready
      FROM orders o
      JOIN users u ON o.customer_id = u.id
      JOIN pets p ON o.pet_id = p.id
      JOIN services s ON o.service_id = s.id
      WHERE 1=1
    `;
    const params = [];

    if (status) {
      query += ` AND o.status = ?`;
      params.push(status);
    }
    if (category) {
      query += ` AND s.category = ?`;
      params.push(category);
    }

    query += ` ORDER BY o.created_at DESC`;

    const [rows] = await pool.query(query, params);
    res.json({ success: true, count: rows.length, data: rows });
  } catch (error) {
    console.error('Error fetching orders:', error);
    res.status(500).json({ success: false, message: error.message });
  }
};

// 2. Ambil detail pesanan beserta tracking steps & foto
exports.getOrderById = async (req, res) => {
  try {
    const { id } = req.params;

    const [orderRows] = await pool.query(`
      SELECT 
        o.*,
        u.name AS customer_name,
        u.phone AS customer_phone,
        p.name AS pet_name,
        p.species AS pet_species,
        p.breed AS pet_breed,
        p.photo_url AS pet_photo,
        p.special_notes AS pet_notes,
        s.name AS service_name,
        s.category AS service_category,
        TIMESTAMPDIFF(MINUTE, o.ready_at, NOW()) AS minutes_since_ready
      FROM orders o
      JOIN users u ON o.customer_id = u.id
      JOIN pets p ON o.pet_id = p.id
      JOIN services s ON o.service_id = s.id
      WHERE o.id = ?
    `, [id]);

    if (orderRows.length === 0) {
      return res.status(404).json({ success: false, message: 'Pesanan tidak ditemukan' });
    }

    const order = orderRows[0];

    // Ambil timeline steps
    const [steps] = await pool.query(`
      SELECT * FROM order_tracking_steps 
      WHERE order_id = ? 
      ORDER BY step_number ASC
    `, [id]);

    order.tracking_steps = steps;

    res.json({ success: true, data: order });
  } catch (error) {
    console.error('Error fetching order detail:', error);
    res.status(500).json({ success: false, message: error.message });
  }
};

// 3. Ambil pesanan milik Customer tertentu
exports.getCustomerOrders = async (req, res) => {
  try {
    const { customerId } = req.params;

    const [rows] = await pool.query(`
      SELECT 
        o.*,
        p.name AS pet_name,
        p.species AS pet_species,
        p.breed AS pet_breed,
        p.photo_url AS pet_photo,
        s.name AS service_name,
        s.category AS service_category,
        TIMESTAMPDIFF(MINUTE, o.ready_at, NOW()) AS minutes_since_ready
      FROM orders o
      JOIN pets p ON o.pet_id = p.id
      JOIN services s ON o.service_id = s.id
      WHERE o.customer_id = ?
      ORDER BY o.created_at DESC
    `, [customerId]);

    res.json({ success: true, count: rows.length, data: rows });
  } catch (error) {
    console.error('Error fetching customer orders:', error);
    res.status(500).json({ success: false, message: error.message });
  }
};

// 4. Buat Reservasi / Pesanan Baru (Grooming, Steril, Pet Hotel)
exports.createOrder = async (req, res) => {
  const connection = await pool.getConnection();
  try {
    await connection.beginTransaction();

    const {
      customerId,
      petId,
      serviceId,
      notes,
      totalPrice
    } = req.body;

    const orderCode = 'ORD-' + Date.now().toString().slice(-6);
    const pickupPin = Math.floor(100000 + Math.random() * 900000).toString(); // 6 digit PIN

    // Insert order
    const [orderResult] = await connection.query(`
      INSERT INTO orders (order_code, customer_id, pet_id, service_id, status, pickup_pin, notes, total_price, check_in_time)
      VALUES (?, ?, ?, ?, 'BOOKED', ?, ?, ?, NOW())
    `, [orderCode, customerId, petId, serviceId, pickupPin, notes || '', totalPrice]);

    const orderId = orderResult.insertId;

    // Ambil info service untuk membuat langkah-langkah template otomatis
    const [serviceRows] = await connection.query('SELECT * FROM services WHERE id = ?', [serviceId]);
    const service = serviceRows[0];

    let steps = [];
    if (service && service.category === 'Grooming') {
      steps = [
        { num: 1, title: 'Check-in & Pemeriksaan Fisik', desc: 'Pengecekan kutu, jamur, kuku & telinga' },
        { num: 2, title: 'Mandi Spa & Shampoo Khusus', desc: 'Pembersihan bulu dengan air hangat dan shampoo ramah kulit' },
        { num: 3, title: 'Pengeringan & Blower Higienis', desc: 'Bulu dikeringkan menyeluruh sampai lapisan kulit' },
        { num: 4, title: 'Styling, Potong Kuku & Parfum', desc: 'Perapihan bulu dan wewangian premium' },
        { num: 5, title: 'Siap Dijemput!', desc: 'Hewan sudah bersih wangi dan siap dijemput di kandang tunggu' }
      ];
    } else if (service && service.category === 'Steril') {
      steps = [
        { num: 1, title: 'Pemeriksaan Pra-Operasi & Timbang', desc: 'Pengecekan suhu, jantung, dan status puasa hewan' },
        { num: 2, title: 'Tindakan Operasi Sterilisasi', desc: 'Tindakan bedah aseptik oleh Dokter Hewan' },
        { num: 3, title: 'Pemulihan & Observasi Anestesi', desc: 'Pemantauan di ruang hangat hingga hewan sadar penuh' },
        { num: 4, title: 'Edukasi Pasca-Operasi & Obat', desc: 'Pemberian antibiotik dan resep pemulihan' },
        { num: 5, title: 'Siap Dijemput Pemilik!', desc: 'Kondisi stabil, siuman aman untuk dibawa pulang' }
      ];
    } else {
      // Pet Hotel
      steps = [
        { num: 1, title: 'Check-in Kamar & Timbang', desc: 'Hewan masuk ke kamar individual ber-AC' },
        { num: 2, title: 'Jadwal Makan & Pemantauan', desc: 'Pemberian pakan sesuai jadwal pemilik' },
        { num: 3, title: 'Sesi Bermain & Olahraga', desc: 'Aktivitas santai di play area' },
        { num: 4, title: 'Pemeriksaan Akhir & Rapikan Barang', desc: 'Pemeriksaan kondisi fisik sebelum check-out' },
        { num: 5, title: 'Siap Dijemput!', desc: 'Hewan dan barang bawaan siap diserahkan' }
      ];
    }

    for (const step of steps) {
      await connection.query(`
        INSERT INTO order_tracking_steps (order_id, step_number, title, description, status)
        VALUES (?, ?, ?, ?, ?)
      `, [orderId, step.num, step.title, step.desc, step.num === 1 ? 'IN_PROGRESS' : 'PENDING']);
    }

    await connection.commit();

    res.status(201).json({
      success: true,
      message: 'Pesanan berhasil dibuat!',
      orderId,
      orderCode,
      pickupPin
    });
  } catch (error) {
    await connection.rollback();
    console.error('Error creating order:', error);
    res.status(500).json({ success: false, message: error.message });
  } finally {
    connection.release();
  }
};

// 5. Update Status Pesanan oleh Staf (Groomer / Dokter Hewan)
// FITUR KUNCI: Saat status diubah ke READY_FOR_PICKUP, notifikasi langsung terpicu
exports.updateOrderStatus = async (req, res) => {
  const connection = await pool.getConnection();
  try {
    await connection.beginTransaction();

    const { id } = req.params;
    const { status, holdingCageNumber, notes } = req.body;

    // Ambil order saat ini
    const [orders] = await connection.query(`
      SELECT o.*, u.id AS user_id, u.name AS customer_name, p.name AS pet_name, s.name AS service_name
      FROM orders o
      JOIN users u ON o.customer_id = u.id
      JOIN pets p ON o.pet_id = p.id
      JOIN services s ON o.service_id = s.id
      WHERE o.id = ?
    `, [id]);

    if (orders.length === 0) {
      return res.status(404).json({ success: false, message: 'Pesanan tidak ditemukan' });
    }

    const order = orders[0];
    let readyAtUpdate = '';
    let pickedUpAtUpdate = '';

    if (status === 'READY_FOR_PICKUP') {
      readyAtUpdate = ', ready_at = NOW()';
      // Buat Notifikasi Khusus ke Pemilik Hewan
      const notifTitle = `🎉 ${order.pet_name} Sudah Siap Dijemput!`;
      const notifMsg = `Layanan ${order.service_name} untuk ${order.pet_name} telah selesai. Silakan jemput di ${holdingCageNumber || 'Kandang Tunggu Pet Shop'} dengan menunjukkan Kode PIN: ${order.pickup_pin}.`;

      await connection.query(`
        INSERT INTO notifications (user_id, order_id, type, title, message)
        VALUES (?, ?, 'READY_PICKUP', ?, ?)
      `, [order.user_id, id, notifTitle, notifMsg]);
    } else if (status === 'PICKED_UP') {
      pickedUpAtUpdate = ', picked_up_at = NOW()';
      const notifTitle = `❤️ Terima Kasih Telah Mempercayakan ${order.pet_name}`;
      const notifMsg = `${order.pet_name} telah berhasil diserahkan kepada Anda. Sampai jumpa di layanan berikutnya!`;

      await connection.query(`
        INSERT INTO notifications (user_id, order_id, type, title, message)
        VALUES (?, ?, 'PICKED_UP', ?, ?)
      `, [order.user_id, id, notifTitle, notifMsg]);
    }

    // Update orders table
    await connection.query(`
      UPDATE orders 
      SET status = ?, 
          holding_cage_number = COALESCE(?, holding_cage_number),
          notes = COALESCE(?, notes)
          ${readyAtUpdate}
          ${pickedUpAtUpdate}
      WHERE id = ?
    `, [status, holdingCageNumber || null, notes || null, id]);

    // Jika READY_FOR_PICKUP, set semua step tracking jadi COMPLETED
    if (status === 'READY_FOR_PICKUP') {
      await connection.query(`
        UPDATE order_tracking_steps
        SET status = 'COMPLETED', completed_at = NOW()
        WHERE order_id = ?
      `, [id]);
    }

    await connection.commit();

    res.json({
      success: true,
      message: `Status pesanan berhasil diperbarui ke ${status}`,
      status
    });
  } catch (error) {
    await connection.rollback();
    console.error('Error updating status:', error);
    res.status(500).json({ success: false, message: error.message });
  } finally {
    connection.release();
  }
};

// 6. Update Langkah Individual Tracking & Unggah Foto Progres
exports.updateTrackingStep = async (req, res) => {
  try {
    const { stepId } = req.params;
    const { status, photoUrl, staffNotes } = req.body;

    await pool.query(`
      UPDATE order_tracking_steps
      SET status = ?,
          photo_url = COALESCE(?, photo_url),
          staff_notes = COALESCE(?, staff_notes),
          completed_at = CASE WHEN ? = 'COMPLETED' THEN NOW() ELSE completed_at END
      WHERE id = ?
    `, [status, photoUrl || null, staffNotes || null, status, stepId]);

    res.json({ success: true, message: 'Langkah tracking berhasil diperbarui!' });
  } catch (error) {
    console.error('Error updating step:', error);
    res.status(500).json({ success: false, message: error.message });
  }
};

// 7. Pemilik Menekan Tombol "Saya Sedang Menuju ke Petshop"
exports.signalOwnerOnTheWay = async (req, res) => {
  try {
    const { id } = req.params;
    const { etaMinutes } = req.body;

    await pool.query(`
      UPDATE orders
      SET is_owner_on_the_way = TRUE,
          owner_eta_minutes = ?
      WHERE id = ?
    `, [etaMinutes || 15, id]);

    res.json({
      success: true,
      message: 'Pemberitahuan telah dikirim ke staf petshop! Staf sedang menyiapkan hewan Anda.'
    });
  } catch (error) {
    console.error('Error signaling on the way:', error);
    res.status(500).json({ success: false, message: error.message });
  }
};

// 8. Verifikasi Penjemputan Hewan Menggunakan PIN / QR di Kasir
exports.verifyPickup = async (req, res) => {
  try {
    const { id } = req.params;
    const { pin } = req.body;

    const [rows] = await pool.query('SELECT * FROM orders WHERE id = ?', [id]);
    if (rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Pesanan tidak ditemukan' });
    }

    const order = rows[0];
    if (order.pickup_pin !== pin) {
      return res.status(400).json({ success: false, message: 'PIN Penjemputan salah. Silakan periksa di aplikasi pemilik.' });
    }

    await pool.query(`
      UPDATE orders 
      SET status = 'PICKED_UP', picked_up_at = NOW() 
      WHERE id = ?
    `, [id]);

    res.json({
      success: true,
      message: 'Verifikasi penjemputan berhasil! Hewan telah diserahterimakan.'
    });
  } catch (error) {
    console.error('Error verifying pickup:', error);
    res.status(500).json({ success: false, message: error.message });
  }
};

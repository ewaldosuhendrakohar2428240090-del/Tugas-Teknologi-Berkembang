-- =====================================================================
-- DATABASE: pet_care_db
-- Deskripsi: Database Sistem Manajemen & Pelacakan Penjemputan Pet Shop
-- Layanan: Grooming, Sterilisasi, Pet Hotel
-- Fokus Utama: Menghilangkan Keterlambatan Penjemputan dengan Live Tracking
-- =====================================================================

CREATE DATABASE IF NOT EXISTS `pet_care_db` 
CHARACTER SET utf8mb4 
COLLATE utf8mb4_unicode_ci;

USE `pet_care_db`;

-- ---------------------------------------------------------------------
-- 1. TABEL USERS (Pemilik Hewan & Staf Petshop)
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `users` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `name` VARCHAR(100) NOT NULL,
    `email` VARCHAR(100) NOT NULL UNIQUE,
    `password` VARCHAR(255) NOT NULL,
    `phone` VARCHAR(20) NOT NULL,
    `role` ENUM('customer', 'staff', 'admin') NOT NULL DEFAULT 'customer',
    `fcm_token` VARCHAR(255) NULL COMMENT 'Token Push Notification Firebase',
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 2. TABEL PETS (Data Peliharaan Milik Customer)
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `pets` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `user_id` INT NOT NULL,
    `name` VARCHAR(100) NOT NULL,
    `species` ENUM('Kucing', 'Anjing', 'Kelinci', 'Lainnya') NOT NULL DEFAULT 'Kucing',
    `breed` VARCHAR(100) NULL COMMENT 'Ras / Jenis Hewan',
    `gender` ENUM('Jantan', 'Betina') NOT NULL,
    `age_years` INT DEFAULT 1,
    `weight_kg` DECIMAL(4,2) DEFAULT 3.5,
    `photo_url` TEXT NULL,
    `special_notes` TEXT NULL COMMENT 'Alergi, sifat agresif/penakut, dll.',
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT `fk_pets_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 3. TABEL SERVICES (Katalog Jasa: Grooming, Steril, Pet Hotel)
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `services` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `code` VARCHAR(50) NOT NULL UNIQUE,
    `name` VARCHAR(100) NOT NULL,
    `category` ENUM('Grooming', 'Steril', 'Pet Hotel') NOT NULL,
    `description` TEXT NOT NULL,
    `base_price` DECIMAL(10,2) NOT NULL,
    `estimated_duration_min` INT NOT NULL COMMENT 'Estimasi durasi pengerjaan dalam menit',
    `icon_name` VARCHAR(50) DEFAULT 'pets',
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 4. TABEL ORDERS (Transaksi Layanan & Status Penjemputan)
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `orders` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `order_code` VARCHAR(30) NOT NULL UNIQUE,
    `customer_id` INT NOT NULL,
    `pet_id` INT NOT NULL,
    `service_id` INT NOT NULL,
    `status` ENUM(
        'BOOKED',            -- Telah dipesan / terjadwal
        'CHECKED_IN',         -- Hewan sudah diantar ke pet shop
        'IN_PROGRESS',        -- Sedang ditangani (Mandi / Operasi / Hotel)
        'POST_CARE',          -- Pengeringan bulu / Pemulihan anestesi steril
        'READY_FOR_PICKUP',   -- SELESAI & SIAP DIJEMPUT (Notif dikirim)
        'PICKED_UP',          -- Hewan telah diambil pemilik
        'CANCELLED'           -- Dibatalkan
    ) NOT NULL DEFAULT 'BOOKED',
    `holding_cage_number` VARCHAR(30) NULL COMMENT 'Nomor Kandang / Bay Tunggu (misal: Kandang A-03)',
    `pickup_pin` VARCHAR(6) NOT NULL COMMENT 'PIN 6 Digit Verifikasi Penjemputan',
    `notes` TEXT NULL,
    `total_price` DECIMAL(10,2) NOT NULL,
    `check_in_time` DATETIME NULL,
    `estimated_completion_time` DATETIME NULL,
    `ready_at` DATETIME NULL COMMENT 'Timestamp saat status berubah ke READY_FOR_PICKUP',
    `picked_up_at` DATETIME NULL COMMENT 'Timestamp saat hewan diserahterimakan',
    `is_owner_on_the_way` BOOLEAN DEFAULT FALSE COMMENT 'Pemilik menekan tombol Saya Sedang Menuju ke Toko',
    `owner_eta_minutes` INT NULL COMMENT 'Estimasi menit pemilik sampai',
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT `fk_orders_customer` FOREIGN KEY (`customer_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_orders_pet` FOREIGN KEY (`pet_id`) REFERENCES `pets` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_orders_service` FOREIGN KEY (`service_id`) REFERENCES `services` (`id`)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 5. TABEL ORDER_TRACKING_STEPS (Timeline Step-by-Step Transparan)
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `order_tracking_steps` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `order_id` INT NOT NULL,
    `step_number` INT NOT NULL,
    `title` VARCHAR(100) NOT NULL,
    `description` TEXT NULL,
    `status` ENUM('PENDING', 'IN_PROGRESS', 'COMPLETED') NOT NULL DEFAULT 'PENDING',
    `photo_url` TEXT NULL COMMENT 'Foto bukti kondisi hewan yang diambil staf',
    `completed_at` DATETIME NULL,
    `staff_notes` TEXT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT `fk_tracking_order` FOREIGN KEY (`order_id`) REFERENCES `orders` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 6. TABEL NOTIFICATIONS (Riwayat Notifikasi ke Pemilik)
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `notifications` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `user_id` INT NOT NULL,
    `order_id` INT NULL,
    `type` ENUM('INFO', 'PROGRESS', 'READY_PICKUP', 'OVERDUE_ALERT', 'PICKED_UP') NOT NULL DEFAULT 'INFO',
    `title` VARCHAR(150) NOT NULL,
    `message` TEXT NOT NULL,
    `is_read` BOOLEAN DEFAULT FALSE,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT `fk_notifications_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
    CONSTRAINT `fk_notifications_order` FOREIGN KEY (`order_id`) REFERENCES `orders` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB;

-- =====================================================================
-- DUMMY / INITIAL SEED DATA
-- =====================================================================

-- Masukkan Pengguna Contoh (Customer & Staf Petshop)
INSERT INTO `users` (`id`, `name`, `email`, `password`, `phone`, `role`) VALUES
(1, 'Budi Santoso', 'budi@gmail.com', 'password123', '081234567890', 'customer'),
(2, 'Siti Rahma', 'siti@gmail.com', 'password123', '081298765432', 'customer'),
(3, 'Dr. Vet Dian (Staf)', 'staf@petshop.com', 'password123', '081122334455', 'staff');

-- Masukkan Hewan Peliharaan Contoh
INSERT INTO `pets` (`id`, `user_id`, `name`, `species`, `breed`, `gender`, `age_years`, `weight_kg`, `photo_url`, `special_notes`) VALUES
(1, 1, 'Milo', 'Kucing', 'British Shorthair', 'Jantan', 2, 4.20, 'https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba?w=600', 'Agak takut hair dryer, mohon dikeringkan pelan-pelan.'),
(2, 1, 'Rocky', 'Anjing', 'Golden Retriever', 'Jantan', 3, 28.50, 'https://images.unsplash.com/photo-1552053831-71594a27632d?w=600', 'Sangat ramah dan aktif, suka bermain air.'),
(3, 2, 'Luna', 'Kucing', 'Persia Peaknose', 'Betina', 1, 3.10, 'https://images.unsplash.com/photo-1573865526739-10659fec78a5?w=600', 'Persiapan steril betina, sudah puasa 8 jam.');

-- Masukkan Katalog Layanan (Grooming, Steril, Pet Hotel)
INSERT INTO `services` (`id`, `code`, `name`, `category`, `description`, `base_price`, `estimated_duration_min`, `icon_name`) VALUES
(1, 'GROOM-FULL', 'Full Grooming Premium', 'Grooming', 'Mandi shampoo antikutu & jamur, blow dry, gunting kuku, pembersihan telinga & styling bulu.', 120000.00, 120, 'cut'),
(2, 'GROOM-BASIC', 'Basic Bath & Dry', 'Grooming', 'Mandi wangi, pembersihan ringan, dan pengeringan higienis.', 75000.00, 60, 'shower'),
(3, 'STERIL-CAT-M', 'Sterilisasi Kucing Jantan (Kastrasi)', 'Steril', 'Operasi kastrasi profesional oleh dokter hewan + pemulihan anestesi dan obat pasca operasi.', 350000.00, 180, 'medical_services'),
(4, 'STERIL-CAT-F', 'Sterilisasi Kucing Betina (OH)', 'Steril', 'Operasi pengangkatan rahim/ovariohisterektomi + pemantauan ketat masa siuman anestesi.', 550000.00, 240, 'medical_services'),
(5, 'HOTEL-DELUXE', 'Pet Hotel Deluxe (Per Malam)', 'Pet Hotel', 'Ruangan AC individual, makan 3x sehari, playtime 2x, monitoring CCTV & update foto harian.', 85000.00, 1440, 'hotel');

-- Masukkan Contoh Pesanan yang sedang berlangsung:
-- ORDER 1: Milo sedang Grooming dan SUDAH SIAP DIJEMPUT (Keterlambatan diatasi dengan live alert)
INSERT INTO `orders` (`id`, `order_code`, `customer_id`, `pet_id`, `service_id`, `status`, `holding_cage_number`, `pickup_pin`, `notes`, `total_price`, `check_in_time`, `estimated_completion_time`, `ready_at`, `picked_up_at`) VALUES
(1, 'ORD-2026-001', 1, 1, 1, 'READY_FOR_PICKUP', 'Kandang A-02 (Area Siap Jemput)', '482910', 'Model potongan bulu bulat di kepala.', 120000.00, NOW() - INTERVAL 150 MINUTE, NOW() - INTERVAL 20 MINUTE, NOW() - INTERVAL 20 MINUTE, NULL);

-- Langkah-langkah Tracking untuk Milo (Full Grooming)
INSERT INTO `order_tracking_steps` (`order_id`, `step_number`, `title`, `description`, `status`, `photo_url`, `completed_at`, `staff_notes`) VALUES
(1, 1, 'Check-in & Pemeriksaan Fisik', 'Kondisi kulit bersih, kuku siap dipotong, tidak ada luka.', 'COMPLETED', 'https://images.unsplash.com/photo-1548767797-d8c844163c4c?w=600', NOW() - INTERVAL 140 MINUTE, 'Milo tenang saat pemeriksaan.'),
(1, 2, 'Mandi Spa & Shampoo Premium', 'Menggunakan shampoo chamomile untuk kulit sensitif.', 'COMPLETED', 'https://images.unsplash.com/photo-1516734212186-a967f81ad0d7?w=600', NOW() - INTERVAL 90 MINUTE, 'Bulu dibilas bersih tanpa residu.'),
(1, 3, 'Pengeringan & Blow Dry', 'Bulu dikeringkan sempurna dengan suhu hangat dan pelindung telinga.', 'COMPLETED', NULL, NOW() - INTERVAL 50 MINUTE, 'Bulu sudah 100% kering dan mengembang.'),
(1, 4, 'Styling, Potong Kuku & Parfum', 'Gunting kuku rapi, bulu diratakan, wangi baby powder.', 'COMPLETED', 'https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba?w=600', NOW() - INTERVAL 20 MINUTE, 'Selesai sempurna dan rapi.'),
(1, 5, 'Siap Dijemput di Pet Shop!', 'Milo sudah berada di Kandang A-02 ber-AC dan siap dipeluk pulang.', 'COMPLETED', NULL, NOW() - INTERVAL 20 MINUTE, 'Tolong jemput dengan membawa kode PIN / QR.');

-- ORDER 2: Luna sedang Sterilisasi (Sedang dalam masa pemulihan anestesi / post-care)
INSERT INTO `orders` (`id`, `order_code`, `customer_id`, `pet_id`, `service_id`, `status`, `holding_cage_number`, `pickup_pin`, `notes`, `total_price`, `check_in_time`, `estimated_completion_time`, `ready_at`, `picked_up_at`) VALUES
(2, 'ORD-2026-002', 2, 3, 4, 'POST_CARE', 'Ruang Rawat Inap Steril B-01', '739104', 'Kucing betina, sudah puasa 8 jam.', 550000.00, NOW() - INTERVAL 180 MINUTE, NOW() + INTERVAL 45 MINUTE, NULL, NULL);

-- Langkah-langkah Tracking untuk Luna (Sterilisasi)
INSERT INTO `order_tracking_steps` (`order_id`, `step_number`, `title`, `description`, `status`, `photo_url`, `completed_at`, `staff_notes`) VALUES
(2, 1, 'Pemeriksaan Pra-Operasi & Timbang', 'Suhu tubuh 38.3°C normal, detak jantung stabil, berat 3.1 kg.', 'COMPLETED', NULL, NOW() - INTERVAL 170 MINUTE, 'Disetujui untuk tindakan bedah.'),
(2, 2, 'Tindakan Operasi Sterilisasi (OH)', 'Prosedur bedah ovariohisterektomi oleh Dr. Vet Dian.', 'COMPLETED', NULL, NOW() - INTERVAL 60 MINUTE, 'Operasi lancar, jahitan intradermal rapi.'),
(2, 3, 'Pemulihan & Observasi Pasca-Anestesi', 'Hewan ditempatkan di inkubator hangat dengan pantauan pernapasan.', 'IN_PROGRESS', 'https://images.unsplash.com/photo-1573865526739-10659fec78a5?w=600', NULL, 'Sudah mulai mengangkat kepala, refleks kornea aktif.'),
(2, 4, 'Pemberian Obat & Edukasi Pasca Operasi', 'Pemberian antibiotik oral & persiapan cone kerah leher.', 'PENDING', NULL, NULL, 'Menunggu pasien pulih 100%.'),
(2, 5, 'Siap Dijemput Pemilik', 'Kucing telah sadar penuh, stabil, dan siap pulang dengan aman.', 'PENDING', NULL, NULL, NULL);

-- Notifikasi Awal
INSERT INTO `notifications` (`user_id`, `order_id`, `type`, `title`, `message`, `is_read`) VALUES
(1, 1, 'READY_PICKUP', '🎉 Milo Sudah Selesai Grooming!', 'Halo Budi, Milo sudah selesai dan sangat wangi! Silakan datang menjemput ke pet shop di Kandang A-02.', FALSE),
(2, 2, 'PROGRESS', 'Operasi Luna Selesai dengan Lancar', 'Luna saat ini berada di ruang observasi dan sedang dalam masa pemulihan anestesi yang stabil.', FALSE);

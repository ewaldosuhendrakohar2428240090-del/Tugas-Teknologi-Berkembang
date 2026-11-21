-- =====================================================================
-- UPDATE: Menambah Role 'owner' dan Data Seed Owner
-- Jalankan setelah pet_care_db.sql
-- =====================================================================

USE `pet_care_db`;

-- Ubah ENUM role untuk menambah 'owner'
ALTER TABLE `users` 
MODIFY COLUMN `role` ENUM('customer', 'staff', 'admin', 'owner') NOT NULL DEFAULT 'customer';

-- Tambah user admin dan owner
INSERT INTO `users` (`id`, `name`, `email`, `password`, `phone`, `role`) VALUES
(4, 'Admin HappyPaws', 'admin@petshop.com', 'password123', '081100001111', 'admin'),
(5, 'Pak Joko (Owner)', 'owner@petshop.com', 'password123', '081200002222', 'owner')
ON DUPLICATE KEY UPDATE `role` = VALUES(`role`);

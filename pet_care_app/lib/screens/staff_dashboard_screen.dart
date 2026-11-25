import 'package:flutter/material.dart';
import '../models/order_model.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'tracking_detail_screen.dart';

class StaffDashboardScreen extends StatefulWidget {
  final VoidCallback onSwitchToCustomer;

  const StaffDashboardScreen({super.key, required this.onSwitchToCustomer});

  @override
  State<StaffDashboardScreen> createState() => _StaffDashboardScreenState();
}

class _StaffDashboardScreenState extends State<StaffDashboardScreen> {
  List<OrderModel> _orders = [];
  bool _isLoading = true;
  String _selectedFilter = 'ALL'; // 'ALL', 'IN_PROGRESS', 'READY', 'DELAYED'

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    final orders = await ApiService.fetchOrders();
    if (mounted) {
      setState(() {
        _orders = orders;
        _isLoading = false;
      });
    }
  }

  Future<void> _changeStatus(OrderModel order, String newStatus) async {
    String? cage;
    if (newStatus == 'READY_FOR_PICKUP') {
      cage = await _showCageDialog(order);
      if (cage == null) return; // User cancelled
    }

    final success = await ApiService.updateOrderStatus(order.id, newStatus, cageNumber: cage);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: newStatus == 'READY_FOR_PICKUP' ? AppTheme.readyGreen : AppTheme.primaryDark,
          content: Text(
            newStatus == 'READY_FOR_PICKUP'
                ? '🔔 Notifikasi Siap Jemput terkirim ke pemilik ${order.petName}!'
                : 'Status diperbarui ke $newStatus',
          ),
        ),
      );
      _loadOrders();
    }
  }

  Future<String?> _showCageDialog(OrderModel order) async {
    final controller = TextEditingController(text: order.holdingCageNumber ?? 'Kandang A-02');
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tetapkan Nomor Kandang / Bay', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Masukkan nomor kandang atau area penempatan hewan yang siap diambil pemilik:',
              style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: 'Nomor Kandang / Area',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, null), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.readyGreen),
            child: const Text('Kirim Notif Siap Jemput', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _showPickupVerifyDialog(OrderModel order) async {
    final pinController = TextEditingController();
    return showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Verifikasi Penjemputan ${order.petName}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pemilik: ${order.customerName} (${order.customerPhone})', style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 8),
            Text('PIN Pemilik Sebenarnya: ${order.pickupPin}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primary)),
            const SizedBox(height: 12),
            TextField(
              controller: pinController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: InputDecoration(
                labelText: 'Ketik 6 Digit PIN Pemilik',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              if (pinController.text.trim() == order.pickupPin) {
                Navigator.pop(ctx);
                await _changeStatus(order, 'PICKED_UP');
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('PIN Salah! Pastikan memeriksa aplikasi pemilik.'), backgroundColor: Colors.red),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
            child: const Text('Konfirmasi Serah Terima', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<OrderModel> filtered = _orders;
    if (_selectedFilter == 'IN_PROGRESS') {
      filtered = _orders.where((o) => o.isInProgress || o.isBookedOrCheckedIn).toList();
    } else if (_selectedFilter == 'READY') {
      filtered = _orders.where((o) => o.isReadyForPickup).toList();
    } else if (_selectedFilter == 'DELAYED') {
      filtered = _orders.where((o) => o.isDelayedPickup).toList();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Dashboard Petugas / Groomer', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
            Text('Kelola Antrean & Notifikasi Penjemputan', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: widget.onSwitchToCustomer,
            icon: const Icon(Icons.swap_horiz, size: 16, color: Colors.white),
            label: const Text('Mode Pemilik', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadOrders,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Tabs
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('ALL', 'Semua (${_orders.length})'),
                  const SizedBox(width: 8),
                  _buildFilterChip('IN_PROGRESS', 'Sedang Dikerjakan'),
                  const SizedBox(width: 8),
                  _buildFilterChip('READY', 'Siap Dijemput 🔔'),
                  const SizedBox(width: 8),
                  _buildFilterChip('DELAYED', 'Terlambat Diambil ⚠️'),
                ],
              ),
            ),
          ),

          // Orders List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? const Center(child: Text('Tidak ada antrean pesanan pada filter ini'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final order = filtered[index];
                          return _buildStaffOrderCard(order);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _selectedFilter == key;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = key),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryDark : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.textMuted,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildStaffOrderCard(OrderModel order) {
    final isDelayed = order.isDelayedPickup;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDelayed ? AppTheme.delayedRed : (order.isReadyForPickup ? AppTheme.readyGreen : AppTheme.borderLight),
          width: isDelayed || order.isReadyForPickup ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Code, Status & Delayed Pill
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      order.orderCode,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textLight),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        order.serviceCategory,
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primaryDark),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: order.isReadyForPickup
                        ? (isDelayed ? AppTheme.delayedRedBg : AppTheme.readyGreenBg)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    isDelayed ? '⚠️ TERLAMBAT ${order.minutesSinceReady} MNT' : order.statusDisplayIndonesian,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isDelayed
                          ? AppTheme.delayedRed
                          : (order.isReadyForPickup ? AppTheme.primaryDark : AppTheme.textMuted),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Pet & Owner Details
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppTheme.primaryLight,
                  backgroundImage: order.petPhoto != null ? NetworkImage(order.petPhoto!) : null,
                  child: order.petPhoto == null ? const Icon(Icons.pets, color: AppTheme.primary) : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${order.petName} (${order.petSpecies})',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Pemilik: ${order.customerName} • 📞 ${order.customerPhone}',
                        style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                      ),
                      if (order.notes != null && order.notes!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            'Catatan: "${order.notes}"',
                            style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Color(0xFFB45309)),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Cage & Owner OTW Indicator
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: order.isOwnerOnTheWay ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: order.isOwnerOnTheWay ? const Color(0xFF93C5FD) : AppTheme.borderLight),
              ),
              child: Row(
                children: [
                  Icon(
                    order.isOwnerOnTheWay ? Icons.directions_car : Icons.meeting_room,
                    color: order.isOwnerOnTheWay ? const Color(0xFF2563EB) : AppTheme.textLight,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      order.isOwnerOnTheWay
                          ? '🚗 Pemilik sedang menuju petshop (~${order.ownerEtaMinutes ?? 15} mnt)! Siapkan hewan.'
                          : 'Lokasi: ${order.holdingCageNumber ?? "Belum ditentukan"} • PIN: ${order.pickupPin}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: order.isOwnerOnTheWay ? FontWeight.bold : FontWeight.normal,
                        color: order.isOwnerOnTheWay ? const Color(0xFF1D4ED8) : AppTheme.textDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Action Buttons for Operator
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => TrackingDetailScreen(orderId: order.id)),
                      ).then((_) => _loadOrders());
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Detail & Foto', style: TextStyle(fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 8),

                // Dynamic Status Advancement
                if (order.isBookedOrCheckedIn)
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () => _changeStatus(order, 'IN_PROGRESS'),
                      icon: const Icon(Icons.play_arrow, size: 16),
                      label: const Text('Mulai Pengerjaan', style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.inProgressAmber,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  )
                else if (order.status == 'IN_PROGRESS')
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () => _changeStatus(order, 'POST_CARE'),
                      icon: const Icon(Icons.dry_cleaning, size: 16),
                      label: Text(
                        order.serviceCategory == 'Steril' ? 'Masa Pemulihan' : 'Pengeringan/Styling',
                        style: const TextStyle(fontSize: 12),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7C3AED),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  )
                else if (order.status == 'POST_CARE')
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () => _changeStatus(order, 'READY_FOR_PICKUP'),
                      icon: const Icon(Icons.notifications_active, size: 16),
                      label: const Text('Kirim Siap Jemput 🔔', style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.readyGreen,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  )
                else if (order.isReadyForPickup)
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () => _showPickupVerifyDialog(order),
                      icon: const Icon(Icons.verified, size: 16),
                      label: const Text('Verifikasi PIN Kasir', style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryDark,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  )
                else
                  const Text('Selesai Dijemput', style: TextStyle(color: AppTheme.textLight, fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

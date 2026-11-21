import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/order_model.dart';
import '../models/service_model.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/live_pickup_alert_card.dart';
import 'booking_service_screen.dart';
import 'pickup_pass_screen.dart';
import '../models/user_model.dart';
import 'tracking_detail_screen.dart';

class CustomerHomeScreen extends StatefulWidget {
  final VoidCallback onSwitchToStaff;
  final UserModel? user;
  final VoidCallback? onLogout;

  const CustomerHomeScreen({
    Key? key,
    required this.onSwitchToStaff,
    this.user,
    this.onLogout,
  }) : super(key: key);

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}


class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  List<OrderModel> _orders = [];
  List<ServiceModel> _services = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final orders = await ApiService.fetchOrders();
    final services = ApiService.getServices();
    if (mounted) {
      setState(() {
        _orders = orders;
        _services = services;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeOrders = _orders.where((o) => !o.isPickedUp).toList();
    final readyOrder = activeOrders.where((o) => o.isReadyForPickup).firstOrNull;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.primaryLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.pets, color: AppTheme.primary, size: 20),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'HappyPaws Pet Care',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                ),
                Text(
                  'Grooming • Steril • Pet Hotel',
                  style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: widget.onSwitchToStaff,
            icon: const Icon(Icons.swap_horiz, size: 16, color: AppTheme.primary),
            label: const Text(
              'Mode Staf',
              style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Perbarui Data',
          ),
          if (widget.onLogout != null)
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.redAccent),
              onPressed: widget.onLogout,
              tooltip: 'Keluar / Ganti Akun',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : RefreshIndicator(
              onRefresh: _loadData,
              color: AppTheme.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // TOP CRITICAL ALERT: When a pet is ready for pickup
                    if (readyOrder != null) ...[
                      const SizedBox(height: 6),
                      LivePickupAlertCard(
                        order: readyOrder,
                        onTapPass: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => PickupPassScreen(order: readyOrder)),
                          );
                        },
                        onRefresh: _loadData,
                      ),
                    ],

                    // Section: Active Services Tracker
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Status Hewan Peliharaan Anda',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryLight,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${activeOrders.length} Aktif',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (activeOrders.isEmpty)
                      Container(
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.borderLight),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.pets, size: 48, color: Colors.grey.shade300),
                            const SizedBox(height: 12),
                            const Text(
                              'Tidak ada hewan yang sedang dalam perawatan',
                              style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textDark),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Pesan layanan Grooming, Sterilisasi, atau Pet Hotel di bawah.',
                              style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: activeOrders.length,
                        itemBuilder: (context, index) {
                          final order = activeOrders[index];
                          return _buildActiveOrderCard(order);
                        },
                      ),

                    const SizedBox(height: 16),

                    // Section: Our Services (Grooming, Steril, Pet Hotel)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Layanan Khusus Pet Care',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                          ),
                          ElevatedButton.icon(
                            onPressed: () async {
                              final created = await Navigator.push<bool>(
                                context,
                                MaterialPageRoute(builder: (_) => const BookingServiceScreen()),
                              );
                              if (created == true) _loadData();
                            },
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Reservasi Baru', style: TextStyle(fontSize: 12)),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            ),
                          ),
                        ],
                      ),
                    ),

                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _services.length,
                      itemBuilder: (context, index) {
                        final s = _services[index];
                        return _buildServiceCatalogCard(s);
                      },
                    ),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildActiveOrderCard(OrderModel order) {
    final isSteril = order.serviceCategory == 'Steril';
    final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => TrackingDetailScreen(orderId: order.id)),
        ).then((_) => _loadData());
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: order.isReadyForPickup
                ? AppTheme.readyGreen
                : (order.isInProgress ? AppTheme.inProgressAmber : AppTheme.borderLight),
            width: order.isReadyForPickup || order.isInProgress ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: AppTheme.primaryLight,
                  backgroundImage: order.petPhoto != null ? NetworkImage(order.petPhoto!) : null,
                  child: order.petPhoto == null ? const Icon(Icons.pets, color: AppTheme.primary) : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            order.petName,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: order.isReadyForPickup
                                  ? AppTheme.readyGreenBg
                                  : (order.isInProgress ? AppTheme.inProgressBg : const Color(0xFFF1F5F9)),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              order.statusDisplayIndonesian,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: order.isReadyForPickup
                                    ? AppTheme.primaryDark
                                    : (order.isInProgress ? const Color(0xFFB45309) : AppTheme.textMuted),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${order.serviceName} • ${currency.format(order.totalPrice)}',
                        style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Mini Progress Tracker Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: order.isReadyForPickup
                    ? 1.0
                    : (order.trackingSteps.isEmpty
                        ? 0.2
                        : order.trackingSteps.where((s) => s.isCompleted).length / order.trackingSteps.length),
                backgroundColor: const Color(0xFFE2E8F0),
                valueColor: AlwaysStoppedAnimation<Color>(
                  order.isReadyForPickup ? AppTheme.readyGreen : (isSteril ? AppTheme.sterilColor : AppTheme.primary),
                ),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 10),

            // Bottom quick hint
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  order.holdingCageNumber != null ? 'Lokasi: ${order.holdingCageNumber}' : 'Sedang diproses',
                  style: const TextStyle(fontSize: 11, color: AppTheme.textLight),
                ),
                const Row(
                  children: [
                    Text('Lihat Timeline', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.primary)),
                    Icon(Icons.chevron_right, size: 16, color: AppTheme.primary),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCatalogCard(ServiceModel s) {
    final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    Color tagColor = AppTheme.groomingColor;
    if (s.category == 'Steril') tagColor = AppTheme.sterilColor;
    if (s.category == 'Pet Hotel') tagColor = AppTheme.hotelColor;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: tagColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              s.category == 'Steril'
                  ? Icons.medical_services
                  : (s.category == 'Pet Hotel' ? Icons.hotel : Icons.content_cut),
              color: tagColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        s.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textDark),
                      ),
                    ),
                    Text(
                      currency.format(s.basePrice),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primaryDark),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  s.description,
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.timer_outlined, size: 14, color: AppTheme.textLight),
                    const SizedBox(width: 4),
                    Text(
                      'Estimasi durasi: ${s.estimatedDurationMin ~/ 60 > 0 ? '${s.estimatedDurationMin ~/ 60} jam ' : ''}${s.estimatedDurationMin % 60 > 0 ? '${s.estimatedDurationMin % 60} mnt' : ''}',
                      style: const TextStyle(fontSize: 11, color: AppTheme.textLight),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

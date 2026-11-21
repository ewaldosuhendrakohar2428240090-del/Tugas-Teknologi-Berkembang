import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/order_model.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/live_pickup_alert_card.dart';
import '../widgets/tracking_stepper_widget.dart';
import 'pickup_pass_screen.dart';

class TrackingDetailScreen extends StatefulWidget {
  final int orderId;

  const TrackingDetailScreen({Key? key, required this.orderId}) : super(key: key);

  @override
  State<TrackingDetailScreen> createState() => _TrackingDetailScreenState();
}

class _TrackingDetailScreenState extends State<TrackingDetailScreen> {
  OrderModel? _order;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  Future<void> _loadOrder() async {
    setState(() => _isLoading = true);
    final order = await ApiService.fetchOrderDetail(widget.orderId);
    if (mounted) {
      setState(() {
        _order = order;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppTheme.primary)),
      );
    }

    if (_order == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detail Tracking')),
        body: const Center(child: Text('Data pesanan tidak ditemukan')),
      );
    }

    final order = _order!;
    final isSteril = order.serviceCategory == 'Steril';

    return Scaffold(
      appBar: AppBar(
        title: Text(order.orderCode),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadOrder,
            tooltip: 'Segarkan Status',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadOrder,
        color: AppTheme.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ready For Pickup Top Banner if active
              if (order.isReadyForPickup)
                LivePickupAlertCard(
                  order: order,
                  onTapPass: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => PickupPassScreen(order: order)),
                    );
                  },
                  onRefresh: _loadOrder,
                ),

              // Pet & Service Summary Card
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.borderLight),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: AppTheme.primaryLight,
                      backgroundImage: order.petPhoto != null ? NetworkImage(order.petPhoto!) : null,
                      child: order.petPhoto == null
                          ? const Icon(Icons.pets, color: AppTheme.primary, size: 28)
                          : null,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                order.petName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textDark,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isSteril ? const Color(0xFFEDE9FE) : const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  order.serviceCategory,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isSteril ? AppTheme.sterilColor : AppTheme.groomingColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            order.serviceName,
                            style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Check-in: ${order.checkInTime != null ? DateFormat('dd MMM, HH:mm').format(order.checkInTime!) : '-'}',
                            style: const TextStyle(fontSize: 11, color: AppTheme.textLight),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Status Summary Bar
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: order.isReadyForPickup
                      ? AppTheme.readyGreenBg
                      : (order.isInProgress ? AppTheme.inProgressBg : const Color(0xFFF1F5F9)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      order.isReadyForPickup
                          ? Icons.check_circle
                          : (order.isInProgress ? Icons.access_time_filled : Icons.info),
                      color: order.isReadyForPickup
                          ? AppTheme.readyGreen
                          : (order.isInProgress ? AppTheme.inProgressAmber : AppTheme.textMuted),
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Status Saat Ini:',
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                          ),
                          Text(
                            order.statusDisplayIndonesian,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: order.isReadyForPickup
                                  ? AppTheme.primaryDark
                                  : (order.isInProgress ? const Color(0xFF92400E) : AppTheme.textDark),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Timeline Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Live Tracking Pengerjaan',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                    ),
                    Text(
                      '${order.trackingSteps.where((s) => s.isCompleted).length}/${order.trackingSteps.length} Selesai',
                      style: const TextStyle(fontSize: 12, color: AppTheme.textMuted, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Stepper List
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: TrackingStepperWidget(
                  steps: order.trackingSteps,
                  isSteril: isSteril,
                ),
              ),

              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, -4)),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Menghubungkan ke Staf Pet Shop via WhatsApp: 0812-3456-7890'),
                        backgroundColor: AppTheme.primaryDark,
                      ),
                    );
                  },
                  icon: const Icon(Icons.chat_outlined, size: 18),
                  label: const Text('Tanya Staf'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primary,
                    side: const BorderSide(color: AppTheme.primary),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => PickupPassScreen(order: order)),
                    );
                  },
                  icon: const Icon(Icons.qr_code, size: 20),
                  label: const Text('Pass Penjemputan'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: order.isReadyForPickup ? AppTheme.readyGreen : AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../models/order_model.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';

class LivePickupAlertCard extends StatefulWidget {
  final OrderModel order;
  final VoidCallback onTapPass;
  final VoidCallback onRefresh;

  const LivePickupAlertCard({
    super.key,
    required this.order,
    required this.onTapPass,
    required this.onRefresh,
  });

  @override
  State<LivePickupAlertCard> createState() => _LivePickupAlertCardState();
}

class _LivePickupAlertCardState extends State<LivePickupAlertCard> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _isSendingOtw = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.97, end: 1.03).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _handleOnTheWay() async {
    setState(() => _isSendingOtw = true);
    await ApiService.notifyOnTheWay(widget.order.id, 15);
    setState(() => _isSendingOtw = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppTheme.primaryDark,
          content: Text('🚗 Staf Pet Shop telah diberitahu! Peliharaan Anda sedang disiapkan di meja penjemputan.'),
        ),
      );
      widget.onRefresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final isDelayed = order.isDelayedPickup;

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: child,
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDelayed
                ? [const Color(0xFFFEF2F2), const Color(0xFFFEE2E2)]
                : [const Color(0xFFECFDF5), const Color(0xFFD1FAE5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDelayed ? AppTheme.delayedRed : AppTheme.readyGreen,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: (isDelayed ? AppTheme.delayedRed : AppTheme.readyGreen).withValues(alpha: 0.2),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Tag & Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDelayed ? AppTheme.delayedRed : AppTheme.readyGreen,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.notifications_active, color: Colors.white, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          isDelayed ? 'PERINGATAN JEMPUT' : 'SIAP DIJEMPUT SEKARANG',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    order.minutesSinceReady != null
                        ? 'Siap ${order.minutesSinceReady} mnt lalu'
                        : 'Baru saja selesai',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDelayed ? AppTheme.delayedRed : AppTheme.primaryDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Main Message
              Text(
                '🎉 ${order.petName} telah selesai ${order.serviceName}!',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                order.serviceCategory == 'Steril'
                    ? 'Observasi anestesi telah stabil dan ${order.petName} sudah sadar penuh. Silakan bawa carrier/keranjang untuk menjemput.'
                    : '${order.petName} sudah harum, bersih, dan menunggumu di pet shop.',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textMuted,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),

              // Kandang / Bay Location Box
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderLight),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.meeting_room, color: AppTheme.primary, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Lokasi Pengambilan:',
                            style: TextStyle(fontSize: 11, color: AppTheme.textLight, fontWeight: FontWeight.w500),
                          ),
                          Text(
                            order.holdingCageNumber ?? 'Kandang Tunggu Depan Kasir',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Action Buttons
              Row(
                children: [
                  // Pass Penjemputan Button
                  Expanded(
                    flex: 3,
                    child: ElevatedButton.icon(
                      onPressed: widget.onTapPass,
                      icon: const Icon(Icons.qr_code, size: 18),
                      label: const Text('Pass Jemput (QR/PIN)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDelayed ? AppTheme.delayedRed : AppTheme.readyGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // "Saya Sedang Menuju ke Toko" Button
                  Expanded(
                    flex: 2,
                    child: OutlinedButton(
                      onPressed: order.isOwnerOnTheWay ? null : _handleOnTheWay,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryDark,
                        side: const BorderSide(color: AppTheme.primary, width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: _isSendingOtw
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              order.isOwnerOnTheWay ? '🚗 Menuju Toko' : 'Saya OTW!',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

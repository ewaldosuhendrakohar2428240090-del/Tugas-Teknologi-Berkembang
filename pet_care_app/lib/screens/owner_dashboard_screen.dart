import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../models/user_model.dart';
import '../models/sale_model.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';

class OwnerDashboardScreen extends StatefulWidget {
  final UserModel user;

  const OwnerDashboardScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends State<OwnerDashboardScreen> {
  List<SaleModel> _sales = [];
  bool _isLoading = true;
  final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  // Summary stats
  double _totalRevenue = 0;
  int _totalTransactions = 0;

  @override
  void initState() {
    super.initState();
    _loadSales();
  }

  Future<void> _loadSales() async {
    setState(() => _isLoading = true);

    try {
      final baseUrl = kIsWeb ? 'http://localhost:5000/api' : 'http://10.0.2.2:5000/api';
      final response = await http.get(
        Uri.parse('$baseUrl/sales'),
      ).timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] is List) {
          final sales = (data['data'] as List).map((s) => SaleModel.fromJson(s)).toList();
          if (mounted) {
            setState(() {
              _sales = sales;
              _totalRevenue = data['totalRevenue'] != null
                  ? double.tryParse(data['totalRevenue'].toString()) ?? 0.0
                  : 0.0;
              _totalTransactions = sales.length;
              _isLoading = false;
            });
          }
          return;
        }
      }
    } catch (e) {
      debugPrint('ℹ️ API offline, using mock sales: $e');
    }

    // Fallback mock
    _loadMockSales();
  }

  void _loadMockSales() {
    final mockSales = [
      SaleModel(
        id: 1,
        orderCode: 'ORD-2026-001',
        customerId: 1,
        status: 'PICKED_UP',
        notes: 'Model kepala bulat manis, wangi baby powder.',
        totalPrice: 120000.0,
        originalPrice: 120000.0,
        checkInTime: DateTime.now().subtract(const Duration(hours: 3)),
        pickedUpAt: DateTime.now().subtract(const Duration(hours: 1)),
        customerName: 'Budi Santoso',
        customerPhone: '081234567890',
        petName: 'Milo',
        petSpecies: 'Kucing',
        serviceName: 'Full Grooming Spa Premium',
        serviceCategory: 'Grooming',
      ),
      SaleModel(
        id: 3,
        orderCode: 'ORD-2026-003',
        customerId: 2,
        status: 'PICKED_UP',
        notes: 'Steril betina, pemulihan lancar.',
        totalPrice: 550000.0,
        originalPrice: 550000.0,
        checkInTime: DateTime.now().subtract(const Duration(days: 1)),
        pickedUpAt: DateTime.now().subtract(const Duration(hours: 12)),
        customerName: 'Siti Rahma',
        customerPhone: '081298765432',
        petName: 'Luna',
        petSpecies: 'Kucing',
        serviceName: 'Sterilisasi Kucing Betina (OH)',
        serviceCategory: 'Steril',
      ),
      SaleModel(
        id: 4,
        orderCode: 'ORD-2026-004',
        customerId: 1,
        status: 'PICKED_UP',
        notes: 'Menginap 2 malam, kondisi baik.',
        totalPrice: 170000.0,
        originalPrice: 170000.0,
        checkInTime: DateTime.now().subtract(const Duration(days: 3)),
        pickedUpAt: DateTime.now().subtract(const Duration(days: 1)),
        customerName: 'Budi Santoso',
        customerPhone: '081234567890',
        petName: 'Rocky',
        petSpecies: 'Anjing',
        serviceName: 'Pet Hotel Deluxe (Per Malam)',
        serviceCategory: 'Pet Hotel',
      ),
    ];

    setState(() {
      _sales = mockSales;
      _totalRevenue = mockSales.fold(0.0, (sum, s) => sum + s.totalPrice);
      _totalTransactions = mockSales.length;
      _isLoading = false;
    });
  }

  Future<void> _showEditDialog(SaleModel sale) async {
    final priceController = TextEditingController(text: sale.totalPrice.toStringAsFixed(0));
    final notesController = TextEditingController(text: sale.notes ?? '');

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420),
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.edit_note, color: Color(0xFFD97706), size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Edit Penjualan',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                            ),
                            Text(
                              sale.orderCode,
                              style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Info Card
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.borderLight),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: _categoryColor(sale.serviceCategory).withOpacity(0.15),
                          child: Icon(
                            _categoryIcon(sale.serviceCategory),
                            color: _categoryColor(sale.serviceCategory),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(sale.petName,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              Text('${sale.serviceName} • ${sale.customerName}',
                                  style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Price Field
                  const Text('Total Harga (Rp)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: priceController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryDark),
                    decoration: InputDecoration(
                      prefixText: 'Rp ',
                      prefixStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textMuted),
                      filled: true,
                      fillColor: const Color(0xFFF0FDFA),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppTheme.primary),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppTheme.primary, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Notes Field
                  const Text('Catatan', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: notesController,
                    maxLines: 3,
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Tambahkan catatan...',
                      hintStyle: const TextStyle(color: AppTheme.textLight),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppTheme.borderLight),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppTheme.primary, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            side: const BorderSide(color: AppTheme.borderLight),
                          ),
                          child: const Text('Batal', style: TextStyle(color: AppTheme.textMuted, fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(ctx, {
                              'totalPrice': double.tryParse(priceController.text) ?? sale.totalPrice,
                              'notes': notesController.text,
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.save, size: 18),
                              SizedBox(width: 6),
                              Text('Simpan', style: TextStyle(fontWeight: FontWeight.bold)),
                            ],
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
      },
    );

    if (result != null) {
      await _updateSale(sale.id, result['totalPrice'], result['notes']);
    }
  }

  Future<void> _updateSale(int id, double totalPrice, String notes) async {
    try {
      final baseUrl = kIsWeb ? 'http://localhost:5000/api' : 'http://10.0.2.2:5000/api';
      await http.patch(
        Uri.parse('$baseUrl/sales/$id'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'totalPrice': totalPrice, 'notes': notes}),
      ).timeout(const Duration(seconds: 3));
    } catch (e) {
      debugPrint('ℹ️ API offline, updating mock data: $e');
    }

    // Update local state
    final idx = _sales.indexWhere((s) => s.id == id);
    if (idx != -1) {
      final old = _sales[idx];
      setState(() {
        _sales[idx] = SaleModel(
          id: old.id,
          orderCode: old.orderCode,
          customerId: old.customerId,
          status: old.status,
          notes: notes,
          totalPrice: totalPrice,
          originalPrice: old.originalPrice,
          checkInTime: old.checkInTime,
          pickedUpAt: old.pickedUpAt,
          createdAt: old.createdAt,
          customerName: old.customerName,
          customerPhone: old.customerPhone,
          petName: old.petName,
          petSpecies: old.petSpecies,
          serviceName: old.serviceName,
          serviceCategory: old.serviceCategory,
        );
        _totalRevenue = _sales.fold(0.0, (sum, s) => sum + s.totalPrice);
      });
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('Data penjualan berhasil diperbarui!'),
            ],
          ),
          backgroundColor: AppTheme.readyGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  Color _categoryColor(String category) {
    switch (category) {
      case 'Grooming':
        return AppTheme.groomingColor;
      case 'Steril':
        return AppTheme.sterilColor;
      case 'Pet Hotel':
        return AppTheme.hotelColor;
      default:
        return AppTheme.primary;
    }
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'Grooming':
        return Icons.content_cut;
      case 'Steril':
        return Icons.medical_services;
      case 'Pet Hotel':
        return Icons.hotel;
      default:
        return Icons.pets;
    }
  }

  void _logout() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.diamond, color: Color(0xFFD97706), size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Owner Dashboard',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                ),
                Text(
                  'Halo, ${widget.user.name}',
                  style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSales,
            tooltip: 'Perbarui Data',
          ),
          PopupMenuButton<String>(
            onSelected: (val) {
              if (val == 'logout') _logout();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 18, color: AppTheme.delayedRed),
                    SizedBox(width: 8),
                    Text('Keluar', style: TextStyle(color: AppTheme.delayedRed)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : RefreshIndicator(
              onRefresh: _loadSales,
              color: AppTheme.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Summary Cards
                    _buildSummarySection(),
                    const SizedBox(height: 24),

                    // Sales List Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Riwayat Penjualan',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryLight,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$_totalTransactions Transaksi',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Sales List
                    if (_sales.isEmpty)
                      _buildEmptyState()
                    else
                      ..._sales.map((sale) => _buildSaleCard(sale)),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSummarySection() {
    return Column(
      children: [
        // Big Revenue Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Pendapatan',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withOpacity(0.85),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.trending_up, color: Colors.white, size: 14),
                        SizedBox(width: 4),
                        Text(
                          'Semua Waktu',
                          style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                currency.format(_totalRevenue),
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '$_totalTransactions transaksi selesai',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withOpacity(0.75),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Category Stats Row
        Row(
          children: [
            _buildCategoryStat('Grooming', Icons.content_cut, AppTheme.groomingColor),
            const SizedBox(width: 10),
            _buildCategoryStat('Steril', Icons.medical_services, AppTheme.sterilColor),
            const SizedBox(width: 10),
            _buildCategoryStat('Pet Hotel', Icons.hotel, AppTheme.hotelColor),
          ],
        ),
      ],
    );
  }

  Widget _buildCategoryStat(String category, IconData icon, Color color) {
    final count = _sales.where((s) => s.serviceCategory == category).length;
    final total = _sales.where((s) => s.serviceCategory == category).fold(0.0, (sum, s) => sum + s.totalPrice);

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.borderLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 16),
                ),
                const Spacer(),
                Text(
                  '$count',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              category,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textDark),
            ),
            Text(
              currency.format(total),
              style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaleCard(SaleModel sale) {
    final color = _categoryColor(sale.serviceCategory);
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm', 'id_ID');
    final priceChanged = sale.originalPrice != null && sale.totalPrice != sale.originalPrice;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: color.withOpacity(0.12),
                child: Icon(_categoryIcon(sale.serviceCategory), color: color, size: 22),
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
                            '${sale.petName} (${sale.petSpecies ?? ''})',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textDark),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          currency.format(sale.totalPrice),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: priceChanged ? const Color(0xFFD97706) : AppTheme.primaryDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      sale.serviceName,
                      style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.person_outline, size: 14, color: AppTheme.textLight),
                const SizedBox(width: 4),
                Text(sale.customerName, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                const Spacer(),
                const Icon(Icons.access_time, size: 14, color: AppTheme.textLight),
                const SizedBox(width: 4),
                Text(
                  sale.pickedUpAt != null ? dateFormat.format(sale.pickedUpAt!) : '-',
                  style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                ),
              ],
            ),
          ),
          if (sale.notes != null && sale.notes!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.notes, size: 14, color: AppTheme.textLight),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    sale.notes!,
                    style: const TextStyle(fontSize: 11, color: AppTheme.textMuted, fontStyle: FontStyle.italic),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  sale.serviceCategory,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
                ),
              ),
              TextButton.icon(
                onPressed: () => _showEditDialog(sale),
                icon: const Icon(Icons.edit, size: 16),
                label: const Text('Edit Penjualan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFD97706),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        children: [
          Icon(Icons.receipt_long, size: 56, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text(
            'Belum ada data penjualan',
            style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textDark, fontSize: 16),
          ),
          const SizedBox(height: 6),
          const Text(
            'Data akan muncul setelah ada pesanan yang selesai (PICKED_UP)',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

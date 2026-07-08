import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/shared_widgets.dart';
import '../../../../features/order/presentation/providers/order_provider.dart';
import '../../../../features/order/data/models/order_model.dart';

class PelangganPaymentScreen extends ConsumerStatefulWidget {
  final OrderModel order;
  const PelangganPaymentScreen({super.key, required this.order});

  @override
  ConsumerState<PelangganPaymentScreen> createState() =>
      _PelangganPaymentScreenState();
}

class _PelangganPaymentScreenState
    extends ConsumerState<PelangganPaymentScreen> {
  String _selectedMethod = 'cash';
  bool _isSubmitting = false;
  late TextEditingController _amountCtrl;

  @override
  void initState() {
    super.initState();
    final remainingBalance = widget.order.totalPrice - widget.order.totalPaid;
    _amountCtrl = TextEditingController(text: remainingBalance.toStringAsFixed(0));
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  // For Transfer
  File? _proofImage;
  final _picker = ImagePicker();

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _proofImage = File(picked.path);
      });
    }
  }

  void _submitPayment() async {
    if (_selectedMethod == 'transfer' && _proofImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Silakan upload bukti transfer terlebih dahulu'),
        backgroundColor: AppColors.danger,
      ));
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final amount = double.tryParse(_amountCtrl.text) ?? (widget.order.totalPrice - widget.order.totalPaid);
      await ref.read(orderProvider.notifier).payOrder(
            widget.order.id,
            _selectedMethod,
            amount,
            proof: _proofImage,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Pembayaran berhasil dikirim! Menunggu konfirmasi kasir.'),
          backgroundColor: AppColors.success,
        ));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = e.toString();
        if (e is DioException) {
          errorMessage = e.response?.data?['message'] ?? e.response?.data?['error'] ?? e.message ?? errorMessage;
        }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Gagal: $errorMessage'),
          backgroundColor: AppColors.danger,
        ));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GradientAppBar(title: 'Pembayaran', subtitle: widget.order.invoice),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Info Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: AppColors.primaryGradient,
                    begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8))],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Sisa Tagihan',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontWeight: FontWeight.w600)),
                      Text(formatCurrency(widget.order.totalPrice - widget.order.totalPaid),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(color: Colors.white24, height: 1),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('No. Order',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6), fontSize: 12)),
                      Text(widget.order.invoice,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            const Text('PILIH METODE PEMBAYARAN',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textMid,
                    letterSpacing: 0.5)),
            const SizedBox(height: 16),
            Row(
              children: [
                _payMethodChip('cash', 'Cash', '💵'),
                const SizedBox(width: 8),
                _payMethodChip('qris', 'QRIS', '📲'),
                const SizedBox(width: 8),
                _payMethodChip('transfer', 'Transfer', '🏦'),
                const SizedBox(width: 8),
                _payMethodChip('ewallet', 'E-Wallet', '💳'),
              ],
            ),
            const SizedBox(height: 28),

            // Dynamic Content Based on Selected Method
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _buildMethodContent(),
            ),
            const SizedBox(height: 24),
            const Text('JUMLAH BAYAR',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textMid,
                    letterSpacing: 0.5)),
            const SizedBox(height: 12),
            TextFormField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.w900,
                  fontSize: 24),
              decoration: InputDecoration(
                prefixText: 'Rp ',
                prefixStyle: const TextStyle(
                    color: AppColors.textMid, fontSize: 24, fontWeight: FontWeight.bold),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 16),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.divider)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.divider)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                        color: AppColors.primary, width: 2)),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _submitPayment,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              elevation: 4,
              shadowColor: AppColors.primary.withValues(alpha: 0.4),
            ),
            child: _isSubmitting
                ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                : Text('Kirim Pembayaran',
                    style: GoogleFonts.poppins(
                        fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
          ),
        ),
      ),
    );
  }

  Widget _buildMethodContent() {
    if (_selectedMethod == 'cash') {
      return Container(
        key: const ValueKey('cash'),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.divider),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: const Column(
          children: [
            Icon(Icons.storefront_rounded, color: AppColors.success, size: 56),
            SizedBox(height: 20),
            Text(
              'Pembayaran Tunai di Toko',
              style: TextStyle(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.w800,
                  fontSize: 18),
            ),
            SizedBox(height: 12),
            Text(
              'Silakan datang ke toko dan lakukan pembayaran secara tunai di kasir. Tekan "Kirim Pembayaran" untuk memberitahu kasir bahwa Anda akan membayar secara tunai.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMid, fontSize: 13, height: 1.6),
            ),
          ],
        ),
      );
    } else if (_selectedMethod == 'qris') {
      return Container(
        key: const ValueKey('qris'),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.divider),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          children: [
            const Icon(Icons.qr_code_2_rounded, color: AppColors.primary, size: 56),
            const SizedBox(height: 16),
            const Text(
              'Scan QR Code Toko',
              style: TextStyle(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.w800,
                  fontSize: 18),
            ),
            const SizedBox(height: 12),
            const Text(
              'Minta kasir untuk menunjukkan QR Code, lalu scan menggunakan aplikasi bank atau e-wallet Anda (GoPay, OVO, Dana, dll).',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMid, fontSize: 13, height: 1.6),
            ),
            const SizedBox(height: 24),
            // Static QR Code placeholder
            Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.divider),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
              ),
              padding: const EdgeInsets.all(16),
              child: Image.network(
                'https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=WashFlow-Laundry-QRIS-00020101021226580014ID.CO.BNI.WWW01189360004680019040000001BNI0215000039880000003031ID63040B26',
                fit: BoxFit.contain,
                errorBuilder: (c, e, s) => const Icon(
                  Icons.qr_code_2,
                  size: 150,
                  color: AppColors.textLight,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 18),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Setelah scan & bayar, tekan tombol di bawah untuk konfirmasi.',
                      style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else if (_selectedMethod == 'ewallet') {
      // E-Wallet
      return Container(
        key: const ValueKey('ewallet'),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.divider),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          children: [
            const Row(
              children: [
                Icon(Icons.account_balance_wallet_rounded, color: AppColors.info, size: 32),
                SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Transfer ke E-Wallet:\nGoPay/OVO/Dana: 0812-3456-7890 a.n. WashFlow',
                    style: TextStyle(color: AppColors.textDark, fontSize: 14, height: 1.5, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Divider(color: AppColors.divider, height: 1),
            ),
            if (_proofImage != null)
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(_proofImage!, height: 200, width: double.infinity, fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: CircleAvatar(
                      backgroundColor: Colors.black.withValues(alpha: 0.6),
                      child: IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white),
                        onPressed: () => setState(() => _proofImage = null),
                      ),
                    ),
                  ),
                ],
              )
            else
              OutlinedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.upload_file_rounded, color: AppColors.info),
                label: const Text('Upload Bukti E-Wallet', style: TextStyle(color: AppColors.info, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                  side: const BorderSide(color: AppColors.info, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  backgroundColor: AppColors.info.withValues(alpha: 0.05),
                ),
              ),
          ],
        ),
      );
    } else {
      // Transfer
      return Container(
        key: const ValueKey('transfer'),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.divider),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          children: [
            const Row(
              children: [
                Icon(Icons.account_balance_rounded, color: AppColors.warning, size: 32),
                SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Transfer ke Rekening:\nBCA 123456789 a.n. WashFlow Laundry',
                    style: TextStyle(color: AppColors.textDark, fontSize: 14, height: 1.5, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Divider(color: AppColors.divider, height: 1),
            ),
            if (_proofImage != null)
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(_proofImage!, height: 200, width: double.infinity, fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: CircleAvatar(
                      backgroundColor: Colors.black.withValues(alpha: 0.6),
                      child: IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white),
                        onPressed: () => setState(() => _proofImage = null),
                      ),
                    ),
                  ),
                ],
              )
            else
              OutlinedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.upload_file_rounded, color: AppColors.warning),
                label: const Text('Upload Bukti Transfer', style: TextStyle(color: AppColors.warning, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                  side: const BorderSide(color: AppColors.warning, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  backgroundColor: AppColors.warning.withValues(alpha: 0.05),
                ),
              ),
          ],
        ),
      );
    }
  }

  Widget _payMethodChip(String value, String label, String emoji) {
    final isSelected = value == _selectedMethod;
    final colors = {
      'cash': AppColors.success,
      'qris': AppColors.primary,
      'transfer': AppColors.warning,
      'ewallet': AppColors.info,
    };
    final color = colors[value]!;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedMethod = value;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.1)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: isSelected ? color : AppColors.divider, width: isSelected ? 2 : 1),
            boxShadow: isSelected ? [] : [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 2))],
          ),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(height: 10),
              Text(label,
                  style: TextStyle(
                      color: isSelected ? color : AppColors.textMid,
                      fontSize: 13,
                      fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      ),
    );
  }
}

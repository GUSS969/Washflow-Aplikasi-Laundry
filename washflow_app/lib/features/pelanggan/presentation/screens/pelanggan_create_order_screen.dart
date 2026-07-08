import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/shared_widgets.dart';
import '../../../../features/service/presentation/providers/service_provider.dart';
import '../../../../features/service/data/models/service_model.dart';
import '../../../../features/order/presentation/providers/order_provider.dart';

class PelangganCreateOrderScreen extends ConsumerStatefulWidget {
  const PelangganCreateOrderScreen({super.key});
  @override
  ConsumerState<PelangganCreateOrderScreen> createState() =>
      _PelangganCreateOrderScreenState();
}

class _PelangganCreateOrderScreenState
    extends ConsumerState<PelangganCreateOrderScreen> {
  ServiceModel? _selectedService;
  String _serviceType = 'cuci_setrika';
  String _perfumeType = 'reguler';
  String _clothNotes = '';
  String _deliveryType = 'antar_sendiri';
  String _address = '';
  double _estimateWeight = 0;
  int _estimateQty = 1;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(serviceProvider.notifier).fetchServices());
  }

  InputDecoration _inputDeco(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textLight),
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.divider)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.divider)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
      );

  Future<void> _submit() async {
    if (_selectedService == null) {
      _snack('Pilih layanan terlebih dahulu', isError: true);
      return;
    }
    if (_deliveryType == 'minta_dijemput' && _address.trim().isEmpty) {
      _snack('Alamat penjemputan wajib diisi', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);

    String? notes;
    if (_deliveryType == 'minta_dijemput' && _address.trim().isNotEmpty) {
      notes = 'Alamat Penjemputan: ${_address.trim()}';
    }

    final details = [
      {
        'service_id': _selectedService!.id,
        if (_selectedService!.unit == 'kg') 'weight': _estimateWeight,
        if (_selectedService!.unit != 'kg') 'qty': _estimateQty,
      }
    ];

    try {
      await ref.read(orderProvider.notifier).createOrder(
            null,
            details,
            deliveryType: _deliveryType,
            serviceType: _serviceType,
            perfumeType: _perfumeType,
            clothNotes: _clothNotes.trim().isEmpty ? null : _clothNotes.trim(),
            notes: notes,
          );
      if (mounted) {
        _snack('Pesanan berhasil dikirim! Menunggu konfirmasi kasir.');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) _snack('Gagal: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppColors.danger : AppColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final servicesAsync = ref.watch(serviceProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Buat Pesanan Baru',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        backgroundColor: AppColors.background,
        elevation: 0.5,
        foregroundColor: AppColors.textDark,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 24),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Pesananmu akan dikonfirmasi kasir terlebih dahulu. Harga & berat aktual ditimbang saat pakaian diterima.',
                      style: TextStyle(
                          color: AppColors.primary, fontSize: 13, height: 1.5, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ─── PILIH LAYANAN ────────────────────────────────────────
            _sectionTitle('PILIH LAYANAN'),
            servicesAsync.when(
              loading: () => const Center(
                  child: CircularProgressIndicator(strokeWidth: 2)),
              error: (_, __) => const Text('Gagal memuat layanan',
                  style: TextStyle(color: AppColors.danger)),
              data: (services) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: _cardDeco(),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<ServiceModel>(
                    value: _selectedService,
                    hint: const Text('Ketuk untuk memilih layanan...',
                        style:
                            TextStyle(color: AppColors.textLight, fontSize: 14)),
                    dropdownColor: AppColors.surface,
                    isExpanded: true,
                    style: const TextStyle(color: AppColors.textDark, fontSize: 14, fontWeight: FontWeight.w600),
                    icon: const Icon(Icons.expand_more_rounded, color: AppColors.textMid),
                    items: services
                        .map((s) => DropdownMenuItem(
                            value: s,
                            child: Text(
                                '${s.serviceName} – ${formatCurrency(s.price)}/${s.unit}')))
                        .toList(),
                    onChanged: (s) => setState(() {
                      _selectedService = s;
                      _estimateWeight = 0;
                      _estimateQty = 1;
                    }),
                  ),
                ),
              ),
            ),

            if (_selectedService != null) ...[
              const SizedBox(height: 16),
              _sectionTitle(
                  'PERKIRAAN ${_selectedService!.unit.toUpperCase()} (OPSIONAL)'),
              TextFormField(
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w600),
                decoration: _inputDeco(
                    'Kira-kira berapa ${_selectedService!.unit}?').copyWith(
                  suffixText: _selectedService!.unit,
                  suffixStyle: const TextStyle(color: AppColors.textMid, fontWeight: FontWeight.bold),
                ),
                onChanged: (v) {
                  if (_selectedService!.unit == 'kg') {
                    _estimateWeight = double.tryParse(v) ?? 0;
                  } else {
                    _estimateQty = int.tryParse(v) ?? 1;
                  }
                },
              ),
            ],

            const SizedBox(height: 28),

            // ─── JENIS LAYANAN ────────────────────────────────────────
            _sectionTitle('JENIS LAYANAN'),
            _chipGroup(
              options: const {
                'cuci_setrika': ('🫧 Cuci + Setrika', AppColors.primary),
                'cuci_saja': ('🧺 Cuci Saja', Color(0xFF06B6D4)),
                'setrika_saja': ('👔 Setrika Saja', Color(0xFF8B5CF6)),
              },
              selected: _serviceType,
              onSelect: (v) => setState(() => _serviceType = v),
            ),
            const SizedBox(height: 28),

            // ─── PILIHAN PARFUM ───────────────────────────────────────
            _sectionTitle('PILIHAN PARFUM'),
            _chipGroup(
              options: const {
                'tanpa_parfum': ('🚫 Tanpa Parfum', AppColors.textMid),
                'reguler': ('🌸 Reguler', AppColors.warning),
                'antibakteri': ('🛡️ Antibakteri', AppColors.success),
                'lavender': ('💜 Lavender', Color(0xFFA855F7)),
                'floral': ('🌺 Floral', Color(0xFFEC4899)),
                'sport': ('⚡ Sport', AppColors.danger),
              },
              selected: _perfumeType,
              onSelect: (v) => setState(() => _perfumeType = v),
            ),
            const SizedBox(height: 28),

            // ─── CATATAN BAJU ─────────────────────────────────────────
            _sectionTitle('CATATAN BAJU (OPSIONAL)'),
            TextField(
              maxLines: 3,
              style: const TextStyle(color: AppColors.textDark, fontSize: 14),
              decoration: _inputDeco(
                  'Contoh: Ada warna merah yang luntur, tolong pisahkan dari yang putih...'),
              onChanged: (v) => _clothNotes = v,
            ),
            const SizedBox(height: 28),

            // ─── PENGIRIMAN ───────────────────────────────────────────
            _sectionTitle('METODE PENGIRIMAN'),
            Container(
              decoration: _cardDeco(),
              child: Column(
                children: [
                  RadioListTile<String>(
                    value: 'antar_sendiri',
                    groupValue: _deliveryType,
                    title: const Text('🏪 Saya Antar & Ambil Sendiri ke Toko',
                        style: TextStyle(color: AppColors.textDark, fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: const Text('Gratis, datang langsung ke toko',
                        style: TextStyle(color: AppColors.textMid, fontSize: 12)),
                    activeColor: AppColors.primary,
                    onChanged: (v) => setState(() => _deliveryType = v!),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  const Divider(color: AppColors.divider, height: 1),
                  RadioListTile<String>(
                    value: 'minta_dijemput',
                    groupValue: _deliveryType,
                    title: const Text('🛵 Minta Kurir Jemput & Antar',
                        style: TextStyle(color: AppColors.textDark, fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: const Text('Kurir kami akan datang ke lokasi Anda',
                        style: TextStyle(color: AppColors.textMid, fontSize: 12)),
                    activeColor: AppColors.primary,
                    onChanged: (v) => setState(() => _deliveryType = v!),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ],
              ),
            ),

            if (_deliveryType == 'minta_dijemput') ...[
              const SizedBox(height: 16),
              _sectionTitle('ALAMAT LENGKAP PENJEMPUTAN'),
              TextField(
                maxLines: 3,
                style: const TextStyle(color: AppColors.textDark),
                decoration: _inputDeco(
                    'Masukkan alamat lengkap untuk penjemputan baju...'),
                onChanged: (v) => _address = v,
              ),
            ],

            const SizedBox(height: 28),

            // ─── INFO PEMBAYARAN ──────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: AppColors.warning.withValues(alpha: 0.3)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(Icons.payments_outlined,
                        color: AppColors.warning, size: 20),
                    SizedBox(width: 10),
                    Text('Informasi Pembayaran',
                        style: TextStyle(
                            color: AppColors.warning,
                            fontWeight: FontWeight.bold,
                            fontSize: 14)),
                  ]),
                  SizedBox(height: 12),
                  Text(
                    '• 💵 Cash: Bayar saat ambil baju di toko\n'
                    '• 📲 QRIS: Kasir akan tunjukkan QR saat transaksi\n'
                    '• 🏦 Transfer: Kasir akan informasikan rekening tujuan',
                    style: TextStyle(
                        color: AppColors.warning, fontSize: 12, height: 1.7, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(54),
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 4,
                shadowColor: AppColors.primary.withValues(alpha: 0.5),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white)))
                  : const Text('Kirim Pesanan Sekarang',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _chipGroup({
    required Map<String, (String, Color)> options,
    required String selected,
    required void Function(String) onSelect,
  }) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: options.entries.map((e) {
        final isSelected = selected == e.key;
        final (label, color) = e.value;
        return GestureDetector(
          onTap: () => onSelect(e.key),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? color.withValues(alpha: 0.1)
                  : AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: isSelected ? color : AppColors.divider,
                  width: isSelected ? 1.5 : 1),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? color : AppColors.textMid,
                fontSize: 13,
                fontWeight:
                    isSelected ? FontWeight.bold : FontWeight.w600,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _sectionTitle(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(title,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.textMid,
                letterSpacing: 0.5)),
      );

  BoxDecoration _cardDeco() => BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2))],
      );
}

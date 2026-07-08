import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/shared_widgets.dart';
import '../../../../features/customer/presentation/providers/customer_provider.dart';
import '../../../../features/customer/data/models/customer_model.dart';
import '../../../../features/service/presentation/providers/service_provider.dart';
import '../../../../features/service/data/models/service_model.dart';
import '../../../../features/order/presentation/providers/order_provider.dart';

class _OrderItem {
  ServiceModel? service;
  double weight;
  int qty;
  _OrderItem() : weight = 0, qty = 1;

  double get subtotal {
    if (service == null) return 0;
    if (service!.unit == 'kg') return service!.price * weight;
    return service!.price * qty;
  }
}

class CreateOrderScreen extends ConsumerStatefulWidget {
  const CreateOrderScreen({super.key});
  @override
  ConsumerState<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends ConsumerState<CreateOrderScreen> {
  CustomerModel? _selectedCustomer;
  final List<_OrderItem> _items = [_OrderItem()];
  String _paymentStatus = 'belum_lunas';
  String _serviceType = 'cuci_setrika';
  String _perfumeType = 'reguler';
  String _deliveryType = 'antar_sendiri';
  String _clothNotes = '';
  DateTime? _estimatedReady;
  bool _isSubmitting = false;
  // ignore: unused_field
  String _customerSearch = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(customerProvider.notifier).fetchCustomers();
      ref.read(serviceProvider.notifier).fetchServices();
    });
  }

  double get _totalPrice => _items.fold(0.0, (sum, item) => sum + item.subtotal);

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

  Future<void> _pickEstimatedDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 2)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primary,
            surface: AppColors.surface,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: const TimeOfDay(hour: 12, minute: 0),
        builder: (ctx, child) => Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              surface: AppColors.surface,
            ),
          ),
          child: child!,
        ),
      );
      if (time != null && mounted) {
        setState(() {
          _estimatedReady =
              DateTime(picked.year, picked.month, picked.day, time.hour, time.minute);
        });
      }
    }
  }

  Future<void> _submit() async {
    if (_selectedCustomer == null) {
      _snack('Pilih pelanggan terlebih dahulu', isError: true);
      return;
    }
    if (_items.any((i) => i.service == null)) {
      _snack('Pilih layanan untuk semua item', isError: true);
      return;
    }
    if (_totalPrice <= 0) {
      _snack('Total harga harus lebih dari 0', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);

    final details = _items.map((item) {
      final Map<String, dynamic> d = {'service_id': item.service!.id};
      if (item.service!.unit == 'kg') {
        d['weight'] = item.weight;
      } else {
        d['qty'] = item.qty;
      }
      return d;
    }).toList();

    try {
      await ref.read(orderProvider.notifier).createOrder(
            _selectedCustomer!.id,
            details,
            paymentStatus: _paymentStatus,
            deliveryType: _deliveryType,
            serviceType: _serviceType,
            perfumeType: _perfumeType,
            clothNotes: _clothNotes.trim().isEmpty ? null : _clothNotes.trim(),
            estimatedReady: _estimatedReady,
          );
      if (mounted) {
        _snack('Order berhasil dibuat!');
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
    final customersAsync = ref.watch(customerProvider);
    final servicesAsync = ref.watch(serviceProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Buat Order Baru',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textDark,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── PELANGGAN ────────────────────────────────────────────
            _sectionTitle('PELANGGAN'),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: _cardDeco(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_selectedCustomer != null)
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor:
                              AppColors.primary.withValues(alpha: 0.15),
                          child: Text(
                            _selectedCustomer!.name[0].toUpperCase(),
                            style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_selectedCustomer!.name,
                                  style: const TextStyle(
                                      color: AppColors.textDark,
                                      fontWeight: FontWeight.bold)),
                              Text(_selectedCustomer!.phone,
                                  style: const TextStyle(
                                      color: AppColors.textMid, fontSize: 12)),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: AppColors.textMid),
                          onPressed: () =>
                              setState(() => _selectedCustomer = null),
                        ),
                      ],
                    )
                  else ...[
                    TextField(
                      style: const TextStyle(color: AppColors.textDark),
                      decoration: _inputDeco('Cari pelanggan (nama / no HP)...')
                          .copyWith(
                              prefixIcon:
                                  const Icon(Icons.search_rounded, color: AppColors.textMid)),
                      onChanged: (v) {
                        setState(() => _customerSearch = v);
                        ref
                            .read(customerProvider.notifier)
                            .fetchCustomers(query: v.isEmpty ? null : v);
                      },
                    ),
                    const SizedBox(height: 8),
                    customersAsync.when(
                      loading: () => const SizedBox(
                          height: 40,
                          child: Center(
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation(
                                      AppColors.primary)))),
                      error: (_, __) => const SizedBox(),
                      data: (customers) => Column(
                        children: customers
                            .take(5)
                            .map((c) => InkWell(
                                  onTap: () => setState(() {
                                    _selectedCustomer = c;
                                    _customerSearch = '';
                                  }),
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 6),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                        color: AppColors.surface,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: AppColors.divider)),
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 16,
                                          backgroundColor:
                                              AppColors.primary
                                                  .withValues(alpha: 0.15),
                                          child: Text(
                                            c.name[0].toUpperCase(),
                                            style: const TextStyle(
                                                color: AppColors.primary,
                                                fontSize: 12, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(c.name,
                                                style: const TextStyle(
                                                    color: AppColors.textDark,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 13)),
                                            Text(c.phone,
                                                style: const TextStyle(
                                                    color: AppColors.textMid,
                                                    fontSize: 11)),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ))
                            .toList(),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

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
            const SizedBox(height: 24),

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
            const SizedBox(height: 24),

            // ─── CATATAN BAJU ─────────────────────────────────────────
            _sectionTitle('CATATAN BAJU (OPSIONAL)'),
            TextField(
              maxLines: 3,
              style: const TextStyle(color: AppColors.textDark, fontSize: 14),
              decoration: _inputDeco(
                  'Contoh: Ada baju putih yang luntur, hati-hati jangan pakai pemutih...'),
              onChanged: (v) => _clothNotes = v,
            ),
            const SizedBox(height: 24),

            // ─── ESTIMASI SELESAI ─────────────────────────────────────
            _sectionTitle('ESTIMASI SELESAI'),
            InkWell(
              onTap: _pickEstimatedDate,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: _cardDeco(),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded,
                        color: AppColors.primary, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _estimatedReady != null
                            ? formatDateTime(_estimatedReady!)
                            : 'Ketuk untuk pilih tanggal & jam estimasi...',
                        style: TextStyle(
                          color: _estimatedReady != null
                              ? AppColors.textDark
                              : AppColors.textLight,
                          fontSize: 14,
                          fontWeight: _estimatedReady != null ? FontWeight.bold : FontWeight.normal
                        ),
                      ),
                    ),
                    if (_estimatedReady != null)
                      IconButton(
                        icon: const Icon(Icons.close_rounded,
                            color: AppColors.textMid, size: 18),
                        onPressed: () =>
                            setState(() => _estimatedReady = null),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ─── PENGIRIMAN ───────────────────────────────────────────
            _sectionTitle('PENGIRIMAN'),
            Container(
              decoration: _cardDeco(),
              child: Column(
                children: [
                  RadioListTile<String>(
                    value: 'antar_sendiri',
                    groupValue: _deliveryType,
                    title: const Text('🏪 Pelanggan Antar & Ambil Sendiri',
                        style: TextStyle(color: AppColors.textDark, fontSize: 14, fontWeight: FontWeight.w600)),
                    activeColor: AppColors.primary,
                    onChanged: (v) => setState(() => _deliveryType = v!),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                  ),
                  const Divider(color: AppColors.divider, height: 1),
                  RadioListTile<String>(
                    value: 'minta_dijemput',
                    groupValue: _deliveryType,
                    title: const Text('🛵 Antar/Jemput ke Lokasi Pelanggan',
                        style: TextStyle(color: AppColors.textDark, fontSize: 14, fontWeight: FontWeight.w600)),
                    activeColor: AppColors.primary,
                    onChanged: (v) => setState(() => _deliveryType = v!),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ─── ITEM LAUNDRY ─────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _sectionTitle('ITEM LAUNDRY'),
                TextButton.icon(
                  onPressed: () => setState(() => _items.add(_OrderItem())),
                  icon: const Icon(Icons.add_rounded, size: 18, color: AppColors.primary),
                  label: const Text('Tambah Item', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            servicesAsync.when(
              loading: () => const SizedBox(
                  height: 60,
                  child: Center(
                      child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation(AppColors.primary)))),
              error: (_, __) => const SizedBox(),
              data: (services) => Column(
                children: List.generate(_items.length, (i) {
                  final item = _items[i];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: _cardDeco(),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<ServiceModel>(
                                  value: item.service,
                                  hint: const Text('Pilih layanan...',
                                      style: TextStyle(
                                          color: AppColors.textLight, fontSize: 14)),
                                  dropdownColor: AppColors.surface,
                                  isExpanded: true,
                                  style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w600),
                                  icon: const Icon(Icons.expand_more_rounded, color: AppColors.textMid),
                                  items: services
                                      .map((s) => DropdownMenuItem(
                                          value: s,
                                          child: Text(
                                              '${s.serviceName} - ${formatCurrency(s.price)}/${s.unit}',
                                              style:
                                                  const TextStyle(fontSize: 13))))
                                      .toList(),
                                  onChanged: (s) => setState(() {
                                    item.service = s;
                                    item.weight = 0;
                                    item.qty = 1;
                                  }),
                                ),
                              ),
                            ),
                            if (_items.length > 1)
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline_rounded,
                                    color: AppColors.danger, size: 22),
                                onPressed: () =>
                                    setState(() => _items.removeAt(i)),
                              ),
                          ],
                        ),
                        if (item.service != null) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: item.service!.unit == 'kg'
                                    ? TextFormField(
                                        initialValue: item.weight == 0
                                            ? ''
                                            : item.weight.toString(),
                                        keyboardType:
                                            const TextInputType.numberWithOptions(
                                                decimal: true),
                                        style: const TextStyle(
                                            color: AppColors.textDark, fontWeight: FontWeight.w600),
                                        decoration: _inputDeco('Berat')
                                            .copyWith(
                                                suffixText: 'kg',
                                                suffixStyle: const TextStyle(
                                                    color: AppColors.textMid, fontWeight: FontWeight.bold)),
                                        onChanged: (v) => setState(
                                            () => item.weight =
                                                double.tryParse(v) ?? 0),
                                      )
                                    : TextFormField(
                                        initialValue: item.qty.toString(),
                                        keyboardType: TextInputType.number,
                                        style: const TextStyle(
                                            color: AppColors.textDark, fontWeight: FontWeight.w600),
                                        decoration: _inputDeco('Jumlah')
                                            .copyWith(
                                                suffixText: item.service!.unit,
                                                suffixStyle: const TextStyle(
                                                    color: AppColors.textMid, fontWeight: FontWeight.bold)),
                                        onChanged: (v) => setState(() =>
                                            item.qty = int.tryParse(v) ?? 1),
                                      ),
                              ),
                              const SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text('Subtotal',
                                      style: TextStyle(
                                          color: AppColors.textMid, fontSize: 11)),
                                  Text(formatCurrency(item.subtotal),
                                      style: const TextStyle(
                                          color: AppColors.success,
                                          fontWeight: FontWeight.bold, fontSize: 15)),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 24),

            // ─── STATUS PEMBAYARAN ────────────────────────────────────
            _sectionTitle('STATUS PEMBAYARAN AWAL'),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: _cardDeco(),
              child: Row(
                children: [
                  Expanded(
                    child: RadioListTile<String>(
                      value: 'belum_lunas',
                      groupValue: _paymentStatus,
                      title: const Text('Belum Lunas',
                          style:
                              TextStyle(color: AppColors.textDark, fontSize: 13, fontWeight: FontWeight.w600)),
                      activeColor: AppColors.warning,
                      onChanged: (v) =>
                          setState(() => _paymentStatus = v!),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      value: 'lunas',
                      groupValue: _paymentStatus,
                      title: const Text('Lunas',
                          style:
                              TextStyle(color: AppColors.textDark, fontSize: 13, fontWeight: FontWeight.w600)),
                      activeColor: AppColors.success,
                      onChanged: (v) =>
                          setState(() => _paymentStatus = v!),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // ─── TOTAL ────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [AppColors.primary, Color(0xFF60A5FA)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('TOTAL HARGA',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0)),
                  Text(formatCurrency(_totalPrice),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _submit,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white)))
                  : const Icon(Icons.check_circle_outline_rounded),
              label: Text(_isSubmitting ? 'Menyimpan...' : 'Buat Order',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 4,
                  shadowColor: AppColors.primary.withValues(alpha: 0.4),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16))),
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
              color: isSelected ? color.withValues(alpha: 0.1) : AppColors.surface,
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

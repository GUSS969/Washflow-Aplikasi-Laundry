import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/shared_widgets.dart';
import '../../../../features/order/presentation/providers/order_provider.dart';
import '../../../../features/order/data/models/order_model.dart';
import '../../../../features/pelanggan/presentation/screens/pelanggan_payment_screen.dart';
import '../../../../core/constants/constants.dart';
import 'package:dio/dio.dart';

class OrderDetailScreen extends ConsumerStatefulWidget {
  final OrderModel order;
  final bool isReadOnly;
  const OrderDetailScreen(
      {super.key, required this.order, this.isReadOnly = false});

  @override
  ConsumerState<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends ConsumerState<OrderDetailScreen> {
  late OrderModel _order;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _order = widget.order;
  }

  final List<String> _statusFlow = [
    'menunggu_konfirmasi',
    'diterima',
    'dicuci',
    'dikeringkan',
    'disetrika',
    'selesai',
    'sudah_diambil'
  ];

  String _serviceTypeLabel(String t) => switch (t) {
        'cuci_saja' => '🧺 Cuci Saja',
        'setrika_saja' => '👔 Setrika Saja',
        _ => '🫧 Cuci + Setrika',
      };

  String _perfumeLabel(String p) => switch (p) {
        'tanpa_parfum' => '🚫 Tanpa Parfum',
        'antibakteri' => '🛡️ Antibakteri',
        'lavender' => '💜 Lavender',
        'floral' => '🌺 Floral',
        'sport' => '⚡ Sport',
        _ => '🌸 Reguler',
      };

  String _deliveryLabel(String? d) => switch (d) {
        'minta_dijemput' => '🛵 Antar/Jemput Kurir',
        _ => '🏪 Ambil Sendiri',
      };

  void _showPaymentSheet() {
    String selectedMethod = 'cash';
    final double remainingBalance = _order.totalPrice - _order.totalPaid;
    final amountCtrl = TextEditingController(text: remainingBalance.toStringAsFixed(0));
    final notesCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setModal) => Padding(
          padding: EdgeInsets.fromLTRB(
              24, 20, 24, MediaQuery.of(ctx2).viewInsets.bottom + 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                        color: AppColors.divider,
                        borderRadius: BorderRadius.circular(3)),
                  ),
                ),
                const Text('Proses Pembayaran',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textDark)),
                const SizedBox(height: 4),
                Text('Order: ${_order.invoice}',
                    style:
                        const TextStyle(color: AppColors.textMid, fontSize: 13)),
                const SizedBox(height: 24),

                // Total tagihan
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [AppColors.primary, Color(0xFF60A5FA)]),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Tagihan',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600)),
                      Text(formatCurrency(_order.totalPrice),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                const Text('METODE PEMBAYARAN',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textMid,
                        letterSpacing: 0.5)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _payMethodChip('cash', 'Cash', '💵', selectedMethod,
                        (v) => setModal(() => selectedMethod = v)),
                    const SizedBox(width: 8),
                    _payMethodChip('qris', 'QRIS', '📲', selectedMethod,
                        (v) => setModal(() => selectedMethod = v)),
                    const SizedBox(width: 8),
                    _payMethodChip('transfer', 'Transfer', '🏦', selectedMethod,
                        (v) => setModal(() => selectedMethod = v)),
                    const SizedBox(width: 8),
                    _payMethodChip('ewallet', 'E-Wallet', '💳', selectedMethod,
                        (v) => setModal(() => selectedMethod = v)),
                  ],
                ),
                const SizedBox(height: 20),

                // Info sesuai metode
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: _paymentMethodInfo(selectedMethod),
                ),
                const SizedBox(height: 20),

                const Text('JUMLAH BAYAR',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textMid,
                        letterSpacing: 0.5)),
                const SizedBox(height: 12),
                TextFormField(
                  controller: amountCtrl,
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
                    fillColor: AppColors.background,
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
                const SizedBox(height: 16),
                TextField(
                  controller: notesCtrl,
                  style:
                      const TextStyle(color: AppColors.textDark, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Catatan pembayaran (opsional)...',
                    hintStyle: const TextStyle(color: AppColors.textLight),
                    filled: true,
                    fillColor: AppColors.background,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.divider)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.divider)),
                  ),
                ),
                const SizedBox(height: 28),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    setState(() => _isUpdating = true);
                    try {
                      final amount = double.tryParse(amountCtrl.text) ?? remainingBalance;
                      await ref.read(orderProvider.notifier).payOrder(
                            _order.id,
                            selectedMethod,
                            amount,
                            notes: notesCtrl.text.trim().isEmpty
                                ? null
                                : notesCtrl.text.trim(),
                          );
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Pembayaran berhasil dikonfirmasi!', style: TextStyle(fontWeight: FontWeight.bold)),
                            backgroundColor: AppColors.success,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        );
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
                          behavior: SnackBarBehavior.floating,
                        ));
                      }
                    } finally {
                      if (mounted) setState(() => _isUpdating = false);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(56),
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shadowColor: AppColors.primary.withValues(alpha: 0.4),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16))),
                  child: const Text('Bayar Tagihan',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _paymentMethodInfo(String method) {
    switch (method) {
      case 'cash':
        return Container(
          key: const ValueKey('cash'),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: AppColors.success.withValues(alpha: 0.3)),
          ),
          child: const Text(
            '💵 Pelanggan membayar tunai di toko saat mengambil cucian. Kasir konfirmasi setelah menerima uang.',
            style: TextStyle(color: AppColors.success, fontSize: 13, height: 1.5, fontWeight: FontWeight.w600),
          ),
        );
      case 'qris':
        return Container(
          key: const ValueKey('qris'),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3)),
          ),
          child: const Text(
            '📲 Tunjukkan QR Code toko kepada pelanggan untuk discan. Setelah pembayaran berhasil, konfirmasi di sini.',
            style: TextStyle(color: AppColors.primary, fontSize: 13, height: 1.5, fontWeight: FontWeight.w600),
          ),
        );
      case 'transfer':
        return Container(
          key: const ValueKey('transfer'),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: AppColors.warning.withValues(alpha: 0.3)),
          ),
          child: const Text(
            '🏦 Informasikan rekening toko kepada pelanggan. Setelah pelanggan transfer & bukti diterima, konfirmasi di sini.',
            style: TextStyle(
                color: AppColors.warning, fontSize: 13, height: 1.5, fontWeight: FontWeight.w600),
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _payMethodChip(String value, String label, String emoji,
      String selected, Function(String) onTap) {
    final isSelected = value == selected;
    final colors = {
      'cash': AppColors.success,
      'qris': AppColors.primary,
      'transfer': AppColors.warning,
      'ewallet': AppColors.info,
    };
    final color = colors[value]!;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.1) : AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: isSelected ? color : AppColors.divider, width: isSelected ? 2 : 1),
            boxShadow: isSelected ? [] : [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0,2))],
          ),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(height: 8),
              Text(label,
                  style: TextStyle(
                      color: isSelected ? color : AppColors.textMid,
                      fontSize: 12,
                      fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmOrderWithEstimation() async {
    final ctx = context;
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: ctx,
      initialDate: now.add(const Duration(days: 3)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
      locale: const Locale('id', 'ID'),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: Colors.white,
            onSurface: AppColors.textDark,
          ),
        ),
        child: child!,
      ),
    );

    if (pickedDate != null && mounted) {
      final pickedTime = await showTimePicker(
        context: ctx,
        initialTime: const TimeOfDay(hour: 10, minute: 0),
        builder: (context, child) => Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textDark,
            ),
          ),
          child: child!,
        ),
      );

      if (pickedTime != null) {
        final estimatedReady = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        final messenger = ScaffoldMessenger.of(context);
        setState(() => _isUpdating = true);
        try {
          await ref.read(orderProvider.notifier).updateOrder(
                _order.id,
                status: 'diterima',
                estimatedReady: estimatedReady,
              );
          setState(() {
            _order = OrderModel(
              id: _order.id,
              invoice: _order.invoice,
              customerId: _order.customerId,
              customer: _order.customer,
              userId: _order.userId,
              user: _order.user,
              status: 'diterima',
              paymentStatus: _order.paymentStatus,
              deliveryType: _order.deliveryType,
              serviceType: _order.serviceType,
              perfumeType: _order.perfumeType,
              estimatedReady: estimatedReady,
              clothNotes: _order.clothNotes,
              totalPrice: _order.totalPrice,
              totalPaid: _order.totalPaid,
              createdAt: _order.createdAt,
              orderDetails: _order.orderDetails,
              payments: _order.payments,
            );
          });
          if (mounted) {
            messenger.showSnackBar(SnackBar(
              content: const Text('Pesanan dikonfirmasi dengan estimasi!'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ));
          }
        } catch (e) {
          if (mounted) {
            String errorMessage = e.toString();
            if (e is DioException) {
              errorMessage = e.response?.data?['message'] ?? e.response?.data?['error'] ?? e.message ?? errorMessage;
            }
            messenger.showSnackBar(SnackBar(
              content: Text('Gagal: $errorMessage'),
              backgroundColor: AppColors.danger,
              behavior: SnackBarBehavior.floating,
            ));
          }
        } finally {
          if (mounted) setState(() => _isUpdating = false);
        }
      }
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    setState(() => _isUpdating = true);
    try {
      await ref.read(orderProvider.notifier).updateOrderStatus(_order.id, newStatus);
      setState(() {
        _order = OrderModel(
          id: _order.id,
          invoice: _order.invoice,
          customerId: _order.customerId,
          customer: _order.customer,
          userId: _order.userId,
          user: _order.user,
          status: newStatus,
          paymentStatus: _order.paymentStatus,
          deliveryType: _order.deliveryType,
          serviceType: _order.serviceType,
          perfumeType: _order.perfumeType,
          clothNotes: _order.clothNotes,
          estimatedReady: _order.estimatedReady,
          notes: _order.notes,
          totalPrice: _order.totalPrice,
          totalPaid: _order.totalPaid,
          createdAt: _order.createdAt,
          orderDetails: _order.orderDetails,
          payments: _order.payments,
        );
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Status diperbarui: ${getStatusLabel(newStatus)}', style: const TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = e.toString();
        if (e is DioException) {
          final data = e.response?.data;
          if (data is Map) {
            errorMessage = data['message'] ?? data['error'] ?? e.message ?? errorMessage;
          } else {
            errorMessage = e.message ?? errorMessage;
          }
        }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Gagal: $errorMessage'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentIdx = _statusFlow.indexOf(_order.status);
    final nextStatus = currentIdx < _statusFlow.length - 1
        ? _statusFlow[currentIdx + 1]
        : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GradientAppBar(
        title: _order.invoice,
        subtitle: formatDate(_order.createdAt),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── PELANGGAN ────────────────────────────────────────
            _section(
              'PELANGGAN',
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor:
                        AppColors.primary.withValues(alpha: 0.15),
                    child: Text(
                      (_order.customer?.name ?? 'P')[0].toUpperCase(),
                      style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w900,
                          fontSize: 20),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_order.customer?.name ?? 'Pelanggan',
                            style: const TextStyle(
                                color: AppColors.textDark,
                                fontWeight: FontWeight.bold,
                                fontSize: 16)),
                        const SizedBox(height: 2),
                        Text(_order.customer?.phone ?? '-',
                            style: const TextStyle(
                                color: AppColors.textMid, fontSize: 13, fontWeight: FontWeight.w500)),
                        if (_order.customer?.address != null &&
                            _order.customer!.address!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(_order.customer!.address!,
                                style: const TextStyle(
                                    color: AppColors.textLight, fontSize: 12)),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ─── INFO ORDER ───────────────────────────────────────
            _section(
              'DETAIL PESANAN',
              child: Column(
                children: [
                  _infoRow('Jenis Layanan',
                      _serviceTypeLabel(_order.serviceType)),
                  const SizedBox(height: 12),
                  _infoRow('Parfum', _perfumeLabel(_order.perfumeType)),
                  const SizedBox(height: 12),
                  _infoRow('Pengiriman',
                      _deliveryLabel(_order.deliveryType)),
                  if (_order.estimatedReady != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Estimasi Ambil',
                            style: const TextStyle(color: AppColors.textMid, fontSize: 13, fontWeight: FontWeight.w500)),
                        const Spacer(),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              DateFormat('EEEE, dd MMM yyyy', 'id_ID').format(_order.estimatedReady!),
                              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            Text(
                              DateFormat('HH:mm', 'id_ID').format(_order.estimatedReady!),
                              style: const TextStyle(color: AppColors.textMid, fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                  if (_order.clothNotes != null &&
                      _order.clothNotes!.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Divider(color: AppColors.divider, height: 1),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.sticky_note_2_outlined,
                            color: AppColors.warning, size: 18),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _order.clothNotes!,
                            style: const TextStyle(
                                color: AppColors.warning,
                                fontSize: 13,
                                height: 1.5, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (_order.notes != null &&
                      _order.notes!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline_rounded,
                            color: AppColors.textMid, size: 18),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _order.notes!,
                            style: const TextStyle(
                                color: AppColors.textMid, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ─── STATUS TIMELINE ──────────────────────────────────
            _section(
              'STATUS CUCIAN',
              child: Column(
                children: List.generate(_statusFlow.length, (i) {
                  final s = _statusFlow[i];
                  final isDone = i <= currentIdx;
                  final isCurrent = i == currentIdx;
                  final isLast = i == _statusFlow.length - 1;
                  final color =
                      isDone ? getStatusColor(s) : AppColors.divider;
                  return Row(
                    children: [
                      Column(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isDone
                                  ? color.withValues(alpha: 0.1)
                                  : AppColors.background,
                              border: Border.all(
                                  color: color,
                                  width: isCurrent ? 2.5 : (isDone ? 1.5 : 1)),
                            ),
                            child:
                                Icon(getStatusIcon(s), color: isDone ? color : AppColors.textLight, size: 18),
                          ),
                          if (!isLast)
                            Container(
                                width: 2,
                                height: 28,
                                color: isDone
                                    ? color.withValues(alpha: 0.3)
                                    : AppColors.divider),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 28),
                          child: Text(
                            getStatusLabel(s),
                            style: TextStyle(
                              color: isCurrent
                                  ? color
                                  : (isDone
                                      ? AppColors.textDark
                                      : AppColors.textLight),
                              fontWeight: isCurrent
                                  ? FontWeight.w800
                                  : (isDone ? FontWeight.w600 : FontWeight.normal),
                              fontSize: isCurrent ? 15 : 14,
                            ),
                          ),
                        ),
                      ),
                      if (isCurrent)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: color.withValues(alpha: 0.3))),
                          child: Text('Sekarang',
                              style: TextStyle(
                                  color: color,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800)),
                        ),
                    ],
                  );
                }),
              ),
            ),
            const SizedBox(height: 20),

            // ─── ITEM LAUNDRY ─────────────────────────────────────
            _section(
              'ITEM LAUNDRY',
              child: Column(
                children: [
                  ..._order.orderDetails.map((d) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      d.service?.serviceName ?? 'Layanan',
                                      style: const TextStyle(
                                          color: AppColors.textDark,
                                          fontWeight: FontWeight.bold, fontSize: 14)),
                                  const SizedBox(height: 2),
                                  Text(
                                    d.weight != null
                                        ? '${d.weight} kg × ${formatCurrency(d.service?.price ?? 0)}/kg'
                                        : '${d.qty ?? 1} ${d.service?.unit ?? 'item'} × ${formatCurrency(d.service?.price ?? 0)}',
                                    style: const TextStyle(
                                        color: AppColors.textMid, fontSize: 12, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                            Text(formatCurrency(d.subtotal),
                                style: const TextStyle(
                                    color: AppColors.success,
                                    fontWeight: FontWeight.bold, fontSize: 15)),
                          ],
                        ),
                      )),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Divider(color: AppColors.divider, thickness: 1),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('TOTAL',
                          style: TextStyle(
                              color: AppColors.textDark,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.0, fontSize: 13)),
                      Text(formatCurrency(_order.totalPrice),
                          style: const TextStyle(
                              color: AppColors.success,
                              fontSize: 18,
                              fontWeight: FontWeight.w900)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ─── PEMBAYARAN ───────────────────────────────────────
            _section(
              'PEMBAYARAN',
              child: _order.payments.isNotEmpty
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final payment in _order.payments) ...[
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                    color: payment.status == 'pending'
                                        ? AppColors.warning.withValues(alpha: 0.1)
                                        : AppColors.success.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12)),
                                child: Icon(
                                    payment.status == 'pending'
                                        ? Icons.hourglass_empty_rounded
                                        : Icons.check_circle_rounded,
                                    color: payment.status == 'pending'
                                        ? AppColors.warning
                                        : AppColors.success, size: 28),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                        payment.status == 'pending'
                                            ? 'Menunggu Konfirmasi (${payment.method.toUpperCase()})'
                                            : 'Berhasil via ${payment.method.toUpperCase()}',
                                        style: const TextStyle(
                                            color: AppColors.textDark,
                                            fontWeight: FontWeight.bold, fontSize: 14)),
                                    const SizedBox(height: 2),
                                    Text(
                                        formatDateTime(payment.paymentDate),
                                        style: const TextStyle(
                                            color: AppColors.textMid,
                                            fontSize: 12)),
                                    const SizedBox(height: 2),
                                    Text(formatCurrency(payment.amount),
                                        style: const TextStyle(
                                            color: AppColors.success,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 14)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (payment.paymentProofUrl != null) ...[
                            const SizedBox(height: 16),
                            const Text('Bukti Transfer / Pembayaran:', style: TextStyle(color: AppColors.textMid, fontSize: 12, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 10),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                '${AppConstants.baseUrl.replaceAll('/api', '')}${payment.paymentProofUrl}',
                                height: 200,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (c, e, s) => Container(
                                  height: 120,
                                  color: AppColors.background,
                                  child: const Center(child: Icon(Icons.broken_image_rounded, color: AppColors.textLight, size: 40)),
                                ),
                              ),
                            ),
                          ],
                          if (payment.paymentNotes != null &&
                              payment.paymentNotes!.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Text(
                              'Catatan: ${payment.paymentNotes}',
                              style: const TextStyle(
                                  color: AppColors.textMid, fontSize: 13, fontStyle: FontStyle.italic),
                            ),
                          ],
                          if (!widget.isReadOnly && payment.status == 'pending') ...[
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () async {
                                final messenger = ScaffoldMessenger.of(context);
                                setState(() => _isUpdating = true);
                                try {
                                  await ref.read(orderProvider.notifier).confirmPayment(payment.id);
                                  if (mounted) {
                                    messenger.showSnackBar(SnackBar(
                                      content: const Text('Pembayaran berhasil dikonfirmasi!', style: TextStyle(fontWeight: FontWeight.bold)),
                                      backgroundColor: AppColors.success,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      behavior: SnackBarBehavior.floating,
                                    ));
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    messenger.showSnackBar(SnackBar(
                                      content: Text('Gagal konfirmasi: $e'),
                                      backgroundColor: AppColors.danger,
                                      behavior: SnackBarBehavior.floating,
                                    ));
                                  }
                                } finally {
                                  if (mounted) setState(() => _isUpdating = false);
                                }
                              },
                              icon: const Icon(Icons.verified_rounded),
                              label: const Text('Validasi & Konfirmasi Lunas',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size.fromHeight(56),
                                backgroundColor: AppColors.success,
                                foregroundColor: Colors.white,
                                elevation: 4,
                                shadowColor: AppColors.success.withValues(alpha: 0.4),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16)),
                              ),
                            ),
                          ],
                          const SizedBox(height: 24),
                        ],
                      ],
                    )
                  : widget.isReadOnly
                      ? _belumBayarPelangganInfo()
                      : Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                  color: AppColors.warning.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12)),
                              child: const Icon(Icons.pending_actions_rounded,
                                  color: AppColors.warning, size: 28),
                            ),
                            const SizedBox(width: 16),
                            const Text('Belum dibayar',
                                style: TextStyle(
                                    color: AppColors.warning,
                                    fontWeight: FontWeight.w800, fontSize: 15)),
                          ],
                        ),
            ),
            const SizedBox(height: 28),

            // ─── ACTION BUTTONS (PELANGGAN) ───────────────────────────────────
            if (widget.isReadOnly) ...[
              if (_order.paymentStatus != 'lunas')
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PelangganPaymentScreen(order: _order),
                      ),
                    ).then((_) => ref.read(orderProvider.notifier).fetchOrders());
                  },
                  icon: const Icon(Icons.payments_rounded),
                  label: const Text('Bayar Sekarang', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shadowColor: AppColors.primary.withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                )
              else if (_order.paymentStatus == 'belum_lunas' && _order.payments.any((p) => p.status == 'pending'))
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.hourglass_empty_rounded, color: AppColors.warning),
                      SizedBox(width: 12),
                      Text('Menunggu Konfirmasi Kasir', style: TextStyle(color: AppColors.warning, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
            ],

            // ─── ACTION BUTTONS (KASIR) ───────────────────────────────────
            if (!widget.isReadOnly) ...[
              if (nextStatus != null) ...[
                // Tombol khusus konfirmasi jika status menunggu
                if (_order.status == 'menunggu_konfirmasi')
                  ElevatedButton.icon(
                    onPressed: _isUpdating ? null : _confirmOrderWithEstimation,
                    icon: _isUpdating
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(Colors.white)))
                        : const Icon(Icons.check_circle_rounded),
                    label: const Text('✅ Konfirmasi & Terima Pesanan',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(56),
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shadowColor: AppColors.success.withValues(alpha: 0.4),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                  )
                else
                  ElevatedButton.icon(
                    onPressed: _isUpdating
                        ? null
                        : () => _updateStatus(nextStatus),
                    icon: _isUpdating
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation(Colors.white)))
                        : Icon(getStatusIcon(nextStatus)),
                    label: Text('Tandai: ${getStatusLabel(nextStatus)}',
                        style:
                            const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(56),
                      backgroundColor: getStatusColor(nextStatus),
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shadowColor: getStatusColor(nextStatus).withValues(alpha: 0.4),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
              ],
              if (_order.paymentStatus != 'lunas') ...[
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _isUpdating ? null : _showPaymentSheet,
                  icon: const Icon(Icons.payments_outlined,
                      color: AppColors.success),
                  label: const Text('Input Pembayaran',
                      style: TextStyle(
                          color: AppColors.success,
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                    side: const BorderSide(color: AppColors.success, width: 2),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ],
              const SizedBox(height: 40),
            ],
          ],
        ),
      ),
    );
  }

  Widget _belumBayarPelangganInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: AppColors.warning.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tagihan: ${formatCurrency(_order.totalPrice)}',
                style: const TextStyle(
                    color: AppColors.warning,
                    fontWeight: FontWeight.w900,
                    fontSize: 18),
              ),
              const SizedBox(height: 12),
              const Text(
                'Cara membayar:\n'
                '• 💵 Cash: Bayar saat ambil cucian di toko\n'
                '• 📲 QRIS: Kasir tunjukkan QR untuk di-scan\n'
                '• 🏦 Transfer: Hubungi Admin untuk no rekening\n'
                '• 💳 E-Wallet: Hubungi Admin untuk info e-wallet',
                style: TextStyle(
                    color: AppColors.textMid, fontSize: 13, height: 1.7, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style:
                const TextStyle(color: AppColors.textMid, fontSize: 13, fontWeight: FontWeight.w500)),
        Text(value,
            style: TextStyle(
                color: valueColor ?? AppColors.textDark,
                fontWeight: FontWeight.bold,
                fontSize: 13)),
      ],
    );
  }

  Widget _section(String title, {required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.textMid,
                letterSpacing: 0.5)),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: child,
        ),
      ],
    );
  }
}

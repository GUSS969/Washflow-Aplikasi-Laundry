import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/shared_widgets.dart';
import '../../../../features/service/presentation/providers/service_provider.dart';
import '../../../../features/service/data/models/service_model.dart';

class ServicesTab extends ConsumerStatefulWidget {
  const ServicesTab({super.key});
  @override
  ConsumerState<ServicesTab> createState() => _ServicesTabState();
}

class _ServicesTabState extends ConsumerState<ServicesTab> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(serviceProvider.notifier).fetchServices());
  }

  void _showServiceDialog({ServiceModel? existing}) {
    final nameCtrl = TextEditingController(text: existing?.serviceName);
    final priceCtrl = TextEditingController(text: existing != null ? existing.price.toStringAsFixed(0) : '');
    String selectedUnit = existing?.unit ?? 'kg';
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx2).viewInsets.bottom + 24),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 16),
                Text(existing == null ? 'Tambah Layanan' : 'Edit Layanan',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                const SizedBox(height: 20),
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nama Layanan', prefixIcon: Icon(Icons.local_laundry_service_outlined, size: 20)),
                  validator: (v) => v == null || v.isEmpty ? 'Nama layanan wajib diisi' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: priceCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Harga (Rp)', prefixIcon: Icon(Icons.payments_outlined, size: 20)),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Harga wajib diisi';
                    if (double.tryParse(v) == null) return 'Masukkan angka yang valid';
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                const Text('SATUAN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textMid, letterSpacing: 0.5)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedUnit,
                      dropdownColor: AppColors.surface,
                      style: const TextStyle(color: AppColors.textDark, fontSize: 14),
                      icon: const Icon(Icons.arrow_drop_down, color: AppColors.textMid),
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(value: 'kg', child: Text('Kg (Kilogram)')),
                        DropdownMenuItem(value: 'item', child: Text('Item (Satuan)')),
                        DropdownMenuItem(value: 'pasang', child: Text('Pasang (Pairs)')),
                      ],
                      onChanged: (v) { if (v != null) setModalState(() => selectedUnit = v); },
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      Navigator.pop(ctx);
                      try {
                        if (existing == null) {
                          await ref.read(serviceProvider.notifier).addService(nameCtrl.text.trim(), double.parse(priceCtrl.text), selectedUnit);
                        } else {
                          await ref.read(serviceProvider.notifier).updateService(existing.id, nameCtrl.text.trim(), double.parse(priceCtrl.text), selectedUnit);
                        }
                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(existing == null ? 'Layanan berhasil ditambahkan' : 'Layanan diperbarui'),
                          backgroundColor: AppColors.success,
                        ));
                      } catch (e) {
                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.danger));
                      }
                    },
                    child: Text(existing == null ? 'Tambah Layanan' : 'Simpan Perubahan'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(ServiceModel s) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Hapus Layanan?', style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w800)),
        content: Text('Hapus "${s.serviceName}"?', style: const TextStyle(color: AppColors.textMid)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger, minimumSize: const Size(0, 40)), onPressed: () => Navigator.pop(ctx, true), child: const Text('Hapus')),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await ref.read(serviceProvider.notifier).deleteService(s.id);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Layanan dihapus'), backgroundColor: AppColors.success));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e'), backgroundColor: AppColors.danger));
      }
    }
  }

  static const Map<String, String> _unitLabels = {'kg': 'Kiloan', 'item': 'Satuan', 'meter': 'Meter', 'pasang': 'Pasang'};
  static const Map<String, IconData> _unitIcons = {'kg': Icons.scale, 'item': Icons.checkroom, 'meter': Icons.straighten, 'pasang': Icons.sports_handball};
  static const Map<String, Color> _unitColors = {'kg': AppColors.primary, 'item': Color(0xFF9C27B0), 'meter': AppColors.info, 'pasang': AppColors.warning};

  @override
  Widget build(BuildContext context) {
    final servicesAsync = ref.watch(serviceProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: servicesAsync.when(
        loading: () => const LoadingWidget(),
        error: (e, _) => ErrorWidget2(message: 'Gagal memuat layanan', onRetry: () => ref.read(serviceProvider.notifier).fetchServices()),
        data: (services) {
          if (services.isEmpty) return const EmptyState(icon: Icons.local_laundry_service_outlined, title: 'Belum Ada Layanan', subtitle: 'Tambah layanan laundry yang tersedia.');

          // Group by unit
          final grouped = <String, List<ServiceModel>>{};
          for (final s in services) {
            grouped.putIfAbsent(s.unit, () => []).add(s);
          }

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () => ref.read(serviceProvider.notifier).fetchServices(),
            child: ListView(
              padding: const EdgeInsets.only(top: 8, bottom: 80),
              children: grouped.entries.map((entry) {
                final unit = entry.key;
                final list = entry.value;
                final color = _unitColors[unit] ?? AppColors.primary;
                final unitLabel = _unitLabels[unit] ?? unit;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Group header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                      child: Row(
                        children: [
                          Icon(_unitIcons[unit] ?? Icons.category, color: color, size: 16),
                          const SizedBox(width: 6),
                          Text(unitLabel, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
                        ],
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.divider),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
                        ],
                      ),
                      child: Column(
                        children: list.map((s) {
                          return Column(
                            children: [
                              ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                leading: Container(
                                  width: 42, height: 42,
                                  decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                                  child: Icon(_unitIcons[s.unit] ?? Icons.category, color: color, size: 20),
                                ),
                                title: Text(s.serviceName, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark, fontSize: 13)),
                                subtitle: Text(formatCurrency(s.price), style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13)),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(alpha: 0.08),
                                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text('Edit', style: TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w700)),
                                    ),
                                    const SizedBox(width: 8),
                                    GestureDetector(
                                      onTap: () => _showServiceDialog(existing: s),
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(color: AppColors.surfaceAlt, borderRadius: BorderRadius.circular(8)),
                                        child: const Icon(Icons.edit_outlined, color: AppColors.textMid, size: 18),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    GestureDetector(
                                      onTap: () => _confirmDelete(s),
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(color: AppColors.danger.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
                                        child: const Icon(Icons.delete_outline_rounded, color: AppColors.danger, size: 18),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (s != list.last) const Divider(height: 1, indent: 72, endIndent: 16),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showServiceDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Tambah Layanan'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }
}

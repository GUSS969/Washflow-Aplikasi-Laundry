import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/shared_widgets.dart';
import '../../../../features/customer/presentation/providers/customer_provider.dart';
import '../../../../features/customer/data/models/customer_model.dart';
import '../../../../core/network/api_service.dart';

class CustomersTab extends ConsumerStatefulWidget {
  const CustomersTab({super.key});
  @override
  ConsumerState<CustomersTab> createState() => _CustomersTabState();
}

class _CustomersTabState extends ConsumerState<CustomersTab> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(customerProvider.notifier).fetchCustomers());
    _searchCtrl.addListener(() {
      ref.read(customerProvider.notifier).fetchCustomers(
        query: _searchCtrl.text.isEmpty ? null : _searchCtrl.text,
      );
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _showAddEditDialog({CustomerModel? existing}) {
    final nameCtrl = TextEditingController(text: existing?.name);
    final phoneCtrl = TextEditingController(text: existing?.phone);
    final addressCtrl = TextEditingController(text: existing?.address);
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              Text(existing == null ? 'Tambah Pelanggan' : 'Edit Pelanggan',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textDark)),
              const SizedBox(height: 20),
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Nama Lengkap', prefixIcon: Icon(Icons.person_outline, size: 20)),
                validator: (v) => v == null || v.isEmpty ? 'Nama wajib diisi' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Nomor HP', prefixIcon: Icon(Icons.phone_outlined, size: 20)),
                validator: (v) => v == null || v.isEmpty ? 'Nomor HP wajib diisi' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: addressCtrl,
                decoration: const InputDecoration(labelText: 'Kota / Alamat (opsional)', prefixIcon: Icon(Icons.location_on_outlined, size: 20)),
                maxLines: 2,
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
                        await ref.read(customerProvider.notifier).addCustomer(
                          nameCtrl.text.trim(), phoneCtrl.text.trim(),
                          addressCtrl.text.trim().isEmpty ? null : addressCtrl.text.trim(),
                        );
                      } else {
                        await ref.read(customerProvider.notifier).updateCustomer(
                          existing.id, nameCtrl.text.trim(), phoneCtrl.text.trim(),
                          addressCtrl.text.trim().isEmpty ? null : addressCtrl.text.trim(),
                        );
                      }
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(existing == null ? 'Pelanggan berhasil ditambahkan' : 'Data pelanggan diperbarui'),
                          backgroundColor: AppColors.success,
                        ));
                      }
                    } catch (e) {
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${ApiService.parseError(e)}'), backgroundColor: AppColors.danger));
                    }
                  },
                  child: Text(existing == null ? 'Tambah Pelanggan' : 'Simpan Perubahan'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(CustomerModel c) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Hapus Pelanggan?', style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w800)),
        content: Text('Hapus "${c.name}"? Data tidak bisa dipulihkan.', style: const TextStyle(color: AppColors.textMid)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              minimumSize: const Size(0, 40),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await ref.read(customerProvider.notifier).deleteCustomer(c.id);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pelanggan dihapus'), backgroundColor: AppColors.success));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: ${ApiService.parseError(e)}'), backgroundColor: AppColors.danger));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(customerProvider);

    return Column(
      children: [
        // Add button + Search
        Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(bottom: BorderSide(color: AppColors.divider)),
          ),
          child: Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showAddEditDialog(),
                  icon: const Icon(Icons.person_add_rounded, size: 18),
                  label: const Text('Tambah Pelanggan', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SindrySearchBar(
                controller: _searchCtrl,
                hint: 'Cari nama atau nomor HP...',
                onChanged: (v) => ref.read(customerProvider.notifier).fetchCustomers(query: v.isEmpty ? null : v),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
        Expanded(
          child: customersAsync.when(
            loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
            error: (e, _) => ErrorWidget2(message: 'Gagal memuat data', onRetry: () => ref.read(customerProvider.notifier).fetchCustomers()),
            data: (customers) {
              if (customers.isEmpty) {
                return const EmptyState(icon: Icons.people_outline, title: 'Belum Ada Pelanggan', subtitle: 'Tambah pelanggan baru menggunakan tombol di atas.');
              }
              // Count
              return Column(
                children: [
                  Container(
                    color: AppColors.background,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    width: double.infinity,
                    child: Text('${customers.length} orang', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textMid)),
                  ),
                  Expanded(
                    child: RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: () => ref.read(customerProvider.notifier).fetchCustomers(),
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                        itemCount: customers.length,
                        itemBuilder: (ctx, i) {
                          final c = customers[i];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppColors.divider),
                                boxShadow: [
                                  BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
                                ],
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                leading: CircleAvatar(
                                  radius: 22,
                                  backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                                  child: Text(c.name[0].toUpperCase(), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 16)),
                                ),
                                title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textDark, fontSize: 14)),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 2),
                                    Row(children: [
                                      const Icon(Icons.phone_outlined, size: 12, color: AppColors.textLight),
                                      const SizedBox(width: 4),
                                      Text(c.phone, style: const TextStyle(color: AppColors.textMid, fontSize: 12)),
                                    ]),
                                    if (c.address != null && c.address!.isNotEmpty)
                                      Text(c.address!, style: const TextStyle(color: AppColors.textLight, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                                  ],
                                ),
                                trailing: PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert_rounded, color: AppColors.textMid),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  onSelected: (val) {
                                    if (val == 'edit') _showAddEditDialog(existing: c);
                                    if (val == 'delete') _confirmDelete(c);
                                  },
                                  itemBuilder: (ctx) => [
                                    const PopupMenuItem(value: 'detail', child: Row(children: [Icon(Icons.visibility_outlined, size: 16), SizedBox(width: 8), Text('Detail')])),
                                    const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_outlined, size: 16), SizedBox(width: 8), Text('Edit')])),
                                    PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outlined, size: 16, color: AppColors.danger), const SizedBox(width: 8), Text('Hapus', style: TextStyle(color: AppColors.danger))])),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

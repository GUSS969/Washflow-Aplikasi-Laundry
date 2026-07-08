import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/customer_model.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';

class CustomerNotifier extends StateNotifier<AsyncValue<List<CustomerModel>>> {
  final Ref _ref;

  CustomerNotifier(this._ref) : super(const AsyncValue.loading()) {
    fetchCustomers();
  }

  Future<void> fetchCustomers({String? query}) async {
    state = const AsyncValue.loading();
    try {
      final apiService = _ref.read(apiServiceProvider);
      final customers = await apiService.getCustomers(query: query);
      state = AsyncValue.data(customers);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addCustomer(String name, String phone, String? address) async {
    try {
      final apiService = _ref.read(apiServiceProvider);
      await apiService.createCustomer(name, phone, address);
      await fetchCustomers();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateCustomer(int id, String name, String phone, String? address) async {
    try {
      final apiService = _ref.read(apiServiceProvider);
      await apiService.updateCustomer(id, name, phone, address);
      await fetchCustomers();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteCustomer(int id) async {
    try {
      final apiService = _ref.read(apiServiceProvider);
      await apiService.deleteCustomer(id);
      await fetchCustomers();
    } catch (e) {
      rethrow;
    }
  }
}

final customerProvider = StateNotifierProvider<CustomerNotifier, AsyncValue<List<CustomerModel>>>((ref) {
  return CustomerNotifier(ref);
});

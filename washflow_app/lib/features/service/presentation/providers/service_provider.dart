import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/service_model.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';

class ServiceNotifier extends StateNotifier<AsyncValue<List<ServiceModel>>> {
  final Ref _ref;

  ServiceNotifier(this._ref) : super(const AsyncValue.loading()) {
    fetchServices();
  }

  Future<void> fetchServices() async {
    state = const AsyncValue.loading();
    try {
      final apiService = _ref.read(apiServiceProvider);
      final services = await apiService.getServices();
      state = AsyncValue.data(services);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addService(String name, double price, String unit) async {
    try {
      final apiService = _ref.read(apiServiceProvider);
      await apiService.createService(name, price, unit);
      await fetchServices();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateService(int id, String name, double price, String unit) async {
    try {
      final apiService = _ref.read(apiServiceProvider);
      await apiService.updateService(id, name, price, unit);
      await fetchServices();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteService(int id) async {
    try {
      final apiService = _ref.read(apiServiceProvider);
      await apiService.deleteService(id);
      await fetchServices();
    } catch (e) {
      rethrow;
    }
  }
}

final serviceProvider = StateNotifierProvider<ServiceNotifier, AsyncValue<List<ServiceModel>>>((ref) {
  return ServiceNotifier(ref);
});

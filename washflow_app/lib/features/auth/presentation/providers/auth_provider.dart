import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/user_model.dart';
import '../../../../core/network/api_service.dart';
import '../../../../core/storage/token_manager.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final String? errorMessage;

  AuthState({
    required this.status,
    this.user,
    this.errorMessage,
  });

  factory AuthState.initial() => AuthState(status: AuthStatus.initial);
  factory AuthState.loading() => AuthState(status: AuthStatus.loading);
  factory AuthState.authenticated(UserModel user) => AuthState(status: AuthStatus.authenticated, user: user);
  factory AuthState.unauthenticated() => AuthState(status: AuthStatus.unauthenticated);
  factory AuthState.error(String message) => AuthState(status: AuthStatus.error, errorMessage: message);
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiService _apiService;

  AuthNotifier(this._apiService) : super(AuthState.initial());

  Future<void> checkAuth() async {
    final token = await TokenManager.getToken();
    final userData = await TokenManager.getUserData();

    if (token != null && userData != null) {
      state = AuthState.authenticated(UserModel.fromJson(userData));
      // Refresh profile in background
      try {
        final profile = await _apiService.getProfile();
        state = AuthState.authenticated(profile);
      } catch (_) {
        // If refresh fails due to invalid/expired token, logout
        await logout();
      }
    } else {
      state = AuthState.unauthenticated();
    }
  }

  Future<void> login(String email, String password) async {
    state = AuthState.loading();
    try {
      final user = await _apiService.login(email, password);
      state = AuthState.authenticated(user);
    } catch (e) {
      state = AuthState.error(_parseError(e));
    }
  }

  Future<bool> register(String name, String email, String? phone, String password, String role) async {
    state = AuthState.loading();
    try {
      await _apiService.register(name, email, phone, password, role);
      state = AuthState.unauthenticated();
      return true;
    } catch (e) {
      state = AuthState.error(_parseError(e));
      return false;
    }
  }

  Future<void> logout() async {
    state = AuthState.loading();
    await _apiService.logout();
    state = AuthState.unauthenticated();
  }

  Future<void> refreshProfile() async {
    try {
      final user = await _apiService.getProfile();
      state = AuthState.authenticated(user);
    } catch (_) {}
  }

  String _parseError(dynamic error) {
    if (error is DioException) {
      if (error.response?.data != null && error.response?.data is Map) {
        final data = error.response!.data as Map<String, dynamic>;
        if (data.containsKey('message')) {
          return data['message'].toString();
        }
        if (data.containsKey('errors')) {
          final errors = data['errors'] as Map<String, dynamic>;
          if (errors.isNotEmpty) {
            return errors.values.first[0].toString();
          }
        }
      }
      return 'Koneksi gagal: ${error.message}';
    } else if (error is Exception) {
      return error.toString();
    }
    return 'Gagal melakukan otentikasi';
  }
}

final apiServiceProvider = Provider((ref) => ApiService());

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return AuthNotifier(apiService);
});

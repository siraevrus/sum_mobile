import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'auth_local_datasource.g.dart';

/// Local data source для аутентификации
abstract class AuthLocalDataSource {
  /// Сохранить токен
  Future<void> saveToken(String token);
  
  /// Получить токен
  Future<String?> getToken();
  
  /// Удалить токен
  Future<void> removeToken();
  
  /// Сохранить данные пользователя
  Future<void> saveUserData(Map<String, dynamic> userData);
  
  /// Получить данные пользователя
  Future<Map<String, dynamic>?> getUserData();
  
  /// Удалить данные пользователя  
  Future<void> removeUserData();
  
  /// Проверить, авторизован ли пользователь
  Future<bool> isLoggedIn();
}

/// Реализация local data source
class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final FlutterSecureStorage _secureStorage;
  final SharedPreferences _prefs;
  
  static const String _tokenKey = 'auth_token';
  static const String _userDataKey = 'user_data';
  
  AuthLocalDataSourceImpl(this._secureStorage, this._prefs);
  
  @override
  Future<void> saveToken(String token) async {
    await _secureStorage.write(key: _tokenKey, value: token);
  }
  
  @override
  Future<String?> getToken() async {
    return await _secureStorage.read(key: _tokenKey);
  }
  
  @override
  Future<void> removeToken() async {
    await _secureStorage.delete(key: _tokenKey);
  }
  
  @override
  Future<void> saveUserData(Map<String, dynamic> userData) async {
    final userDataString = jsonEncode(userData);
    await _prefs.setString(_userDataKey, userDataString);
  }
  
  @override
  Future<Map<String, dynamic>?> getUserData() async {
    final userDataString = _prefs.getString(_userDataKey);
    if (userDataString == null) return null;
    
    try {
      return jsonDecode(userDataString) as Map<String, dynamic>;
    } catch (e) {
      // Если ошибка парсинга - удаляем поврежденные данные
      await removeUserData();
      return null;
    }
  }
  
  @override
  Future<void> removeUserData() async {
    await _prefs.remove(_userDataKey);
  }
  
  @override
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}

/// Provider для secure storage
@riverpod
FlutterSecureStorage secureStorage(SecureStorageRef ref) {
  return const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );
}

/// Provider для shared preferences
@riverpod
Future<SharedPreferences> sharedPreferences(SharedPreferencesRef ref) async {
  return await SharedPreferences.getInstance();
}

/// Provider для local data source
@riverpod
Future<AuthLocalDataSource> authLocalDataSource(AuthLocalDataSourceRef ref) async {
  final secureStorage = ref.watch(secureStorageProvider);
  final sharedPrefs = await ref.watch(sharedPreferencesProvider.future);
  return AuthLocalDataSourceImpl(secureStorage, sharedPrefs);
}

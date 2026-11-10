import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_config.dart';

class AppwriteUser {
  final String id;
  final String name;
  final String email;
  final String sessionId;
  final String? sessionCookie;

  AppwriteUser({
    required this.id,
    required this.name,
    required this.email,
    required this.sessionId,
    this.sessionCookie,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'sessionId': sessionId,
        'sessionCookie': sessionCookie,
      };

  factory AppwriteUser.fromJson(Map<String, dynamic> json) => AppwriteUser(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? 'Anfitrión',
        email: json['email'] as String? ?? '',
        sessionId: json['sessionId'] as String? ?? '',
        sessionCookie: json['sessionCookie'] as String?,
      );
}

class AppwriteAuthService {
  static const String _prefKeyUser = 'appwrite_auth_user';

  final ValueNotifier<AppwriteUser?> currentUserNotifier =
      ValueNotifier<AppwriteUser?>(null);
  final ValueNotifier<bool> isLoggedInNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isLoadingNotifier = ValueNotifier<bool>(false);

  AppwriteUser? get currentUser => currentUserNotifier.value;
  bool get isLoggedIn => isLoggedInNotifier.value;

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_prefKeyUser);
      if (userJson != null && userJson.isNotEmpty) {
        final decoded = jsonDecode(userJson) as Map<String, dynamic>;
        final user = AppwriteUser.fromJson(decoded);
        if (user.sessionId.isNotEmpty) {
          currentUserNotifier.value = user;
          isLoggedInNotifier.value = true;
        }
      }
    } catch (e) {
      debugPrint('Aviso recuperando sesión de Appwrite: $e');
    }
  }

  /// Inicia sesión con Email y Contraseña mediante la API de Appwrite
  Future<Map<String, dynamic>> login({
    required AppConfig config,
    required String email,
    required String password,
  }) async {
    isLoadingNotifier.value = true;
    try {
      final endpoint = config.appwriteEndpoint.trim();
      final projectId = config.appwriteProjectId.trim();
      final uri = Uri.parse('$endpoint/account/sessions/email');

      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'X-Appwrite-Project': projectId,
            },
            body: jsonEncode({
              'email': email.trim(),
              'password': password.trim(),
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final sessionId = data[r'$id'] as String? ?? '';
        final userId = data['userId'] as String? ?? '';
        final userName = (data['userName'] as String? ?? '').isNotEmpty
            ? data['userName'] as String
            : (data['providerUid'] as String? ?? 'Anfitrión');

        // Extraer cookie si está disponible
        final rawCookie = response.headers['set-cookie'];

        final user = AppwriteUser(
          id: userId,
          name: userName,
          email: email.trim(),
          sessionId: sessionId,
          sessionCookie: rawCookie,
        );

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_prefKeyUser, jsonEncode(user.toJson()));

        currentUserNotifier.value = user;
        isLoggedInNotifier.value = true;

        return {
          'success': true,
          'message': '¡Bienvenido(a), ${user.name}! Sesión iniciada correctamente.',
          'user': user,
        };
      } else {
        String errMsg = 'Error al iniciar sesión (${response.statusCode})';
        try {
          final errJson = jsonDecode(response.body) as Map<String, dynamic>;
          if (errJson['message'] != null) {
            errMsg = errJson['message'] as String;
          }
        } catch (_) {}
        return {
          'success': false,
          'message': errMsg,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error de conexión con Appwrite: $e',
      };
    } finally {
      isLoadingNotifier.value = false;
    }
  }

  /// Cierra la sesión activa en Appwrite y localmente
  Future<void> logout({required AppConfig config}) async {
    isLoadingNotifier.value = true;
    final user = currentUserNotifier.value;
    if (user != null && user.sessionId.isNotEmpty) {
      try {
        final endpoint = config.appwriteEndpoint.trim();
        final projectId = config.appwriteProjectId.trim();
        final uri = Uri.parse('$endpoint/account/sessions/${user.sessionId}');

        final headers = <String, String>{
          'X-Appwrite-Project': projectId,
        };
        if (user.sessionCookie != null && user.sessionCookie!.isNotEmpty) {
          headers['Cookie'] = user.sessionCookie!;
        }

        await http.delete(uri, headers: headers).timeout(const Duration(seconds: 8));
      } catch (e) {
        debugPrint('Aviso cerrando sesión en Appwrite: $e');
      }
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKeyUser);

    currentUserNotifier.value = null;
    isLoggedInNotifier.value = false;
    isLoadingNotifier.value = false;
  }
}


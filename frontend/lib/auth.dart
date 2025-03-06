import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart';
import 'package:http/http.dart' as http;

class auth {
  final storage = FlutterSecureStorage();

  Future<void> saveTokens(
    String accessToken,
    String refreshToken,
    int expireTime,
  ) async {
    await storage.write(key: 'access_token', value: accessToken);
    await storage.write(key: 'refresh_token', value: refreshToken);
    await storage.write(key: 'exp', value: "$expireTime");
  }

  Future<String?> getAccessToken() async {
    return await storage.read(key: 'access_token');
  }

  Future<int?> getExpireTime() async {
    return int.parse((await storage.read(key: 'exp'))!);
  }

  Future<String?> getRefreshToken() async {
    return await storage.read(key: 'refresh_token');
  }

  Future<void> refreshTokenIfNeeded() async {
    final token = await getAccessToken();
    if (token == null) {
      return;
    }

    final response = await http.post(
      Uri.parse('http://localhost:5001/api/v1/refresh'),
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      final accessToken = responseData['access_token'];
      await storage.write(key: 'access_token', value: accessToken);
    }
  }

  Future<Response> makeAuthenticatedGetRequest(String endpoint) async {
    await refreshTokenIfNeeded();
    final token = await getAccessToken();
    final response = await http.get(
      Uri.parse('http://localhost:5001/api/v1/$endpoint'),
      headers: {'Authorization': 'Bearer $token'},
    );
    return response;
  }

  Future<Response> makeAuthenticatedPostRequest(String endpoint) async {
    await refreshTokenIfNeeded();
    final token = await getAccessToken();
    final response = await http.post(
      Uri.parse('http://localhost:5001/api/v1/$endpoint'),
      headers: {'Authorization': 'Bearer $token'},
    );
    return response;
  }

  Future<void> removeTokens() async {
    await storage.delete(key: 'auth_token');
    await storage.delete(key: 'refresh_token');
  }
}

import 'dart:convert';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:frontend/util.dart';
import 'package:http/http.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart';

class Auth {
  static final storage = FlutterSecureStorage();

  static Future<void> saveTokens(
    String accessToken,
    String refreshToken,
    int expireTime,
  ) async {
    await storage.write(key: 'access_token', value: accessToken);
    await storage.write(key: 'refresh_token', value: refreshToken);
    await storage.write(key: 'exp', value: "$expireTime");
  }

  static Future<String?> getAccessToken() async {
    return await storage.read(key: 'access_token');
  }

  static Future<int?> getExpireTime() async {
    return int.parse((await storage.read(key: 'exp'))!);
  }

  static Future<String?> getRefreshToken() async {
    return await storage.read(key: 'refresh_token');
  }

  static Future<void> refreshTokenIfNeeded() async {
    final token = await getRefreshToken();
    final expireTime = await getExpireTime();

    if (token == null || expireTime == null) {
      return;
    }

    // Check if the token is expired
    if (DateTime.now().millisecondsSinceEpoch / 1000 >= expireTime) {
      final response = await http.post(
        Uri.parse('${Util.BACKEND_URL}/api/v1/refresh-token'),
        headers: {'Content-Type': 'application/json'},
        body: {"refreshToken": token},
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body)["session"];
        final accessToken = responseData['access_token'];
        final newExpireTime =
            responseData['exp']; // Ensure this is returned from the API

        await storage.write(key: 'access_token', value: accessToken);
        await storage.write(key: 'exp', value: newExpireTime.toString());
      }
    }
  }

  static Future<Response> makeAuthenticatedGetRequest(String endpoint) async {
    await refreshTokenIfNeeded();
    final token = await getAccessToken();
    final response = await http.get(
      Uri.parse('${Util.BACKEND_URL}/api/v1/$endpoint'),
      headers: {HttpHeaders.authorizationHeader: 'Bearer $token'},
    );
    return response;
  }

  static Future<Response> makeAuthenticatedPostRequest(
    String endpoint,
    final body,
  ) async {
    await refreshTokenIfNeeded();
    final token = await getAccessToken();
    final response = await http.post(
      Uri.parse('${Util.BACKEND_URL}/api/v1/$endpoint'),
      headers: {
        HttpHeaders.authorizationHeader: 'Bearer $token',
        HttpHeaders.contentTypeHeader: "application/json",
      },
      body: json.encode(body),
    );
    return response;
  }

  static Future<void> removeTokens() async {
    String token = (await getAccessToken())!;
    print(token);
    await storage.delete(key: 'access_token');
    await storage.delete(key: 'refresh_token');
  }

  static Future<http.Response> uploadFileWithAuth(
    String endpoint,
    File file,
    Map<String, dynamic> body,
  ) async {
    await refreshTokenIfNeeded();
    final token = await getAccessToken();

    var request = http.MultipartRequest(
      'POST',
      Uri.parse('${Util.BACKEND_URL}/api/v1/$endpoint'),
    );

    request.headers.addAll({HttpHeaders.authorizationHeader: 'Bearer $token'});

    // Add all body parameters as fields
    body.forEach((key, value) {
      request.fields[key] = value.toString();
    });

    request.files.add(
      await http.MultipartFile.fromPath(
        'icon',
        file.path,
        contentType: MediaType('image', extension(file.path).substring(1)),
      ),
    );

    var streamedResponse = await request.send();

    var response = await http.Response.fromStream(streamedResponse);

    return response;
  }
}

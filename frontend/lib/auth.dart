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
  static String? _accessToken;
  static String? _refreshToken;
  static int? _exp;

  static Future<void> saveTokens(
    String accessToken,
    String refreshToken,
    int expireTime,
  ) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    _exp = expireTime;

    await storage.write(key: 'access_token', value: accessToken);
    await storage.write(key: 'refresh_token', value: refreshToken);
    await storage.write(key: 'exp', value: "$expireTime");
  }

  static Future<String?> getAccessToken() async {
    await refreshTokenIfNeeded();

    if (_accessToken != null) {
      return _accessToken;
    }

    _accessToken = await storage.read(key: 'access_token');
    return _accessToken;
  }

  static Future<int?> getExpireTime() async {
    if (_exp != null) {
      return _exp;
    }

    String? expireString = await storage.read(key: 'exp');
    if (expireString == null || expireString == "null") {
      return null;
    }
    _exp = int.tryParse(expireString);
    return _exp;
  }

  static Future<String?> getRefreshToken() async {
    if (_refreshToken != null) {
      return _refreshToken;
    }
    _refreshToken = await storage.read(key: 'refresh_token');
    return _refreshToken;
  }

  static Future<void> refreshTokenIfNeeded() async {
    String? token = _accessToken;
    token ??= await storage.read(key: 'access_token');

    final expireTime = await getExpireTime();

    if (token == null || expireTime == null) {
      return;
    }

    // Check if the token is expired
    if (DateTime.now().millisecondsSinceEpoch / 1000 >= expireTime) {
      final body = jsonEncode({"refreshToken": token});
      final response = await http.post(
        Uri.parse('${Util.BACKEND_URL}/api/v1/refresh-token'),
        headers: {HttpHeaders.contentTypeHeader: "application/json"},
        body: body,
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body)["session"];
        final accessToken = responseData['access_token'];
        final refreshToken = responseData['refresh_token'];
        final newExpireTime = responseData['exp'];

        saveTokens(accessToken, refreshToken, newExpireTime);
      } else {
        await removeTokens();
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
    await storage.deleteAll();
  }

  static Future<http.Response> uploadFileWithAuth(
    String endpoint,
    File file,
    Map<String, dynamic> body,
  ) async {
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

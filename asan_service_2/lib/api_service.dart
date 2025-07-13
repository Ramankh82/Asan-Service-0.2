// api_service.dart
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;
  final dynamic details;

  ApiException({
    required this.statusCode,
    required this.message,
    this.details,
  });

  @override
  String toString() {
    return 'ApiException: $message (Status Code: $statusCode, Details: $details)';
  }
}

class ApiService {
  static const String _baseUrl = 'http://10.0.2.2:8000/api';
  static const Map<String, String> _defaultHeaders = {
    'Content-Type': 'application/json; charset=UTF-8',
  };

  Future<Map<String, dynamic>> _handleResponse(http.Response response) async {
    final responseBody = utf8.decode(response.bodyBytes);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(responseBody);
    }

    try {
      final errorData = jsonDecode(responseBody);
      throw ApiException(
        statusCode: response.statusCode,
        message: errorData['message'] ?? errorData.toString(),
        details: errorData,
      );
    } catch (_) {
      throw ApiException(
        statusCode: response.statusCode,
        message: 'درخواست با خطا مواجه شد: کد ${response.statusCode}',
        details: responseBody,
      );
    }
  }

  Map<String, String> _buildHeaders(String token) {
    return {
      ..._defaultHeaders,
      'Authorization': 'Bearer $token',
    };
  }

  Future<Map<String, dynamic>> _handleRequest(Future<http.Response> request) async {
    try {
      final response = await request.timeout(const Duration(seconds: 30));
      return _handleResponse(response);
    } on TimeoutException {
      throw ApiException(
        statusCode: 408,
        message: 'اتصال به سرور زمان‌بر شد',
        details: 'Request timed out after 30 seconds',
      );
    }
  }

  Future<Map<String, dynamic>> getUserProfile(String token) async {
    final url = Uri.parse('$_baseUrl/auth/profile/');
    return _handleRequest(http.get(url, headers: _buildHeaders(token)));
  }

  Future<List<dynamic>> getServiceRequests(String token) async {
    final url = Uri.parse('$_baseUrl/requests/');
    final response = await http.get(
      url,
      headers: _buildHeaders(token),
    );

    if (response.statusCode == 200) {
      final decodedBody = jsonDecode(utf8.decode(response.bodyBytes));

      if (decodedBody is List) {
        return decodedBody;
      } else if (decodedBody is Map) {
        if (decodedBody.containsKey('data') && decodedBody['data'] is List) {
          return decodedBody['data'];
        }
        throw ApiException(
          statusCode: 500,
          message: 'فرمت پاسخ سرور نامعتبر است',
          details: 'Expected list but got map',
        );
      }
      throw ApiException(
        statusCode: 500,
        message: 'فرمت پاسخ سرور نامعتبر است',
        details: 'Expected list but got ${decodedBody.runtimeType}',
      );
    }
    throw ApiException(
      statusCode: response.statusCode,
      message: 'خطا در دریافت لیست درخواست‌ها',
      details: utf8.decode(response.bodyBytes),
    );
  }

  Future<List<dynamic>> getMaintenanceContracts(String token) async {
    final url = Uri.parse('$_baseUrl/contracts/');
    final response = await http.get(
      url,
      headers: _buildHeaders(token),
    );

    if (response.statusCode == 200) {
      final decodedBody = jsonDecode(utf8.decode(response.bodyBytes));

      if (decodedBody is List) {
        return decodedBody;
      } else if (decodedBody is Map) {
        if (decodedBody.containsKey('data') && decodedBody['data'] is List) {
          return decodedBody['data'];
        }
        throw ApiException(
          statusCode: 500,
          message: 'فرمت پاسخ سرور نامعتبر است',
          details: 'Expected list but got map',
        );
      }
      throw ApiException(
        statusCode: 500,
        message: 'فرمت پاسخ سرور نامعتبر است',
        details: 'Expected list but got ${decodedBody.runtimeType}',
      );
    }
    throw ApiException(
      statusCode: response.statusCode,
      message: 'خطا در دریافت لیست قراردادهای نگهداری',
      details: utf8.decode(response.bodyBytes),
    );
  }

  Future<Map<String, dynamic>> getServiceRequestDetail({
    required String token,
    required int requestId,
  }) async {
    final url = Uri.parse('$_baseUrl/requests/$requestId/');
    return _handleRequest(http.get(url, headers: _buildHeaders(token)));
  }

  Future<Map<String, dynamic>> createServiceRequest({
    required String token,
    required String title,
    required String description,
    required String address,
  }) async {
    final url = Uri.parse('$_baseUrl/requests/');
    return _handleRequest(
      http.post(
        url,
        headers: _buildHeaders(token),
        body: jsonEncode({
          'title': title,
          'description': description,
          'address': address,
        }),
      ),
    );
  }

  Future<Map<String, dynamic>> acceptServiceRequest({
    required String token,
    required int requestId,
  }) async {
    final url = Uri.parse('$_baseUrl/requests/$requestId/accept/');
    return _handleRequest(http.post(url, headers: _buildHeaders(token)));
  }

  Future<Map<String, dynamic>> updateRequestStatus({
    required String token,
    required int requestId,
    required String newStatus,
  }) async {
    final url = Uri.parse('$_baseUrl/requests/$requestId/update_status/');
    return _handleRequest(
      http.post(
        url,
        headers: _buildHeaders(token),
        body: jsonEncode({'status': newStatus}),
      ),
    );
  }

  Future<Map<String, dynamic>> setRequestPrice({
    required String token,
    required int requestId,
    required double price,
  }) async {
    final url = Uri.parse('$_baseUrl/requests/$requestId/set_price/');
    try {
      final response = await http.post(
        url,
        headers: _buildHeaders(token),
        body: jsonEncode({
          'final_price': price.toString(),
        }),
      ).timeout(const Duration(seconds: 30));
      return _handleResponse(response);
    } catch (e) {
      throw ApiException(
        statusCode: 400,
        message: 'خطا در ثبت هزینه: ${e.toString()}',
      );
    }
  }

  Future<Map<String, dynamic>> applyDiscount({
    required String token,
    required int requestId,
    required String discountCode,
  }) async {
    final url = Uri.parse('$_baseUrl/requests/$requestId/apply_discount/');
    return _handleRequest(
      http.post(
        url,
        headers: _buildHeaders(token),
        body: jsonEncode({'discount_code': discountCode}),
      ),
    );
  }

  Future<Map<String, dynamic>> payForRequest({
    required String token,
    required int requestId,
  }) async {
    final url = Uri.parse('$_baseUrl/requests/$requestId/pay/');
    return _handleRequest(http.post(url, headers: _buildHeaders(token)));
  }

  Future<Map<String, dynamic>> rateRequest({
    required String token,
    required int requestId,
    required int rating,
    String? review,
  }) async {
    final url = Uri.parse('$_baseUrl/requests/$requestId/rate/');
    return _handleRequest(
      http.post(
        url,
        headers: _buildHeaders(token),
        body: jsonEncode({
          'rating': rating,
          'review': review,
        }),
      ),
    );
  }

  Future<Map<String, dynamic>> updateUserProfile({
    required String token,
    required String firstName,
    required String lastName,
  }) async {
    final url = Uri.parse('$_baseUrl/auth/profile/');
    return _handleRequest(
      http.patch(
        url,
        headers: _buildHeaders(token),
        body: jsonEncode({
          'first_name': firstName,
          'last_name': lastName,
        }),
      ),
    );
  }

  Future<Map<String, dynamic>> getActiveContract(String token) async {
    final url = Uri.parse('$_baseUrl/contracts/active/');
    return _handleRequest(http.get(url, headers: _buildHeaders(token)));
  }

  Future<Map<String, dynamic>> getQuote(String token, Map<String, dynamic> data) async {
    final url = Uri.parse('$_baseUrl/contracts/quote/');
    return _handleRequest(
      http.post(
        url,
        headers: _buildHeaders(token),
        body: jsonEncode(data),
      ),
    );
  }

  Future<Map<String, dynamic>> createContract(String token, Map<String, dynamic> data) async {
    final url = Uri.parse('$_baseUrl/contracts/');
    return _handleRequest(
      http.post(
        url,
        headers: _buildHeaders(token),
        body: jsonEncode(data),
      ),
    );
  }

  Future<Map<String, dynamic>> createProjectRequest(
    String token,
    Map<String, dynamic> data,
    List<dynamic>? attachments,
  ) async {
    final url = Uri.parse('$_baseUrl/requests/');
    var request = http.MultipartRequest('POST', url);

    request.headers.addAll(_buildHeaders(token));

    request.fields['title'] = data['title'];
    request.fields['description'] = data['description'];
    request.fields['address'] = data['address'];
    request.fields['type'] = data['type'];

    if (attachments != null) {
      for (var file in attachments as List<PlatformFile>) {
        request.files.add(await http.MultipartFile.fromPath(
          'attachments',
          file.path!,
          filename: file.name,
        ));
      }
    }

    final response = await request.send();
    final responseData = await response.stream.bytesToString();

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(responseData);
    }

    throw ApiException(
      statusCode: response.statusCode,
      message: 'خطا در ارسال درخواست',
      details: responseData,
    );
  }

  Future<Map<String, dynamic>> createInsurance(String token, Map<String, dynamic> data) async {
    final url = Uri.parse('$_baseUrl/insurance/');
    return _handleRequest(
      http.post(
        url,
        headers: _buildHeaders(token),
        body: jsonEncode(data),
      ),
    );
  }

  Future<List<dynamic>> getInsuranceQuote(String token, Map<String, dynamic> data) async {
    final url = Uri.parse('$_baseUrl/insurance/quote/');
    final responseMap = await _handleRequest(
      http.post(
        url,
        headers: _buildHeaders(token),
        body: jsonEncode(data),
      ),
    );
    return responseMap as List<dynamic>;
  }
}
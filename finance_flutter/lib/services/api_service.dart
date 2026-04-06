import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class ApiService {
  // Change this to your Railway backend URL after deployment
  static const String baseUrl = 'https://YOUR-APP.up.railway.app/api';

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<Map<String, String>> _headers() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ---- Auth ----
  static Future<Map<String, dynamic>> login(String username, String password) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> register(
      String username, String email, String password) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'email': email, 'password': password}),
    );
    return jsonDecode(res.body);
  }

  static Future<User> getMe() async {
    final res = await http.get(Uri.parse('$baseUrl/auth/me'), headers: await _headers());
    final body = jsonDecode(res.body);
    return User.fromJson(body['data']);
  }

  // ---- Dashboard ----
  static Future<DashboardSummary> getDashboard() async {
    final res = await http.get(
      Uri.parse('$baseUrl/dashboard/summary'),
      headers: await _headers(),
    );
    final body = jsonDecode(res.body);
    return DashboardSummary.fromJson(body['data']);
  }

  // ---- Records ----
  static Future<PagedResponse<FinancialRecord>> getRecords({
    String? type, String? category, String? from, String? to,
    String? search, int page = 0, int size = 10}) async {
    final params = <String, String>{
      'page': page.toString(), 'size': size.toString(),
    };
    if (type != null) params['type'] = type;
    if (category != null) params['category'] = category;
    if (from != null) params['from'] = from;
    if (to != null) params['to'] = to;
    if (search != null && search.isNotEmpty) params['search'] = search;

    final uri = Uri.parse('$baseUrl/records').replace(queryParameters: params);
    final res = await http.get(uri, headers: await _headers());
    final body = jsonDecode(res.body);
    final data = body['data'];
    final content = (data['content'] as List)
        .map((e) => FinancialRecord.fromJson(e)).toList();
    return PagedResponse<FinancialRecord>(
      content: content,
      page: data['page'],
      size: data['size'],
      totalPages: data['totalPages'],
      totalElements: data['totalElements'],
    );
  }

  static Future<Map<String, dynamic>> createRecord(Map<String, dynamic> data) async {
    final res = await http.post(
      Uri.parse('$baseUrl/records'),
      headers: await _headers(),
      body: jsonEncode(data),
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> updateRecord(int id, Map<String, dynamic> data) async {
    final res = await http.put(
      Uri.parse('$baseUrl/records/$id'),
      headers: await _headers(),
      body: jsonEncode(data),
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> deleteRecord(int id) async {
    final res = await http.delete(
      Uri.parse('$baseUrl/records/$id'),
      headers: await _headers(),
    );
    return jsonDecode(res.body);
  }

  // ---- Users ----
  static Future<List<User>> getUsers() async {
    final res = await http.get(Uri.parse('$baseUrl/users'), headers: await _headers());
    final body = jsonDecode(res.body);
    return (body['data'] as List).map((e) => User.fromJson(e)).toList();
  }

  static Future<Map<String, dynamic>> updateUser(int id, Map<String, dynamic> data) async {
    final res = await http.put(
      Uri.parse('$baseUrl/users/$id'),
      headers: await _headers(),
      body: jsonEncode(data),
    );
    return jsonDecode(res.body);
  }
}

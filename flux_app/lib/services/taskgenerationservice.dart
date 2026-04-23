import 'dart:convert';
import 'package:http/http.dart' as http;

class TaskGenerationService {
  final baseUrl = "https://flux-test-cg9c.onrender.com";

  /// Generate task from ML results
  Future<Map<String, dynamic>?> generateTaskFromML({
    required String ngoId,
  }) async {
    try {
      final url = '$baseUrl/uploads/ngo/$ngoId/generate-task';
      print('[TaskGenerationService] 🔍 Requesting ML task generation...');
      print('[TaskGenerationService] URL: $url');
      print('[TaskGenerationService] NGO ID: $ngoId');
      
      final res = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      ).timeout(
        const Duration(seconds: 30),
      );

      print('[TaskGenerationService] Response status: ${res.statusCode}');
      print('[TaskGenerationService] Response body: ${res.body}');

      // Accept any 2xx success status code
      if (res.statusCode >= 200 && res.statusCode < 300) {
        if (res.body.isEmpty) {
          print('[TaskGenerationService] ⚠️ Empty response body');
          throw Exception('Empty response from server');
        }
        try {
          final data = jsonDecode(res.body);
          print('[TaskGenerationService] ✅ Task generated successfully');
          print('[TaskGenerationService] Data: $data');
          return data;
        } catch (e) {
          print('[TaskGenerationService] ❌ JSON decode error: $e');
          throw Exception('Invalid response format: $e');
        }
      } else if (res.statusCode == 502 || res.statusCode == 503) {
        // Server error - extract error message from response
        print('[TaskGenerationService] ⚠️ Server error (${res.statusCode})');
        try {
          final errorData = jsonDecode(res.body);
          final detail = errorData['detail'] ?? 'Server error. Please try again later.';
          print('[TaskGenerationService] Error detail: $detail');
          throw Exception(detail);
        } catch (e) {
          if (e is Exception && !e.toString().contains('type')) {
            rethrow;
          }
          throw Exception('AI service temporarily unavailable. Please try again later.');
        }
      } else {
        print('[TaskGenerationService] ❌ Failed with status ${res.statusCode}');
        throw Exception('Failed to generate task (${res.statusCode})');
      }
    } catch (e) {
      print('[TaskGenerationService] ❌ Exception: $e');
      rethrow;
    }
  }

  /// Get news by state
  Future<Map<String, dynamic>?> getNewsByState({
    required String state,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/news/by-state'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'state': state}),
      );

      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
      return null;
    } catch (e) {
      print('Error: $e');
      return null;
    }
  }
}

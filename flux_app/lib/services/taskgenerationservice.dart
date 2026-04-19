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

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        print('[TaskGenerationService] ✅ Task generated successfully');
        return data;
      } else if (res.statusCode == 502 || res.statusCode == 503) {
        // Server error - likely quota exceeded or service down
        print('[TaskGenerationService] ⚠️ Server error - quota or service issue');
        if (res.body.contains('RESOURCE_EXHAUSTED') || res.body.contains('quota')) {
          print('[TaskGenerationService] 📊 Quota exceeded for AI generation');
        }
        return null;
      } else {
        print('[TaskGenerationService] ❌ Failed with status ${res.statusCode}');
        return null;
      }
    } catch (e) {
      print('[TaskGenerationService] ❌ Exception: $e');
      return null;
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

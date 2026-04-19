import 'dart:convert';
import 'package:http/http.dart' as http;

class TaskGenerationService {
  final baseUrl = "https://flux-test-cg9c.onrender.com";

  /// Generate task from ML results
  Future<Map<String, dynamic>?> generateTaskFromML({
    required String ngoId,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/uploads/ngo/$ngoId/generate-task'),
        headers: {'Content-Type': 'application/json'},
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

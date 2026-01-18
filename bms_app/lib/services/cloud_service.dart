import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/models.dart';

class CloudService {
  static const String protocolVersion = '1.0';
  static const String appVersion = '1.0.0';

  Future<bool> uploadTelemetry({
    required BmsData data,
    required String endpoint,
    required String apiKey,
    required String deviceId,
  }) async {
    const int maxRetries = 3;
    int attempt = 0;

    while (attempt < maxRetries) {
      attempt++;
      try {
        if (endpoint.isEmpty || endpoint.contains('example.com')) {
          print('[CloudService] Mock Upload (Attempt $attempt): Telemetry data sent to $endpoint');
          return true;
        }

        final response = await http.post(
          Uri.parse(endpoint),
          headers: {
            'Content-Type': 'application/json',
            'X-API-Key': apiKey,
            'X-Device-ID': deviceId,
          },
          body: jsonEncode({
            'header': {
              'deviceId': deviceId,
              'protocolVersion': protocolVersion,
              'appVersion': appVersion,
              'timestamp': DateTime.now().toIso8601String(),
            },
            'payload': data.toJson(),
          }),
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode >= 200 && response.statusCode < 300) {
          print('[CloudService] Telemetry upload successful on attempt $attempt');
          return true;
        } else {
          print('[CloudService] Telemetry upload failed (Attempt $attempt): ${response.statusCode}');
        }
      } catch (e) {
        print('[CloudService] Error uploading telemetry (Attempt $attempt): $e');
      }

      if (attempt < maxRetries) {
        await Future.delayed(Duration(seconds: 2 * attempt)); // Exponential backoff
      }
    }

    return false;
  }

  Future<bool> testConnection(String endpoint, String apiKey) async {
    try {
      if (endpoint.isEmpty || endpoint.contains('example.com')) {
        await Future.delayed(const Duration(seconds: 1)); // Simulate latency
        return true;
      }

      final response = await http.get(
        Uri.parse(endpoint),
        headers: {
          'X-API-Key': apiKey,
        },
      ).timeout(const Duration(seconds: 10));

      // For skeleton, even if it returns 404 but we got a response, it technically connected
      return response.statusCode < 500;
    } catch (e) {
      print('[CloudService] Connection test failed: $e');
      return false;
    }
  }
}

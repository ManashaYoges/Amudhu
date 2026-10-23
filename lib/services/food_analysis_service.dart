import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../models/food_analysis_result.dart';
import 'api_client.dart';

/// Exception thrown when food analysis fails.
class FoodAnalysisException implements Exception {
  final String message;
  final dynamic originalError;

  const FoodAnalysisException(this.message, [this.originalError]);

  @override
  String toString() => message;
}

/// Service responsible for analyzing meal images using real AI Vision.
/// Connects securely to the Amudhu backend or configured vision endpoint.
class FoodAnalysisService {
  /// Default backend URL.
  /// On Android emulator, '10.0.2.2' maps to the host machine's 'localhost'.
  /// On Windows desktop, macOS, iOS simulator, or Web, 'localhost' is used.
  static String get defaultBackendUrl => ApiClient.baseUrl;

  /// Active backend base URL (can be customized by user/developer in settings)
  static String activeBackendUrl = defaultBackendUrl;

  /// Checks if the backend server is reachable and configured
  Future<Map<String, dynamic>> checkBackendHealth() async {
    try {
      final uri = Uri.parse('$activeBackendUrl/api/health');
      final res = await http.get(uri).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
      return {'status': 'error', 'statusCode': res.statusCode};
    } catch (e) {
      return {'status': 'unreachable', 'error': e.toString()};
    }
  }

  /// Analyzes a meal image by sending actual pixels to the vision pipeline.
  /// NEVER returns mock or hardcoded meals.
  Future<FoodAnalysisResult> analyzeImage(File image) async {
    // 1. Validate image file exists and is readable
    if (!await image.exists()) {
      throw const FoodAnalysisException(
        "The selected image file could not be found. Please choose another photo.",
      );
    }

    final fileSize = await image.length();
    if (fileSize == 0) {
      throw const FoodAnalysisException(
        "The selected image is empty. Please choose another photo.",
      );
    }

    return _performBackendAnalysis(image);
  }

  /// Real Backend Vision Analysis
  /// Sends the image to the secure backend endpoint which calls the Vision model
  /// and calculates nutrition using the standardized food composition database.
  Future<FoodAnalysisResult> _performBackendAnalysis(File image) async {
    final endpoint = Uri.parse('$activeBackendUrl/api/analyze-plate');

    try {
      final request = http.MultipartRequest('POST', endpoint);

      // Determine MIME type
      final ext = image.path.split('.').last.toLowerCase();
      String mime = 'image/jpeg';
      if (ext == 'png') {
        mime = 'image/png';
      } else if (ext == 'webp') {
        mime = 'image/webp';
      }

      final fileBytes = await image.readAsBytes();
      final multipartFile = http.MultipartFile.fromBytes(
        'image',
        fileBytes,
        filename: image.uri.pathSegments.isNotEmpty
            ? image.uri.pathSegments.last
            : 'meal.jpg',
        contentType: MediaType.parse(mime),
      );
      request.files.add(multipartFile);

      // Send request with a reasonable timeout for multimodal AI inference
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 35),
      );
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final Map<String, dynamic> json = jsonDecode(utf8.decode(response.bodyBytes));
        return FoodAnalysisResult.fromJson(json, imagePath: image.path);
      } else if (response.statusCode == 422) {
        // No food detected in the photo
        final Map<String, dynamic>? errJson = _tryParseJson(response.body);
        final message = errJson?['error'] as String? ??
            "No food could be identified in this photo. Please make sure the plate is clearly visible.";
        throw FoodAnalysisException(message);
      } else if (response.statusCode == 503) {
        // Backend missing API key
        final Map<String, dynamic>? errJson = _tryParseJson(response.body);
        final message = errJson?['error'] as String? ??
            "AI Vision backend is not configured with an API key. Please set GEMINI_API_KEY in the backend server.";
        throw FoodAnalysisException(message);
      } else if (response.statusCode == 429) {
        throw const FoodAnalysisException(
          "AI rate limit reached. Please wait a moment and try again.",
        );
      } else {
        final Map<String, dynamic>? errJson = _tryParseJson(response.body);
        final message = errJson?['error'] as String? ??
            "Server returned an error (${response.statusCode}). Please try again.";
        throw FoodAnalysisException(message);
      }
    } on SocketException catch (e) {
      throw FoodAnalysisException(
        "Cannot connect to the AI Vision backend at $activeBackendUrl.\n\n"
        "Make sure the backend is running (`cd backend && npm start`), or update the backend address in settings.",
        e,
      );
    } on TimeoutException catch (e) {
      throw FoodAnalysisException(
        "Vision analysis timed out. Please check your network connection and try again.",
        e,
      );
    } on FormatException catch (e) {
      throw FoodAnalysisException(
        "Invalid response format from analysis server. Please check the backend logs.",
        e,
      );
    } catch (e) {
      if (e is FoodAnalysisException) rethrow;
      throw FoodAnalysisException(
        "Could not analyze meal: ${e.toString()}",
        e,
      );
    }
  }

  static Map<String, dynamic>? _tryParseJson(String text) {
    try {
      return jsonDecode(text) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }
}

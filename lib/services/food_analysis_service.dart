import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../models/food_analysis_result.dart';
import 'nutrition_database_service.dart';

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
  static String get defaultBackendUrl {
    // Check if overridden via dart-define
    const envUrl = String.fromEnvironment('AI_BACKEND_URL');
    if (envUrl.isNotEmpty) return envUrl;

    if (!kIsWeb && Platform.isAndroid) {
      return 'http://10.0.2.2:3000';
    }
    return 'http://localhost:3000';
  }

  /// Active backend base URL (can be customized by user/developer in settings)
  static String activeBackendUrl = defaultBackendUrl;

  /// Optional client-side Gemini API key supplied via --dart-define=GEMINI_API_KEY=...
  /// Keeping credentials server-side is the recommended secure pattern.
  static const String directGeminiApiKey = String.fromEnvironment('GEMINI_API_KEY');

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

    // 2. Perform real vision recognition via backend (or direct Gemini if configured)
    if (directGeminiApiKey.isNotEmpty) {
      return _performDirectGeminiAnalysis(image);
    } else {
      return _performBackendAnalysis(image);
    }
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

  /// Direct Gemini Vision inference when configured with GEMINI_API_KEY
  Future<FoodAnalysisResult> _performDirectGeminiAnalysis(File image) async {
    const model = 'gemini-1.5-flash';
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$directGeminiApiKey',
    );

    try {
      final imageBytes = await image.readAsBytes();
      final base64Image = base64Encode(imageBytes);

      final ext = image.path.split('.').last.toLowerCase();
      String mime = 'image/jpeg';
      if (ext == 'png') mime = 'image/png';
      if (ext == 'webp') mime = 'image/webp';

      const prompt = '''
You are an expert food recognition AI for Amudhu Smart Plate.
Inspect this photograph of a meal and identify only the visibly present foods with realistic portion estimates.
Carefully recognize South Indian, Indian (rice, sambar, rasam, dal, poriyal, idli, dosa, chapati, curries, etc.) and global foods.
Never hallucinate or guess invisible ingredients, oils, or spices.
For distinct items, list them separately.
For mixed dishes, identify the dish.
Return strictly a JSON object:
{
  "isFood": true,
  "mealName": "Name of meal",
  "foods": [
    {
      "name": "Food name",
      "confidence": 0.90,
      "estimatedGrams": 180,
      "alternatives": [],
      "notes": null
    }
  ],
  "uncertaintyNotes": null
}
''';

      final payload = jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': prompt},
              {
                'inlineData': {
                  'mimeType': mime,
                  'data': base64Image,
                }
              }
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.1,
          'responseMimeType': 'application/json',
        }
      });

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: payload,
      ).timeout(const Duration(seconds: 35));

      if (response.statusCode != 200) {
        throw FoodAnalysisException('Gemini API returned code ${response.statusCode}: ${response.body}');
      }

      final resJson = jsonDecode(response.body);
      final rawText = resJson['candidates']?[0]?['content']?['parts']?[0]?['text'] as String?;
      if (rawText == null || rawText.isEmpty) {
        throw const FoodAnalysisException("No response received from vision model.");
      }

      String cleaned = rawText.trim();
      if (cleaned.startsWith('```json')) {
        cleaned = cleaned.replaceFirst(RegExp(r'^```json\s*'), '').replaceFirst(RegExp(r'\s*```$'), '');
      } else if (cleaned.startsWith('```')) {
        cleaned = cleaned.replaceFirst(RegExp(r'^```\s*'), '').replaceFirst(RegExp(r'\s*```$'), '');
      }

      final parsed = jsonDecode(cleaned) as Map<String, dynamic>;
      if (parsed['isFood'] == false) {
        throw const FoodAnalysisException("No visible food detected in this photo. Please upload a clear photo of a meal.");
      }

      final rawFoods = parsed['foods'] as List<dynamic>? ?? [];
      final calculatedFoods = <FoodItem>[];

      for (final f in rawFoods) {
        final itemMap = f as Map<String, dynamic>;
        final name = itemMap['name'] as String? ?? 'Cooked food';
        final grams = (itemMap['estimatedGrams'] as num?)?.toDouble() ?? 100.0;
        final conf = (itemMap['confidence'] as num?)?.toDouble() ?? 0.85;
        final alts = (itemMap['alternatives'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? <String>[];
        final notes = itemMap['notes'] as String?;

        final item = NutritionDatabaseService.instance.calculateFoodItem(
          name: name,
          grams: grams,
          confidence: conf,
          alternatives: alts,
          notes: notes,
        );
        calculatedFoods.add(item);
      }

      final total = FoodAnalysisResult.calculateTotal(calculatedFoods);
      final balance = FoodAnalysisResult.calculateBalance(total, calculatedFoods);

      return FoodAnalysisResult(
        mealName: parsed['mealName'] as String? ?? 'Identified Meal',
        foods: calculatedFoods,
        total: total,
        balance: balance,
        vitaminsAndMinerals: FoodAnalysisResult.defaultVitamins,
        timestamp: DateTime.now(),
        imagePath: image.path,
        analysisSource: 'real_ai',
        isEstimate: true,
        uncertaintyNotes: parsed['uncertaintyNotes'] as String?,
      );
    } catch (e) {
      if (e is FoodAnalysisException) rethrow;
      throw FoodAnalysisException("Direct AI vision analysis failed: $e", e);
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

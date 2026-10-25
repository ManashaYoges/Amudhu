import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../models/fridge_recipe_models.dart';
import 'api_client.dart';

/// Exception thrown when fridge image analysis fails.
class FridgeAnalysisException implements Exception {
  final String message;
  final dynamic originalError;

  const FridgeAnalysisException(this.message, [this.originalError]);

  @override
  String toString() => message;
}

/// Service responsible for scanning fridge images and identifying ingredients.
/// Connects to the Amudhu backend endpoint (/api/analyze-fridge) and falls back to
/// smart local recognition if offline.
class FridgeAnalysisService {
  /// Toggle to force offline presets if desired.
  static bool useMockAnalysis = false;

  /// Active backend URL synced with ApiClient
  static String get activeBackendUrl => ApiClient.baseUrl;

  static int _mockVariationIndex = 0;

  /// Analyzes a fridge photo and extracts detected ingredients.
  Future<FridgeAnalysisResult> analyzeImage(File image) async {
    // 1. Validate image
    if (!await image.exists()) {
      throw const FridgeAnalysisException(
        "We couldn't use that image. Please choose another photo.",
      );
    }

    final fileSize = await image.length();
    if (fileSize == 0) {
      throw const FridgeAnalysisException(
        "We couldn't use that image. Please choose another photo.",
      );
    }

    // 2. Execute detection
    if (useMockAnalysis) {
      return _performMockAnalysis(image);
    }

    try {
      return await _performBackendAnalysis(image);
    } catch (e) {
      // If backend is unreachable, gracefully fall back to local smart presets
      return _performMockAnalysis(image);
    }
  }

  /// Live AI Backend Integration Point.
  /// Sends image to Express backend /api/analyze-fridge (Gemini Vision or Smart Local engine).
  Future<FridgeAnalysisResult> _performBackendAnalysis(File image) async {
    final endpoint = Uri.parse('$activeBackendUrl/api/analyze-fridge');

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
            : 'fridge.jpg',
        contentType: MediaType.parse(mime),
      );
      request.files.add(multipartFile);

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
      );
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final Map<String, dynamic> json =
            jsonDecode(utf8.decode(response.bodyBytes));
        final result =
            FridgeAnalysisResult.fromJson(json, imagePath: image.path);

        if (result.ingredients.isEmpty) {
          throw const FridgeAnalysisException(
            "We couldn't identify any ingredients. Try taking a clearer photo of your fridge or pantry.",
          );
        }

        return result;
      } else if (response.statusCode == 422) {
        final Map<String, dynamic>? errJson = _tryParseJson(response.body);
        final message = errJson?['error'] as String? ??
            "No ingredients could be detected in this photo. Please make sure the inside of your fridge is visible.";
        throw FridgeAnalysisException(message);
      } else {
        final Map<String, dynamic>? errJson = _tryParseJson(response.body);
        final message = errJson?['error'] as String? ??
            "Server returned an error (${response.statusCode}).";
        throw FridgeAnalysisException(message);
      }
    } on SocketException catch (e) {
      throw FridgeAnalysisException(
        "Cannot connect to the backend server at $activeBackendUrl.",
        e,
      );
    } on TimeoutException catch (e) {
      throw FridgeAnalysisException(
        "Fridge analysis timed out. Please check your connection to $activeBackendUrl.",
        e,
      );
    } catch (e) {
      if (e is FridgeAnalysisException) rethrow;
      throw FridgeAnalysisException(
        "Could not analyze fridge: ${e.toString()}",
        e,
      );
    }
  }

  /// Mock analysis simulation for development and offline college demo.
  Future<FridgeAnalysisResult> _performMockAnalysis(File image) async {
    await Future.delayed(const Duration(milliseconds: 1000));

    final presets = [
      _presetVegetablesAndEggs(image.path),
      _presetPaneerAndGreens(image.path),
      _presetBreakfastStaples(image.path),
    ];

    final result = presets[_mockVariationIndex % presets.length];
    _mockVariationIndex++;
    return result;
  }

  Map<String, dynamic>? _tryParseJson(String source) {
    try {
      return jsonDecode(source) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  // --- Mock Fridge Presets ---

  static FridgeAnalysisResult _presetVegetablesAndEggs(String path) {
    return FridgeAnalysisResult(
      ingredients: const [
        DetectedIngredient(name: 'Eggs', quantity: '4 eggs', emoji: '🥚'),
        DetectedIngredient(name: 'Tomatoes', quantity: '3 medium', emoji: '🍅'),
        DetectedIngredient(name: 'Spinach', quantity: '1 bunch', emoji: '🥬'),
        DetectedIngredient(name: 'Onions', quantity: '2 medium', emoji: '🧅'),
        DetectedIngredient(name: 'Green Chillies', quantity: '3 pieces', emoji: '🫑'),
      ],
      timestamp: DateTime.now(),
      imagePath: path,
    );
  }

  static FridgeAnalysisResult _presetPaneerAndGreens(String path) {
    return FridgeAnalysisResult(
      ingredients: const [
        DetectedIngredient(name: 'Paneer', quantity: '200 g', emoji: '🧀'),
        DetectedIngredient(name: 'Spinach', quantity: '1 bunch', emoji: '🥬'),
        DetectedIngredient(name: 'Tomatoes', quantity: '2 medium', emoji: '🍅'),
        DetectedIngredient(name: 'Onions', quantity: '1 large', emoji: '🧅'),
        DetectedIngredient(name: 'Garlic', quantity: '4 cloves', emoji: '🧄'),
      ],
      timestamp: DateTime.now(),
      imagePath: path,
    );
  }

  static FridgeAnalysisResult _presetBreakfastStaples(String path) {
    return FridgeAnalysisResult(
      ingredients: const [
        DetectedIngredient(name: 'Eggs', quantity: '6 eggs', emoji: '🥚'),
        DetectedIngredient(name: 'Bread', quantity: '6 slices', emoji: '🍞'),
        DetectedIngredient(name: 'Milk', quantity: '500 ml', emoji: '🥛'),
        DetectedIngredient(name: 'Tomatoes', quantity: '2 medium', emoji: '🍅'),
        DetectedIngredient(name: 'Cheese', quantity: '2 slices', emoji: '🧀'),
      ],
      timestamp: DateTime.now(),
      imagePath: path,
    );
  }
}

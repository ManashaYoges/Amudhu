import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../models/fridge_recipe_models.dart';

/// Exception thrown when fridge image analysis fails.
class FridgeAnalysisException implements Exception {
  final String message;
  final dynamic originalError;

  const FridgeAnalysisException(this.message, [this.originalError]);

  @override
  String toString() => message;
}

/// Service responsible for scanning fridge images and identifying ingredients.
class FridgeAnalysisService {
  /// Set to true to use realistic mock data for presentations & offline use.
  /// Set to false when connecting to a live AI Vision backend API.
  static const bool useMockAnalysis = true;

  /// AI Backend URL endpoint.
  /// Configure this with your server endpoint (e.g. https://api.amudhu.example.com/v1/analyze-fridge)
  /// Note: Do NOT hardcode secret API keys directly into Flutter client source code.
  static const String backendApiUrl = 'https://api.amudhu.example.com/v1/analyze-fridge';

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
    } else {
      return _performBackendAnalysis(image);
    }
  }

  /// Mock analysis simulation for development and offline college demo.
  Future<FridgeAnalysisResult> _performMockAnalysis(File image) async {
    // Simulate AI image recognition processing latency (1.6s)
    await Future.delayed(const Duration(milliseconds: 1600));

    final presets = [
      _presetVegetablesAndEggs(image.path),
      _presetPaneerAndGreens(image.path),
      _presetBreakfastStaples(image.path),
    ];

    final result = presets[_mockVariationIndex % presets.length];
    _mockVariationIndex++;
    return result;
  }

  /// Live AI Backend Integration Point.
  /// Uploads fridge photo to your AI vision backend server.
  Future<FridgeAnalysisResult> _performBackendAnalysis(File image) async {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 15);

    try {
      final uri = Uri.parse(backendApiUrl);
      final request = await client.postUrl(uri);

      final imageBytes = await image.readAsBytes();
      final base64Image = base64Encode(imageBytes);

      final payload = jsonEncode({
        'image': base64Image,
        'filename': image.uri.pathSegments.isNotEmpty
            ? image.uri.pathSegments.last
            : 'fridge.jpg',
        'timestamp': DateTime.now().toIso8601String(),
      });

      request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
      request.write(payload);

      final response = await request.close();

      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        final Map<String, dynamic> json = jsonDecode(responseBody);
        final result = FridgeAnalysisResult.fromJson(json, imagePath: image.path);

        if (result.ingredients.isEmpty) {
          throw const FridgeAnalysisException(
            "We couldn't identify any ingredients. Try taking a clearer photo of the inside of your fridge.",
          );
        }

        return result;
      } else if (response.statusCode >= 500) {
        throw const FridgeAnalysisException(
          "We couldn't analyze your fridge right now. Please try again.",
        );
      } else {
        throw const FridgeAnalysisException(
          "Unable to analyze this image right now. Please try again.",
        );
      }
    } on SocketException catch (e) {
      throw FridgeAnalysisException(
        "Please check your internet connection and try again.",
        e,
      );
    } on TimeoutException catch (e) {
      throw FridgeAnalysisException(
        "Analysis timed out. Please check your connection and try again.",
        e,
      );
    } on FormatException catch (e) {
      throw FridgeAnalysisException(
        "Invalid response from analysis server. Please try again.",
        e,
      );
    } catch (e) {
      if (e is FridgeAnalysisException) rethrow;
      throw FridgeAnalysisException(
        "We couldn't analyze your fridge right now. Please try again.",
        e,
      );
    } finally {
      client.close();
    }
  }

  // --- Mock Fridge Presets ---

  static FridgeAnalysisResult _presetVegetablesAndEggs(String path) {
    return FridgeAnalysisResult(
      ingredients: const [
        DetectedIngredient(name: 'Eggs', quantity: '4 eggs', emoji: '🥚'),
        DetectedIngredient(name: 'Tomato', quantity: '3 medium', emoji: '🍅'),
        DetectedIngredient(name: 'Spinach', quantity: '1 bunch', emoji: '🥬'),
        DetectedIngredient(name: 'Onion', quantity: '2 medium', emoji: '🧅'),
        DetectedIngredient(name: 'Green Chili', quantity: '3 pieces', emoji: '🫑'),
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
        DetectedIngredient(name: 'Tomato', quantity: '2 medium', emoji: '🍅'),
        DetectedIngredient(name: 'Onion', quantity: '1 large', emoji: '🧅'),
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
        DetectedIngredient(name: 'Tomato', quantity: '2 medium', emoji: '🍅'),
        DetectedIngredient(name: 'Cheese', quantity: '2 slices', emoji: '🧀'),
      ],
      timestamp: DateTime.now(),
      imagePath: path,
    );
  }
}

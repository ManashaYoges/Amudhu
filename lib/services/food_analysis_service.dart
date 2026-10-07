import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../models/food_analysis_result.dart';

/// Exception thrown when food analysis fails.
class FoodAnalysisException implements Exception {
  final String message;
  final dynamic originalError;

  const FoodAnalysisException(this.message, [this.originalError]);

  @override
  String toString() => message;
}

/// Service responsible for analyzing meal images using AI or mock fallback.
class FoodAnalysisService {
  /// Toggle to switch between mock/demo mode and live backend API.
  /// For demonstration and college project presentations, keep this set to true.
  /// Set to false when connecting to a live AI Vision backend server.
  static const bool useMockAnalysis = true;

  /// AI Backend URL endpoint.
  /// Configure this with your team's backend server URL (e.g., https://amudhu-backend.example.com/api/analyze-plate)
  /// Note: Do NOT store private API keys directly in client source code.
  /// API keys should be securely managed on your backend server.
  static const String backendApiUrl = 'https://api.amudhu.example.com/v1/analyze-plate';

  /// Counter used in mock mode to provide varied, realistic meal recognitions.
  static int _mockVariationIndex = 0;

  /// Analyzes an image of food and returns a structured [FoodAnalysisResult].
  Future<FoodAnalysisResult> analyzeImage(File image) async {
    // 1. Validate image file
    if (!await image.exists()) {
      throw const FoodAnalysisException(
        "We couldn't use that image. Please choose another photo.",
      );
    }

    final fileSize = await image.length();
    if (fileSize == 0) {
      throw const FoodAnalysisException(
        "We couldn't use that image. Please choose another photo.",
      );
    }

    // 2. Perform analysis based on mode
    if (useMockAnalysis) {
      return _performMockAnalysis(image);
    } else {
      return _performBackendAnalysis(image);
    }
  }

  /// Mock analysis simulation for demonstration and offline reliability.
  Future<FoodAnalysisResult> _performMockAnalysis(File image) async {
    // Simulate realistic AI model processing latency (1.8s)
    await Future.delayed(const Duration(milliseconds: 1800));

    // Realistic sample meals for demonstration
    final sampleMeals = [
      _sampleRiceDalGreens(image.path),
      _sampleSouthIndianThali(image.path),
      _sampleChapatiPaneer(image.path),
      _sampleHealthyBreakfast(image.path),
    ];

    final result = sampleMeals[_mockVariationIndex % sampleMeals.length];
    _mockVariationIndex++;
    return result;
  }

  /// Live AI Backend Integration Point.
  /// Connect this function to your secured server or cloud function endpoint.
  Future<FoodAnalysisResult> _performBackendAnalysis(File image) async {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 15);

    try {
      final uri = Uri.parse(backendApiUrl);
      final request = await client.postUrl(uri);

      // Read image bytes and prepare multipart/form-data or base64 payload
      final imageBytes = await image.readAsBytes();
      final base64Image = base64Encode(imageBytes);

      final payload = jsonEncode({
        'image': base64Image,
        'filename': image.uri.pathSegments.isNotEmpty
            ? image.uri.pathSegments.last
            : 'meal.jpg',
        'timestamp': DateTime.now().toIso8601String(),
      });

      request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
      request.write(payload);

      final response = await request.close();

      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        final Map<String, dynamic> json = jsonDecode(responseBody);
        return FoodAnalysisResult.fromJson(json, imagePath: image.path);
      } else if (response.statusCode >= 500) {
        throw const FoodAnalysisException(
          "We couldn't analyze your meal right now. Please try again.",
        );
      } else {
        throw const FoodAnalysisException(
          "Unable to analyze this image right now. Please try again.",
        );
      }
    } on SocketException catch (e) {
      throw FoodAnalysisException(
        "Please check your internet connection and try again.",
        e,
      );
    } on TimeoutException catch (e) {
      throw FoodAnalysisException(
        "Analysis timed out. Please check your connection and try again.",
        e,
      );
    } on FormatException catch (e) {
      throw FoodAnalysisException(
        "Invalid response from analysis server. Please try again.",
        e,
      );
    } catch (e) {
      if (e is FoodAnalysisException) rethrow;
      throw FoodAnalysisException(
        "We couldn't analyze your meal right now. Please try again.",
        e,
      );
    } finally {
      client.close();
    }
  }

  // --- Realistic Sample Presets for Demo Mode ---

  static FoodAnalysisResult _sampleRiceDalGreens(String path) {
    const items = [
      FoodItem(
        name: 'Steamed Rice',
        quantity: '180 g',
        calories: 230,
        protein: 4.5,
        carbs: 50.0,
        fat: 0.5,
        fiber: 1.0,
        sugar: 0.1,
        emoji: '🍚',
      ),
      FoodItem(
        name: 'Lentil Dal',
        quantity: '120 g',
        calories: 140,
        protein: 8.5,
        carbs: 20.0,
        fat: 3.0,
        fiber: 5.0,
        sugar: 1.2,
        emoji: '🥣',
      ),
      FoodItem(
        name: 'Boiled Egg',
        quantity: '1 large',
        calories: 78,
        protein: 6.3,
        carbs: 0.6,
        fat: 5.3,
        fiber: 0.0,
        sugar: 0.6,
        emoji: '🥚',
      ),
      FoodItem(
        name: 'Mixed Vegetables & Greens',
        quantity: '100 g',
        calories: 72,
        protein: 4.7,
        carbs: 11.4,
        fat: 1.2,
        fiber: 3.5,
        sugar: 2.8,
        emoji: '🥦',
      ),
    ];

    return FoodAnalysisResult(
      mealName: 'Rice Bowl with Dal, Egg & Greens',
      foods: items,
      total: const NutritionSummary(
        calories: 520,
        protein: 24.0,
        carbs: 68.0,
        fat: 16.0,
        fiber: 9.0,
        sugar: 7.0,
      ),
      balance: const MealBalance(
        score: 78,
        status: 'Good balance!',
        description:
            'Your meal brings together grains, plant protein, whole eggs, and vegetables. A little more greens could add fiber and variety.',
        tip: 'Try adding a side salad or an extra serving of greens for optimal digestion.',
        amudhuNote:
            'The lentils and egg contribute protein, while vegetables add micronutrients and fiber. Nutrition values are estimates based on standard portion guidelines.',
      ),
      vitaminsAndMinerals: const [
        'Vitamin A  28%',
        'B1  18%',
        'B2  22%',
        'B6  19%',
        'B12  12%',
        'Vitamin C  35%',
        'Vitamin D  8%',
        'Vitamin E  16%',
        'Vitamin K  30%',
        'Calcium  18%',
        'Iron  24%',
        'Magnesium  21%',
        'Potassium  26%',
        'Zinc  14%',
        'Phosphorus  29%',
      ],
      timestamp: DateTime.now(),
      imagePath: path,
    );
  }

  static FoodAnalysisResult _sampleSouthIndianThali(String path) {
    const items = [
      FoodItem(
        name: 'Steamed Idli / Rice',
        quantity: '150 g',
        calories: 195,
        protein: 4.0,
        carbs: 42.0,
        fat: 0.4,
        fiber: 1.2,
        sugar: 0.2,
        emoji: '🍚',
      ),
      FoodItem(
        name: 'Vegetable Sambar',
        quantity: '140 g',
        calories: 130,
        protein: 5.5,
        carbs: 18.0,
        fat: 4.0,
        fiber: 4.0,
        sugar: 2.0,
        emoji: '🥣',
      ),
      FoodItem(
        name: 'Beans & Carrot Poriyal',
        quantity: '110 g',
        calories: 85,
        protein: 3.2,
        carbs: 11.0,
        fat: 3.5,
        fiber: 4.2,
        sugar: 3.1,
        emoji: '🥗',
      ),
      FoodItem(
        name: 'Curd / Yogurt',
        quantity: '100 g',
        calories: 68,
        protein: 4.1,
        carbs: 4.7,
        fat: 3.2,
        fiber: 0.0,
        sugar: 4.0,
        emoji: '🥛',
      ),
    ];

    return FoodAnalysisResult(
      mealName: 'South Indian Balanced Thali',
      foods: items,
      total: const NutritionSummary(
        calories: 478,
        protein: 16.8,
        carbs: 75.7,
        fat: 11.1,
        fiber: 9.4,
        sugar: 9.3,
      ),
      balance: const MealBalance(
        score: 84,
        status: 'Well balanced!',
        description:
            'Great inclusion of fermented curd for probiotics and vegetable poriyal for fiber.',
        tip: 'Consider adding a handful of sprouts or boiled pulses to boost protein to 20g+.',
        amudhuNote:
            'Curd offers beneficial gut bacteria and calcium, while drumstick and vegetables in sambar supply vitamin C and antioxidants.',
      ),
      vitaminsAndMinerals: const [
        'Vitamin A  34%',
        'B12  16%',
        'Vitamin C  42%',
        'Calcium  26%',
        'Iron  18%',
        'Magnesium  20%',
        'Potassium  28%',
        'Folate  22%',
      ],
      timestamp: DateTime.now(),
      imagePath: path,
    );
  }

  static FoodAnalysisResult _sampleChapatiPaneer(String path) {
    const items = [
      FoodItem(
        name: 'Whole Wheat Chapati',
        quantity: '2 pieces',
        calories: 210,
        protein: 6.2,
        carbs: 38.0,
        fat: 3.5,
        fiber: 5.0,
        sugar: 0.8,
        emoji: '🫓',
      ),
      FoodItem(
        name: 'Palak Paneer',
        quantity: '140 g',
        calories: 220,
        protein: 11.5,
        carbs: 8.0,
        fat: 16.0,
        fiber: 3.8,
        sugar: 1.5,
        emoji: '🧀',
      ),
      FoodItem(
        name: 'Cucumber & Onion Salad',
        quantity: '80 g',
        calories: 35,
        protein: 1.1,
        carbs: 7.0,
        fat: 0.3,
        fiber: 2.2,
        sugar: 2.5,
        emoji: '🥗',
      ),
    ];

    return FoodAnalysisResult(
      mealName: 'Chapati with Palak Paneer & Salad',
      foods: items,
      total: const NutritionSummary(
        calories: 465,
        protein: 18.8,
        carbs: 53.0,
        fat: 19.8,
        fiber: 11.0,
        sugar: 4.8,
      ),
      balance: const MealBalance(
        score: 82,
        status: 'High Fiber & Protein!',
        description:
            'Whole wheat and spinach deliver high dietary fiber, and paneer provides rich calcium and protein.',
        tip: 'A squeeze of fresh lemon juice on the salad aids non-heme iron absorption from spinach.',
        amudhuNote:
            'Spinach is packed with folate and vitamin K, while paneer supplies complete dairy protein for muscle maintenance.',
      ),
      vitaminsAndMinerals: const [
        'Vitamin A  48%',
        'Vitamin K  65%',
        'Calcium  32%',
        'Iron  22%',
        'Magnesium  25%',
        'Folate  30%',
      ],
      timestamp: DateTime.now(),
      imagePath: path,
    );
  }

  static FoodAnalysisResult _sampleHealthyBreakfast(String path) {
    const items = [
      FoodItem(
        name: 'Rolled Oats Bowl',
        quantity: '1 bowl (50g dry)',
        calories: 190,
        protein: 6.5,
        carbs: 33.0,
        fat: 3.0,
        fiber: 5.2,
        sugar: 1.0,
        emoji: '🥣',
      ),
      FoodItem(
        name: 'Sliced Banana & Berries',
        quantity: '1 medium',
        calories: 105,
        protein: 1.3,
        carbs: 27.0,
        fat: 0.3,
        fiber: 3.1,
        sugar: 14.4,
        emoji: '🍎',
      ),
      FoodItem(
        name: 'Almonds & Chia Seeds',
        quantity: '15 g',
        calories: 88,
        protein: 3.1,
        carbs: 3.2,
        fat: 7.4,
        fiber: 2.8,
        sugar: 0.4,
        emoji: '🥜',
      ),
    ];

    return FoodAnalysisResult(
      mealName: 'Nutrient-Dense Oatmeal & Fruits',
      foods: items,
      total: const NutritionSummary(
        calories: 383,
        protein: 10.9,
        carbs: 63.2,
        fat: 10.7,
        fiber: 11.1,
        sugar: 15.8,
      ),
      balance: const MealBalance(
        score: 80,
        status: 'Wholesome Morning Energy',
        description:
            'Beta-glucan soluble fiber supports heart health and slow-release sustained energy throughout the morning.',
        tip: 'Add a scoop of protein powder or Greek yogurt if you want to reach 20g+ morning protein.',
        amudhuNote:
            'Chia seeds and almonds supply omega-3 ALA and vitamin E, giving you steady energy without insulin spikes.',
      ),
      vitaminsAndMinerals: const [
        'Vitamin C  18%',
        'Vitamin E  24%',
        'B6  22%',
        'Magnesium  28%',
        'Potassium  21%',
        'Manganese  45%',
      ],
      timestamp: DateTime.now(),
      imagePath: path,
    );
  }
}

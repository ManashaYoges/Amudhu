import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'models/food_analysis_result.dart';
import 'models/fridge_recipe_models.dart';
import 'models/user_profile.dart';
import 'services/auth_service.dart';
import 'services/user_service.dart';
import 'services/food_analysis_service.dart';
import 'services/fridge_analysis_service.dart';
import 'services/meal_storage_service.dart';
import 'services/recipe_generation_service.dart';
import 'services/recipe_search_service.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const AmuduApp());
}

const green = Color(0xFF087832);
const deepGreen = Color(0xFF075B2A);
const mint = Color(0xFFEAF4DF);
const canvas = Color(0xFFFCFBF7);
const ink = Color(0xFF20261F);

class AmuduApp extends StatelessWidget {
  const AmuduApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'அமுது',
    theme: ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: canvas,
      colorScheme: ColorScheme.fromSeed(
        seedColor: green,
        primary: green,
        surface: canvas,
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(
          fontSize: 23,
          fontWeight: FontWeight.w800,
          color: ink,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: ink,
        ),
        bodyMedium: TextStyle(fontSize: 13, color: Color(0xFF687067)),
      ),
    ),
    home: const WelcomeGate(),
  );
}

class WelcomeGate extends StatefulWidget {
  const WelcomeGate({super.key});
  @override
  State<WelcomeGate> createState() => _WelcomeGateState();
}

class _WelcomeGateState extends State<WelcomeGate> {
  bool _guestEntered = false;
  bool _isSignUp = false;
  bool _isLoading = false;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _message(context, 'Please enter your email and password.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await AuthService.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (mounted) {
        _message(context, 'Welcome back!');
      }
    } catch (e) {
      if (mounted) {
        _message(context, AuthService.getErrorMessage(e));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleRegister() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _message(context, 'Please enter email and password.');
      return;
    }

    if (password.length < 6) {
      _message(context, 'Password must be at least 6 characters.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await AuthService.instance.registerWithEmailAndPassword(
        email: email,
        password: password,
        displayName: name.isNotEmpty ? name : null,
      );
      if (mounted) {
        _message(context, 'Account created successfully! Welcome to Amudhu.');
      }
    } catch (e) {
      if (mounted) {
        _message(context, AuthService.getErrorMessage(e));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleForgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _message(context, 'Enter your email address above, then tap Forgot password.');
      return;
    }

    try {
      await AuthService.instance.sendPasswordResetEmail(email);
      if (mounted) {
        _message(context, 'Password reset link sent to $email');
      }
    } catch (e) {
      if (mounted) {
        _message(context, AuthService.getErrorMessage(e));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService.instance.authStateChanges,
      builder: (context, snapshot) {
        final user = snapshot.data;
        if (user != null || _guestEntered) {
          return MainShell(
            onLogout: () {
              setState(() => _guestEntered = false);
            },
          );
        }

        return Scaffold(
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 22),
                    const BrandMark(size: 76),
                    const SizedBox(height: 12),
                    const Text(
                      'அமுது',
                      style: TextStyle(
                        fontSize: 39,
                        fontWeight: FontWeight.w900,
                        color: deepGreen,
                      ),
                    ),
                    const Text(
                      'Your AI Food & Nutrition Companion',
                      style: TextStyle(color: ink),
                    ),
                    const SizedBox(height: 40),
                    Text(
                      _isSignUp ? 'Create Account' : 'Welcome Back!',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _isSignUp
                          ? 'Start your wellness journey with Amudhu.'
                          : 'Fuel your body, nourish your life.',
                    ),
                    const SizedBox(height: 28),
                    if (_isSignUp) ...[
                      FormFieldBox(
                        controller: _nameController,
                        enabled: !_isLoading,
                        icon: Icons.person_outline,
                        label: 'Full Name',
                      ),
                      const SizedBox(height: 12),
                    ],
                    FormFieldBox(
                      controller: _emailController,
                      enabled: !_isLoading,
                      icon: Icons.mail_outline,
                      label: 'Email address',
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 12),
                    FormFieldBox(
                      controller: _passwordController,
                      enabled: !_isLoading,
                      icon: Icons.lock_outline,
                      label: _isSignUp ? 'Password (min. 6 characters)' : 'Password',
                      obscure: true,
                    ),
                    if (!_isSignUp)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _isLoading ? null : _handleForgotPassword,
                          child: const Text('Forgot password?'),
                        ),
                      )
                    else
                      const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _isLoading
                            ? null
                            : (_isSignUp ? _handleRegister : _handleLogin),
                        style: filledStyle,
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(_isSignUp ? 'Sign Up' : 'Log In'),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _isLoading
                            ? null
                            : () => setState(() => _isSignUp = !_isSignUp),
                        style: outlineStyle,
                        child: Text(
                          _isSignUp ? 'Already have an account? Log In' : 'Create an account',
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () => setState(() => _guestEntered = true),
                      child: const Text('Continue as guest'),
                    ),
                    const SizedBox(height: 28),
                    const Text('A little more mindful, one meal at a time 🌿'),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

ButtonStyle get filledStyle => FilledButton.styleFrom(
  backgroundColor: deepGreen,
  foregroundColor: Colors.white,
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
);
ButtonStyle get outlineStyle => OutlinedButton.styleFrom(
  foregroundColor: ink,
  side: const BorderSide(color: Color(0xFFE5E7DF)),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
);
void _message(BuildContext c, String s) =>
    ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(s)));

class MainShell extends StatefulWidget {
  final VoidCallback? onLogout;
  const MainShell({super.key, this.onLogout});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int index = 0;
  late final List<Widget> pages;

  @override
  void initState() {
    super.initState();
    pages = [
      const HomeScreen(),
      const MealPlanScreen(),
      const ChatScreen(),
      const SmartPlateScreen(),
      ProfileScreen(onLogout: widget.onLogout),
    ];
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: IndexedStack(index: index, children: pages),
    ),
    bottomNavigationBar: NavigationBar(
      height: 68,
      selectedIndex: index,
      onDestinationSelected: (i) => setState(() => index = i),
      backgroundColor: Colors.white,
      indicatorColor: mint,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.calendar_month_outlined),
          selectedIcon: Icon(Icons.calendar_month),
          label: 'Meal Plan',
        ),
        NavigationDestination(
          icon: Icon(Icons.chat_bubble_outline),
          selectedIcon: Icon(Icons.chat_bubble),
          label: 'AI Chat',
        ),
        NavigationDestination(
          icon: Icon(Icons.center_focus_weak),
          selectedIcon: Icon(Icons.center_focus_strong),
          label: 'Smart Plate',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    ),
  );
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser;
    final userName = (user?.displayName != null && user!.displayName!.isNotEmpty)
        ? user.displayName!
        : (user?.email != null && user!.email!.contains('@')
            ? user.email!.split('@').first
            : 'Ananya');
    final initial = userName.isNotEmpty ? userName[0].toUpperCase() : 'A';

    return ScreenScroll(
      children: [
        Row(
          children: [
            const BrandMark(size: 35),
            const SizedBox(width: 8),
            const Text(
              'அமுது',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: deepGreen,
              ),
            ),
            const Spacer(),
            IconButton(
              onPressed: () => _message(context, 'You’re all caught up!'),
              icon: const Icon(Icons.notifications_none_rounded),
            ),
            CircleAvatar(
              radius: 19,
              backgroundColor: mint,
              child: Text(
                initial,
                style: const TextStyle(color: deepGreen, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Hello, $userName! 👋',
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 23, color: ink),
        ),
        const SizedBox(height: 4),
        const Text('Let’s make healthy choices today.'),
        const SizedBox(height: 20),
      Row(
        children: [
          const Expanded(
            child: Text(
              'Today’s nutrition',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
          ),
          Text('Oct 4', style: TextStyle(color: Colors.grey.shade600)),
        ],
      ),
      const SizedBox(height: 10),
      CardBox(
        child: Column(
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Your daily balance',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: mint,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'On track',
                    style: TextStyle(
                      color: deepGreen,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '1450',
                        style: TextStyle(
                          fontSize: 27,
                          fontWeight: FontWeight.w900,
                          color: deepGreen,
                        ),
                      ),
                      const Text('of 2000 kcal today'),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(9),
                        child: const LinearProgressIndicator(
                          value: .72,
                          minHeight: 8,
                          backgroundColor: Color(0xFFEAF0E6),
                          color: green,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 17),
                const SizedBox(
                  width: 60,
                  height: 60,
                  child: CircularProgressIndicator(
                    value: .72,
                    strokeWidth: 7,
                    backgroundColor: mint,
                    color: green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Row(
              children: [
                MacroMini(label: 'Protein', value: '72 / 90 g', icon: '💪'),
                MacroMini(label: 'Carbs', value: '180 g', icon: '🌾'),
                MacroMini(label: 'Fat', value: '48 g', icon: '🥑'),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 23),
      const Text(
        'A little nourishment for today',
        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
      ),
      const SizedBox(height: 10),
      CardBox(
        color: const Color(0xFFF1F6E9),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.lightbulb_outline, color: green),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DAILY HEALTH TIP  ·  HYDRATION',
                    style: TextStyle(
                      fontSize: 10,
                      color: deepGreen,
                      fontWeight: FontWeight.w800,
                      letterSpacing: .5,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Keeping a glass of water nearby can make it easier to sip throughout your day.',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                      color: ink,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 22),
      const Text(
        'Quick actions',
        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
      ),
      const SizedBox(height: 10),
      GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.8,
        children: [
          QuickTile(
            icon: '📷',
            title: 'Smart Plate',
            sub: 'Explore your meal',
            onTap: () => _message(
              context,
              'Choose Smart Plate in the bottom navigation',
            ),
          ),
          QuickTile(
            icon: '🧊',
            title: 'Smart Fridge',
            sub: 'What can I cook?',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FridgeScreen()),
            ),
          ),
          QuickTile(
            icon: '✨',
            title: 'Ask Amudu',
            sub: 'Food, simply explained',
            onTap: () =>
                _message(context, 'Tap AI Chat in the bottom navigation'),
          ),
          QuickTile(
            icon: '🍲',
            title: 'Find a recipe',
            sub: 'Cook with what you have',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RecipeScreen()),
            ),
          ),
        ],
      ),
      const SizedBox(height: 22),
      const Text(
        'Today’s meals',
        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
      ),
      const SizedBox(height: 8),
      const MealRow(
        emoji: '🥣',
        meal: 'Breakfast',
        dish: 'Oats + banana',
        kcal: '320 kcal',
      ),
      const MealRow(
        emoji: '🍛',
        meal: 'Lunch',
        dish: 'Rice + dal + vegetables',
        kcal: '520 kcal',
      ),
      const MealRow(
        emoji: '🥗',
        meal: 'Dinner',
        dish: 'Paneer bowl',
        kcal: '450 kcal',
      ),
      const SizedBox(height: 8),
    ],
  );
  }
}

class MealPlanScreen extends StatelessWidget {
  const MealPlanScreen({super.key});
  @override
  Widget build(BuildContext context) => ScreenScroll(
    children: [
      const PageHeading(
        title: 'Meal Plan',
        subtitle: 'A little structure, with room to enjoy.',
      ),
      CardBox(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sunday, October 4',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: ['M', 'T', 'W', 'T', 'F', 'S', 'S']
                  .asMap()
                  .entries
                  .map(
                    (e) => Column(
                      children: [
                        Text(e.value, style: const TextStyle(fontSize: 11)),
                        const SizedBox(height: 7),
                        CircleAvatar(
                          radius: 15,
                          backgroundColor: e.key == 6
                              ? deepGreen
                              : Colors.transparent,
                          child: Text(
                            '${e.key + 1}',
                            style: TextStyle(
                              color: e.key == 6 ? Colors.white : ink,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
      const SectionTitle('Planned for today'),
      const MealRow(
        emoji: '🥣',
        meal: 'Breakfast · 8:00 AM',
        dish: 'Oats with fruits',
        kcal: '320 kcal',
      ),
      const MealRow(
        emoji: '🥗',
        meal: 'Lunch · 1:00 PM',
        dish: 'Quinoa salad',
        kcal: '520 kcal',
      ),
      const MealRow(
        emoji: '🍛',
        meal: 'Dinner · 7:30 PM',
        dish: 'Dal, rice & veggies',
        kcal: '510 kcal',
      ),
      const MealRow(
        emoji: '🥛',
        meal: 'Snack · 4:00 PM',
        dish: 'Greek yogurt',
        kcal: '150 kcal',
      ),
      const SizedBox(height: 12),
      FilledButton.icon(
        onPressed: () => _message(context, 'Meal added to your plan'),
        style: filledStyle,
        icon: const Icon(Icons.add),
        label: const Text('Add a meal'),
      ),
    ],
  );
}

class SmartPlateScreen extends StatefulWidget {
  const SmartPlateScreen({super.key});
  @override
  State<SmartPlateScreen> createState() => _SmartPlateScreenState();
}

class _SmartPlateScreenState extends State<SmartPlateScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  final FoodAnalysisService _analysisService = FoodAnalysisService();

  File? _selectedImage;
  bool _isAnalyzing = false;
  FoodAnalysisResult? _analysisResult;
  String? _errorMessage;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (picked == null) {
        // User cancelled taking photo or picking image
        return;
      }

      setState(() {
        _selectedImage = File(picked.path);
        _analysisResult = null;
        _errorMessage = null;
      });
    } catch (e) {
      String msg;
      final errLower = e.toString().toLowerCase();
      if (errLower.contains('camera_access_denied') ||
          (source == ImageSource.camera && errLower.contains('denied'))) {
        msg = 'Camera permission is required to take a meal photo.';
      } else if (errLower.contains('photo_access_denied') ||
          (source == ImageSource.gallery && errLower.contains('denied'))) {
        msg = 'Photo access is required to choose a meal image.';
      } else {
        msg = "We couldn't use that image. Please choose another photo.";
      }

      setState(() {
        _errorMessage = msg;
      });
      if (mounted) {
        _message(context, msg);
      }
    }
  }

  Future<void> _analyzeMeal() async {
    if (_selectedImage == null || _isAnalyzing) return;

    setState(() {
      _isAnalyzing = true;
      _errorMessage = null;
    });

    try {
      final result = await _analysisService.analyzeImage(_selectedImage!);
      if (!mounted) return;
      setState(() {
        _analysisResult = result;
        _isAnalyzing = false;
      });
    } on FoodAnalysisException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _isAnalyzing = false;
      });
      _message(context, e.message);
    } catch (e) {
      if (!mounted) return;
      const fallbackMsg =
          "We couldn't analyze your meal right now. Please try again.";
      setState(() {
        _errorMessage = fallbackMsg;
        _isAnalyzing = false;
      });
      _message(context, fallbackMsg);
    }
  }

  void _resetMeal() {
    setState(() {
      _selectedImage = null;
      _analysisResult = null;
      _errorMessage = null;
      _isAnalyzing = false;
    });
  }

  Future<void> _saveMeal(FoodAnalysisResult result) async {
    final saved = await MealStorageService.instance.saveMeal(result);
    if (!mounted) return;
    if (saved) {
      _message(context, '${result.mealName} saved to your history!');
      setState(() {});
    } else {
      _message(context, 'This meal is already saved in your history.');
    }
  }

  void _askAmudhu(FoodAnalysisResult result) {
    final buffer = StringBuffer();
    buffer.writeln('I analyzed your meal:');
    buffer.writeln();
    for (final f in result.foods) {
      buffer.writeln('${f.name} – ${f.quantity}');
    }
    buffer.writeln();
    buffer.writeln('Total:');
    buffer.writeln('${result.total.calories} kcal');
    buffer.writeln('${result.total.protein.toStringAsFixed(0)} g protein');
    buffer.writeln('${result.total.carbs.toStringAsFixed(0)} g carbs');
    buffer.writeln('${result.total.fat.toStringAsFixed(0)} g fat');
    buffer.writeln();
    buffer.writeln('What would you like to know?');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          initialMealContext: buffer.toString(),
          asStandalone: true,
        ),
      ),
    );
  }

  void _showImageSourceModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: canvas,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Choose Meal Photo',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: ink,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: mint,
                  child: Icon(Icons.camera_alt_outlined, color: deepGreen),
                ),
                title: const Text(
                  'Take a photo',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: const Text('Snap your plate with device camera'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: mint,
                  child: Icon(Icons.photo_library_outlined, color: deepGreen),
                ),
                title: const Text(
                  'Choose from gallery',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: const Text('Select an existing photo from library'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepRow(String step, String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 13,
          backgroundColor: mint,
          child: Text(
            step,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: deepGreen,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: const TextStyle(fontSize: 11, height: 1.3),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) => ScreenScroll(
    children: [
      const PageHeading(
        title: 'Smart Plate',
        subtitle: 'A closer look at what’s on your plate.',
      ),

      // Error banner
      if (_errorMessage != null) ...[
        Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFDE8E8),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFF8B4B4)),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: Color(0xFFC81E1E), size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(
                    color: Color(0xFF9B1C1C),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => setState(() => _errorMessage = null),
                icon: const Icon(Icons.close, size: 16, color: Color(0xFF9B1C1C)),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
      ],

      // State 1: No image selected (Empty state)
      if (_selectedImage == null) ...[
        CardBox(
          color: const Color(0xFFF1F6E9),
          child: Column(
            children: [
              const Row(
                children: [
                  Text('🍽️', style: TextStyle(fontSize: 38)),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Analyze Your Plate',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: deepGreen,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Take a photo of your meal or upload an existing picture to discover its nutritional value.',
                          style: TextStyle(
                            height: 1.4,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickImage(ImageSource.camera),
                      style: outlineStyle,
                      icon: const Icon(Icons.camera_alt_outlined),
                      label: const Text('Take photo'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickImage(ImageSource.gallery),
                      style: outlineStyle,
                      icon: const Icon(Icons.photo_library_outlined),
                      label: const Text('Upload image'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const SectionTitle('How Smart Plate works'),
        CardBox(
          child: Column(
            children: [
              _buildStepRow(
                '1',
                'Take or upload meal photo',
                'Capture a clear photo of your meal with good lighting.',
              ),
              const Divider(height: 20),
              _buildStepRow(
                '2',
                'AI portion & food recognition',
                'Computer vision identifies ingredients and estimates weights.',
              ),
              const Divider(height: 20),
              _buildStepRow(
                '3',
                'Instant nutrition & meal balance',
                'Receive calories, macronutrients, and tailored balance suggestions.',
              ),
            ],
          ),
        ),
        if (MealStorageService.instance.savedMeals.isNotEmpty) ...[
          const SectionTitle('Recently saved meals'),
          ...MealStorageService.instance.savedMeals.map(
            (m) => MealRow(
              emoji: m.foods.isNotEmpty ? m.foods.first.emoji : '🍛',
              meal: '${m.timestamp.day}/${m.timestamp.month} · ${m.foods.length} items',
              dish: m.mealName,
              kcal: '${m.total.calories} kcal',
            ),
          ),
        ],
      ],

      // State 2: Image selected (Preview & Action Card)
      if (_selectedImage != null) ...[
        CardBox(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    Image.file(
                      _selectedImage!,
                      height: 220,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 200,
                        color: mint,
                        alignment: Alignment.center,
                        child: const Text('Unable to display image preview'),
                      ),
                    ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: Color(0xFF9AD043),
                              size: 14,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Photo Ready',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isAnalyzing ? null : _showImageSourceModal,
                      style: outlineStyle,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Change photo'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _isAnalyzing ? null : _analyzeMeal,
                      style: filledStyle,
                      icon: _isAnalyzing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.auto_awesome),
                      label: Text(_isAnalyzing ? 'Analyzing…' : 'Analyze Meal'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],

      // State 3: Loading animation
      if (_isAnalyzing) ...[
        const SizedBox(height: 14),
        const CardBox(
          color: Color(0xFFF1F6E9),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Column(
              children: [
                SizedBox(
                  width: 38,
                  height: 38,
                  child: CircularProgressIndicator(
                    strokeWidth: 4,
                    color: green,
                    backgroundColor: mint,
                  ),
                ),
                SizedBox(height: 14),
                Text(
                  'Analyzing your meal…',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: deepGreen,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Identifying foods · Estimating portions · Calculating nutrition',
                  style: TextStyle(fontSize: 12, color: ink),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],

      // State 4: Nutrition Results
      if (_analysisResult != null) ...[
        const SizedBox(height: 14),
        const Text(
          FoodAnalysisService.useMockAnalysis
              ? 'DEMO ANALYSIS · ESTIMATED'
              : 'AI ANALYSIS · ESTIMATED',
          style: TextStyle(
            color: deepGreen,
            fontWeight: FontWeight.w800,
            fontSize: 10,
            letterSpacing: .7,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _analysisResult!.mealName,
          style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
        ),
        const Text(
          'Estimated nutrition based on detected foods and portion sizes.',
          style: TextStyle(fontSize: 12),
        ),
        const SectionTitle('Detected foods'),
        ..._analysisResult!.foods.map(
          (food) => FoodLine(
            emoji: food.emoji,
            name: food.name,
            portion: food.quantity,
            kcal: '${food.calories} kcal',
          ),
        ),
        const SectionTitle('Nutrition overview'),
        CardBox(
          child: Column(
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Meal energy',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  Text(
                    '${_analysisResult!.total.calories} kcal',
                    style: const TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.w900,
                      color: deepGreen,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              NutrientBar(
                label: 'Protein',
                value: '${_analysisResult!.total.protein.toStringAsFixed(0)} g',
                p: (_analysisResult!.total.protein / 50.0).clamp(0.0, 1.0),
                color: green,
              ),
              NutrientBar(
                label: 'Carbohydrates',
                value: '${_analysisResult!.total.carbs.toStringAsFixed(0)} g',
                p: (_analysisResult!.total.carbs / 100.0).clamp(0.0, 1.0),
                color: const Color(0xFFD6A632),
              ),
              NutrientBar(
                label: 'Fat',
                value: '${_analysisResult!.total.fat.toStringAsFixed(0)} g',
                p: (_analysisResult!.total.fat / 50.0).clamp(0.0, 1.0),
                color: const Color(0xFFE98A47),
              ),
              NutrientBar(
                label: 'Fiber',
                value: '${_analysisResult!.total.fiber.toStringAsFixed(0)} g',
                p: (_analysisResult!.total.fiber / 25.0).clamp(0.0, 1.0),
                color: const Color(0xFF5C9E83),
              ),
              NutrientBar(
                label: 'Sugar',
                value: '${_analysisResult!.total.sugar.toStringAsFixed(0)} g',
                p: (_analysisResult!.total.sugar / 30.0).clamp(0.0, 1.0),
                color: const Color(0xFFCC7D7D),
              ),
            ],
          ),
        ),
        const SectionTitle('Vitamins & minerals'),
        CardBox(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _analysisResult!.vitaminsAndMinerals
                .map(
                  (x) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: mint,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      x,
                      style: const TextStyle(
                        color: deepGreen,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        const SectionTitle('Meal balance'),
        CardBox(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.spa_outlined, color: green),
                  const SizedBox(width: 8),
                  Text(
                    '${_analysisResult!.balance.status} · ${_analysisResult!.balance.score}/100',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                _analysisResult!.balance.description,
                style: const TextStyle(height: 1.5),
              ),
              const SizedBox(height: 8),
              Text(
                _analysisResult!.balance.tip,
                style: const TextStyle(
                  color: deepGreen,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SectionTitle('A note from Amudu'),
        CardBox(
          color: const Color(0xFFF2F6EC),
          child: Text(
            _analysisResult!.balance.amudhuNote,
            style: const TextStyle(height: 1.5),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: () => _saveMeal(_analysisResult!),
                style: filledStyle,
                icon: const Icon(Icons.bookmark_add_outlined),
                label: const Text('Save meal'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _askAmudhu(_analysisResult!),
                style: outlineStyle,
                icon: const Icon(Icons.chat_bubble_outline),
                label: const Text('Ask Amudu'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _resetMeal,
            style: outlineStyle,
            icon: const Icon(Icons.add_a_photo_outlined),
            label: const Text('Analyze another meal'),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'For health concerns, speak with a qualified healthcare professional.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 10),
        ),
      ],
    ],
  );
}

class ChatScreen extends StatefulWidget {
  final String? initialMealContext;
  final bool asStandalone;

  const ChatScreen({
    super.key,
    this.initialMealContext,
    this.asStandalone = false,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final input = TextEditingController();
  late final List<String> messages;

  @override
  void initState() {
    super.initState();
    if (widget.initialMealContext != null &&
        widget.initialMealContext!.trim().isNotEmpty) {
      messages = [
        widget.initialMealContext!.trim(),
      ];
    } else {
      messages = [
        'Hi Ananya! 👋\nWhat would you like to know about food today?',
        'What are some easy protein-rich snacks?',
        'Try Greek yogurt, roasted chickpeas, boiled eggs, or a handful of nuts. Pair with fruit for a satisfying snack.',
      ];
    }
  }

  @override
  void dispose() {
    input.dispose();
    super.dispose();
  }

  Widget _buildBody() => Column(
    children: [
      if (!widget.asStandalone)
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 18, 20, 8),
          child: PageHeading(
            title: 'AI Food Assistant',
            subtitle: 'Friendly ideas for everyday food choices.',
          ),
        ),
      Expanded(
        child: ListView.builder(
          padding: const EdgeInsets.all(18),
          itemCount: messages.length,
          itemBuilder: (c, i) {
            final bool user = (widget.initialMealContext != null)
                ? (i % 2 == 1)
                : (i == 1 || (i >= 3 && i % 2 == 1));
            return Align(
              alignment: user ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                constraints: const BoxConstraints(maxWidth: 300),
                decoration: BoxDecoration(
                  color: user ? deepGreen : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(.04),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Text(
                  messages[i],
                  style: TextStyle(
                    color: user ? Colors.white : ink,
                    height: 1.4,
                  ),
                ),
              ),
            );
          },
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: input,
                decoration: InputDecoration(
                  hintText: 'Ask about food or nutrition…',
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: () {
                if (input.text.trim().isNotEmpty) {
                  setState(() {
                    messages.add(input.text.trim());
                    messages.add(
                      'That’s a thoughtful question. A balanced, varied diet can help support your everyday nutrition.',
                    );
                    input.clear();
                  });
                }
              },
              icon: const Icon(Icons.arrow_upward),
              style: IconButton.styleFrom(
                backgroundColor: deepGreen,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    if (widget.asStandalone) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Ask Amudhu'),
          backgroundColor: canvas,
        ),
        body: SafeArea(child: _buildBody()),
      );
    }
    return _buildBody();
  }
}

class ProfileScreen extends StatelessWidget {
  final VoidCallback? onLogout;
  const ProfileScreen({super.key, this.onLogout});

  Future<void> _showEditProfileDialog(
    BuildContext context,
    String currentName,
    String uid,
  ) async {
    final textController = TextEditingController(text: currentName);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Profile'),
        content: TextField(
          controller: textController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Full Name',
            hintText: 'Enter your name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, textController.text.trim()),
            style: filledStyle,
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty && context.mounted) {
      try {
        await UserService.instance.updateUserProfile(
          uid: uid,
          displayName: result,
        );
        await AuthService.instance.currentUser?.updateDisplayName(result);
        if (context.mounted) {
          _message(context, 'Profile updated successfully!');
        }
      } catch (e) {
        if (context.mounted) {
          _message(context, AuthService.getErrorMessage(e));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser;

    return ScreenScroll(
      children: [
        const PageHeading(
          title: 'Your profile',
          subtitle: 'Your wellness journey, at your pace.',
        ),
        if (user != null)
          StreamBuilder<UserProfile?>(
            stream: UserService.instance.streamUserProfile(user.uid),
            builder: (context, snapshot) {
              final profile = snapshot.data;
              final displayName = profile?.displayName ??
                  user.displayName ??
                  (user.email != null ? user.email!.split('@').first : 'User');
              final email = profile?.email ?? user.email ?? 'No email';
              final initial = displayName.isNotEmpty
                  ? displayName[0].toUpperCase()
                  : 'U';

              return CardBox(
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 29,
                      backgroundColor: mint,
                      child: Text(
                        initial,
                        style: const TextStyle(
                          fontSize: 24,
                          color: deepGreen,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 17,
                            ),
                          ),
                          Text(email),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => _showEditProfileDialog(
                        context,
                        displayName,
                        user.uid,
                      ),
                      icon: const Icon(Icons.edit_outlined),
                    ),
                  ],
                ),
              );
            },
          )
        else
          CardBox(
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 29,
                  backgroundColor: mint,
                  child: Text(
                    'G',
                    style: TextStyle(
                      fontSize: 24,
                      color: deepGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Guest User',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                        ),
                      ),
                      Text('Using Amudhu in guest mode'),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _message(context, 'Sign in to customize your profile'),
                  icon: const Icon(Icons.edit_outlined),
                ),
              ],
            ),
          ),
        const SectionTitle('Your week'),
        const CardBox(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              StatMini(label: 'Meals logged', value: '28'),
              StatMini(label: 'Calories burned', value: '1,620'),
              StatMini(label: 'Streak', value: '7 days'),
            ],
          ),
        ),
        const SectionTitle('Your goals'),
        const GoalRow(
          icon: Icons.water_drop_outlined,
          title: 'Drink 8 glasses of water',
          progress: '6 / 8 glasses',
          p: .75,
        ),
        const GoalRow(
          icon: Icons.grass_outlined,
          title: 'Eat 30 g of fiber',
          progress: '25 / 30 g',
          p: .83,
        ),
        const SectionTitle('Preferences'),
        CardBox(
          child: Column(
            children: [
              const SettingsRow(
                icon: Icons.restaurant_menu,
                title: 'Diet preference',
                value: 'Vegetarian',
              ),
              const Divider(height: 20),
              const SettingsRow(
                icon: Icons.monitor_weight_outlined,
                title: 'Nutrition goal',
                value: 'Maintain weight',
              ),
              const Divider(height: 20),
              SettingsRow(
                icon: Icons.settings_outlined,
                title: 'Settings & reminders',
                value: 'Manage',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () async {
            await AuthService.instance.signOut();
            MealStorageService.instance.clear();
            onLogout?.call();
            if (context.mounted) {
              _message(context, 'Logged out successfully');
            }
          },
          style: outlineStyle,
          icon: const Icon(Icons.logout),
          label: Text(user != null ? 'Log out' : 'Exit guest mode'),
        ),
      ],
    );
  }
}

class FridgeScreen extends StatefulWidget {
  const FridgeScreen({super.key});

  @override
  State<FridgeScreen> createState() => _FridgeScreenState();
}

class _FridgeScreenState extends State<FridgeScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  final FridgeAnalysisService _analysisService = FridgeAnalysisService();
  final RecipeGenerationService _recipeService = RecipeGenerationService();

  File? _selectedImage;
  bool _isScanning = false;
  bool _isGenerating = false;
  List<DetectedIngredient> _ingredients = [];
  List<Recipe> _recipes = [];
  String? _errorMessage;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (picked == null) return;

      setState(() {
        _selectedImage = File(picked.path);
        _ingredients = [];
        _recipes = [];
        _errorMessage = null;
      });
    } catch (e) {
      String msg;
      final errLower = e.toString().toLowerCase();
      if (errLower.contains('camera_access_denied') ||
          (source == ImageSource.camera && errLower.contains('denied'))) {
        msg = 'Camera permission is required to take a fridge photo.';
      } else if (errLower.contains('photo_access_denied') ||
          (source == ImageSource.gallery && errLower.contains('denied'))) {
        msg = 'Photo access is required to choose a fridge image.';
      } else {
        msg = "We couldn't use that image. Please choose another photo.";
      }

      setState(() {
        _errorMessage = msg;
      });
      if (mounted) {
        _message(context, msg);
      }
    }
  }

  Future<void> _scanFridge() async {
    if (_selectedImage == null || _isScanning) return;

    setState(() {
      _isScanning = true;
      _errorMessage = null;
      _recipes = [];
    });

    try {
      final result = await _analysisService.analyzeImage(_selectedImage!);
      if (!mounted) return;
      if (result.ingredients.isEmpty) {
        throw const FridgeAnalysisException(
          "We couldn't identify any ingredients. Try taking a clearer photo of the inside of your fridge.",
        );
      }
      setState(() {
        _ingredients = List.from(result.ingredients);
        _isScanning = false;
      });
    } on FridgeAnalysisException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _isScanning = false;
      });
      _message(context, e.message);
    } catch (e) {
      if (!mounted) return;
      const fallbackMsg =
          "We couldn't analyze your fridge right now. Please try again.";
      setState(() {
        _errorMessage = fallbackMsg;
        _isScanning = false;
      });
      _message(context, fallbackMsg);
    }
  }

  Future<void> _generateRecipes() async {
    if (_ingredients.isEmpty || _isGenerating) return;

    setState(() {
      _isGenerating = true;
      _errorMessage = null;
    });

    try {
      final results = await _recipeService.generateRecipes(_ingredients);
      if (!mounted) return;
      setState(() {
        _recipes = results;
        _isGenerating = false;
      });
    } on RecipeGenerationException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _isGenerating = false;
      });
      _message(context, e.message);
    } catch (e) {
      if (!mounted) return;
      const fallbackMsg =
          "We couldn't generate recipes right now. Please try again.";
      setState(() {
        _errorMessage = fallbackMsg;
        _isGenerating = false;
      });
      _message(context, fallbackMsg);
    }
  }

  void _removeIngredient(int index) {
    setState(() {
      _ingredients.removeAt(index);
      if (_recipes.isNotEmpty) {
        _recipes = [];
      }
    });
  }

  void _showAddIngredientDialog() {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Add Ingredient',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: TextField(
          controller: textController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'e.g. Cheese, Capsicum, Bread',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final text = textController.text.trim();
              if (text.isNotEmpty) {
                setState(() {
                  _ingredients.add(DetectedIngredient(
                    name: text,
                    quantity: 'Available',
                    emoji: DetectedIngredient.guessEmoji(text),
                  ));
                  if (_recipes.isNotEmpty) {
                    _recipes = [];
                  }
                });
                Navigator.pop(ctx);
              }
            },
            style: filledStyle,
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showImageSourceModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: canvas,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Choose Fridge Photo',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: ink,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: mint,
                  child: Icon(Icons.camera_alt_outlined, color: deepGreen),
                ),
                title: const Text(
                  'Take a photo',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: const Text('Snap the inside of your fridge'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: mint,
                  child: Icon(Icons.photo_library_outlined, color: deepGreen),
                ),
                title: const Text(
                  'Choose from gallery',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: const Text('Select a photo from library'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep(String num, String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: mint,
          child: Text(
            num,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: deepGreen,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
              const SizedBox(height: 2),
              Text(desc, style: const TextStyle(fontSize: 11, height: 1.3)),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Smart Fridge')),
    body: ScreenScroll(
      children: [
        const PageHeading(
          title: 'What’s in your fridge?',
          subtitle: 'Scan your ingredients and discover complete recipes.',
        ),

        // Error message banner
        if (_errorMessage != null) ...[
          Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFDE8E8),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFF8B4B4)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Color(0xFFC81E1E), size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color: Color(0xFF9B1C1C),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => setState(() => _errorMessage = null),
                  icon: const Icon(Icons.close, size: 16, color: Color(0xFF9B1C1C)),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
        ],

        // State 1: No image selected (Empty state)
        if (_selectedImage == null) ...[
          CardBox(
            color: const Color(0xFFF1F6E9),
            child: Column(
              children: [
                const Row(
                  children: [
                    Text('🧊📸', style: TextStyle(fontSize: 38)),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Scan Your Fridge',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: deepGreen,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Take or upload a photo of your fridge to identify ingredients and generate delicious recipes.',
                            style: TextStyle(
                              height: 1.4,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _pickImage(ImageSource.camera),
                        style: outlineStyle,
                        icon: const Icon(Icons.camera_alt_outlined),
                        label: const Text('Take photo'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _pickImage(ImageSource.gallery),
                        style: outlineStyle,
                        icon: const Icon(Icons.photo_library_outlined),
                        label: const Text('Upload image'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const SectionTitle('How Fridge to Recipe works'),
          CardBox(
            child: Column(
              children: [
                _buildStep(
                  '1',
                  'Snap your fridge shelves',
                  'Capture your available produce, dairy, and groceries clearly.',
                ),
                const Divider(height: 20),
                _buildStep(
                  '2',
                  'AI ingredient recognition',
                  'Computer vision detects items, and you can edit or add items.',
                ),
                const Divider(height: 20),
                _buildStep(
                  '3',
                  'Cook matched recipes',
                  'Discover delicious recipes ranked by highest ingredient match.',
                ),
              ],
            ),
          ),
        ],

        // State 2: Image Preview & Scan Action
        if (_selectedImage != null) ...[
          CardBox(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    children: [
                      Image.file(
                        _selectedImage!,
                        height: 220,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 200,
                          color: mint,
                          alignment: Alignment.center,
                          child: const Text('Unable to display image preview'),
                        ),
                      ),
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: Color(0xFF9AD043),
                                size: 14,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Fridge Photo Ready',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isScanning || _isGenerating
                            ? null
                            : _showImageSourceModal,
                        style: outlineStyle,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Change photo'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _isScanning || _isGenerating
                            ? null
                            : _scanFridge,
                        style: filledStyle,
                        icon: _isScanning
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.document_scanner_outlined),
                        label: Text(_isScanning ? 'Scanning…' : 'Scan Fridge'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],

        // State 3: Scanning Progress
        if (_isScanning) ...[
          const SizedBox(height: 14),
          const CardBox(
            color: Color(0xFFF1F6E9),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Column(
                children: [
                  SizedBox(
                    width: 38,
                    height: 38,
                    child: CircularProgressIndicator(
                      strokeWidth: 4,
                      color: green,
                      backgroundColor: mint,
                    ),
                  ),
                  SizedBox(height: 14),
                  Text(
                    'Scanning your fridge…',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: deepGreen,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Identifying ingredients · Checking available items · Finding recipe possibilities',
                    style: TextStyle(fontSize: 12, color: ink),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],

        // State 4: Ingredients Found Management
        if (_ingredients.isNotEmpty) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Ingredients found (${_ingredients.length})',
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
              ),
              TextButton.icon(
                onPressed: _showAddIngredientDialog,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add more'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          CardBox(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Review detected items. Tap ✕ to remove any mistakes or add missing ingredients:',
                  style: TextStyle(fontSize: 11, color: Color(0xFF687067)),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ..._ingredients.asMap().entries.map(
                      (entry) => Chip(
                        avatar: Text(
                          entry.value.emoji,
                          style: const TextStyle(fontSize: 16),
                        ),
                        label: Text(
                          entry.value.quantity.isNotEmpty
                              ? '${entry.value.name} (${entry.value.quantity})'
                              : entry.value.name,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        backgroundColor: mint,
                        side: BorderSide.none,
                        deleteIcon: const Icon(Icons.close, size: 16, color: deepGreen),
                        onDeleted: () => _removeIngredient(entry.key),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.add, size: 16, color: deepGreen),
                      label: const Text(
                        '+ Add Ingredient',
                        style: TextStyle(
                          color: deepGreen,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFFD3E0C8)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      onPressed: _showAddIngredientDialog,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _isGenerating ? null : _generateRecipes,
                    style: filledStyle,
                    icon: _isGenerating
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.auto_awesome),
                    label: Text(_isGenerating
                        ? 'Creating recipes…'
                        : 'Generate Recipes with Ingredients'),
                  ),
                ),
              ],
            ),
          ),
        ],

        // State 5: Generating Recipes Progress
        if (_isGenerating) ...[
          const SizedBox(height: 14),
          const CardBox(
            color: Color(0xFFF1F6E9),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Column(
                children: [
                  SizedBox(
                    width: 38,
                    height: 38,
                    child: CircularProgressIndicator(
                      strokeWidth: 4,
                      color: green,
                      backgroundColor: mint,
                    ),
                  ),
                  SizedBox(height: 14),
                  Text(
                    'Creating recipes…',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: deepGreen,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Matching ingredients · Prioritizing what you have · Preparing step-by-step instructions',
                    style: TextStyle(fontSize: 12, color: ink),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],

        // State 6: Generated Recipes List
        if (_recipes.isNotEmpty) ...[
          const SizedBox(height: 18),
          SectionTitle('Recipes For You (${_recipes.length})'),
          ..._recipes.map(
            (recipe) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RecipeDetailScreen(recipe: recipe),
                  ),
                ),
                borderRadius: BorderRadius.circular(18),
                child: CardBox(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(recipe.emoji, style: const TextStyle(fontSize: 34)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  recipe.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  recipe.description,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF687067),
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right, color: green),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: mint,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.check_circle,
                                  size: 13,
                                  color: deepGreen,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Uses ${recipe.matchedCount} of ${recipe.totalIngredientsCount} items',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: deepGreen,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${recipe.totalTime}  ·  ${recipe.nutrition.calories} kcal',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF687067),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _selectedImage = null;
                  _ingredients = [];
                  _recipes = [];
                  _errorMessage = null;
                  _isScanning = false;
                  _isGenerating = false;
                });
              },
              style: outlineStyle,
              icon: const Icon(Icons.refresh),
              label: const Text('Scan another photo / Start over'),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ],
    ),
  );
}

Future<void> _launchExternalVideoUrl(BuildContext context, String urlString) async {
  try {
    final uri = Uri.parse(urlString);
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      _message(context, 'Could not open video URL: $urlString');
    }
  } catch (e) {
    if (context.mounted) {
      _message(context, 'Unable to open video: $e');
    }
  }
}

String _getCuisineEmoji(String cuisine) {
  final lower = cuisine.toLowerCase();
  if (lower.contains('india')) return '🇮🇳';
  if (lower.contains('ital')) return '🇮🇹';
  if (lower.contains('asia') || lower.contains('chin') || lower.contains('indo') || lower.contains('thai') || lower.contains('japan')) return '🥢';
  if (lower.contains('mexic')) return '🇲🇽';
  if (lower.contains('americ')) return '🇺🇸';
  if (lower.contains('mediter') || lower.contains('greek')) return '🥗';
  if (lower.contains('french')) return '🥖';
  if (lower.contains('middle')) return '🧆';
  return '🍲';
}

class RecipeDetailScreen extends StatelessWidget {
  final Recipe recipe;
  const RecipeDetailScreen({super.key, required this.recipe});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(recipe.name),
        backgroundColor: canvas,
      ),
      body: ScreenScroll(
        children: [
          // Header Card
          CardBox(
            color: const Color(0xFFF1F6E9),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(recipe.emoji, style: const TextStyle(fontSize: 44)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            recipe.name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: deepGreen,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${_getCuisineEmoji(recipe.cuisine)} ${recipe.cuisine}',
                                  style: const TextStyle(
                                    color: deepGreen,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: recipe.isVegetarian
                                      ? const Color(0xFFE8F5E9)
                                      : const Color(0xFFFFEBEE),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  recipe.isVegetarian ? '🥬 Veg' : '🍗 Non-Veg',
                                  style: TextStyle(
                                    color: recipe.isVegetarian
                                        ? const Color(0xFF2E7D32)
                                        : const Color(0xFFC62828),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            recipe.description,
                            style: const TextStyle(fontSize: 12, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMetric('Prep', recipe.prepTime),
                      _buildMetric('Cook', recipe.cookTime),
                      _buildMetric('Total', recipe.totalTime),
                      _buildMetric('Servings', '${recipe.servings}'),
                      _buildMetric('Level', recipe.difficulty),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Ingredient Match Indicator
          if (recipe.matchedCount > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: mint,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFC7E3B2)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: deepGreen,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Uses ${recipe.matchedCount} of ${recipe.totalIngredientsCount} recipe ingredients (${(recipe.matchPercentage * 100).toInt()}% match from your fridge)',
                      style: const TextStyle(
                        color: deepGreen,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Ingredients list
          const SectionTitle('Ingredients'),
          CardBox(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...recipe.ingredients.map(
                  (ing) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Icon(
                          ing.isFromFridge
                              ? Icons.check_circle
                              : Icons.add_circle_outline,
                          size: 18,
                          color: ing.isFromFridge ? green : Colors.grey.shade500,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            ing.name,
                            style: TextStyle(
                              fontWeight: ing.isFromFridge
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: ink,
                            ),
                          ),
                        ),
                        Text(
                          ing.quantity,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: ing.isFromFridge
                                ? mint
                                : const Color(0xFFF2F3ED),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            ing.isFromFridge ? 'In Fridge' : 'Pantry',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: ing.isFromFridge
                                  ? deepGreen
                                  : Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Instructions list
          const SectionTitle('Instructions'),
          CardBox(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...recipe.steps.asMap().entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: mint,
                          child: Text(
                            '${entry.key + 1}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: deepGreen,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            entry.value,
                            style: const TextStyle(height: 1.4, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Nutrition per serving
          const SectionTitle('Estimated nutrition per serving'),
          CardBox(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNutritionPill(
                      'Calories',
                      '${recipe.nutrition.calories} kcal',
                    ),
                    _buildNutritionPill(
                      'Protein',
                      '${recipe.nutrition.protein.toStringAsFixed(0)} g',
                    ),
                    _buildNutritionPill(
                      'Carbs',
                      '${recipe.nutrition.carbs.toStringAsFixed(0)} g',
                    ),
                    _buildNutritionPill(
                      'Fat',
                      '${recipe.nutrition.fat.toStringAsFixed(0)} g',
                    ),
                    _buildNutritionPill(
                      'Fiber',
                      '${recipe.nutrition.fiber.toStringAsFixed(0)} g',
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'Values are AI-assisted culinary estimates for informational purposes.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 10, color: Color(0xFF687067)),
                ),
              ],
            ),
          ),

          // Cooking Video Tutorial Section
          const SectionTitle('Cooking Video Tutorial'),
          CardBox(
            color: const Color(0xFFFFF7F7),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEBEE),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.play_circle_fill_rounded,
                        color: Color(0xFFD32F2F),
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Step-by-step Video Guide',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              color: ink,
                            ),
                          ),
                          Text(
                            recipe.videoUrl != null
                                ? 'Watch chef demonstration for ${recipe.name}'
                                : 'Search and watch video tutorials for ${recipe.name}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF687067),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      final url = recipe.videoUrl ??
                          'https://www.youtube.com/results?search_query=${Uri.encodeComponent("${recipe.name} recipe step by step")}';
                      _launchExternalVideoUrl(context, url);
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFD32F2F),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Watch Cooking Video'),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Action buttons: Cook Now, Ask Amudu
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _message(
                    context,
                    'Great choice! Enjoy cooking your ${recipe.name}!',
                  ),
                  style: filledStyle,
                  icon: const Icon(Icons.check),
                  label: const Text('Cook this recipe'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    final prompt =
                        'I am cooking ${recipe.name} (${recipe.totalTime}).\n'
                        'Ingredients: ${recipe.ingredients.map((i) => "${i.name} (${i.quantity})").join(", ")}.\n\n'
                        'What chef tips or ingredient substitutions can you suggest?';
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(
                          initialMealContext: prompt,
                          asStandalone: true,
                        ),
                      ),
                    );
                  },
                  style: outlineStyle,
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text('Ask Amudu'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _message(
                context,
                '${recipe.name} saved to your favorite recipes!',
              ),
              style: outlineStyle,
              icon: const Icon(Icons.bookmark_border),
              label: const Text('Save recipe'),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildMetric(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 13,
            color: deepGreen,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Color(0xFF687067)),
        ),
      ],
    );
  }

  Widget _buildNutritionPill(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            color: deepGreen,
            fontSize: 13,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Color(0xFF687067)),
        ),
      ],
    );
  }
}

class RecipeScreen extends StatefulWidget {
  final String? initialQuery;
  const RecipeScreen({super.key, this.initialQuery});

  @override
  State<RecipeScreen> createState() => _RecipeScreenState();
}

class _RecipeScreenState extends State<RecipeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final RecipeSearchService _searchService = RecipeSearchService();

  bool _isLoading = false;
  String? _errorMessage;
  RecipeSearchResult? _searchResult;
  String _activeQuery = '';

  // Filter & sort states
  String _selectedCuisine = 'All';
  String _selectedDiet = 'All'; // 'All', 'Vegetarian', 'Non-Veg'
  String _selectedTime = 'All'; // 'All', '≤ 20 min', '≤ 35 min'
  String _selectedSort = 'Relevance'; // 'Relevance', 'Quickest', 'Lowest Calories'

  static const List<String> _popularSuggestions = [
    'Bread',
    'Pasta',
    'Paneer',
    'Chicken',
    'Rice',
    'Biryani',
    'Pizza',
    'Egg',
    'Potato',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null && widget.initialQuery!.trim().isNotEmpty) {
      _searchController.text = widget.initialQuery!.trim();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _performSearch(widget.initialQuery!.trim());
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    final clean = query.trim();
    if (clean.isEmpty) {
      _message(context, 'Please enter an ingredient or dish name');
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _activeQuery = clean;
      _searchController.text = clean;
      _selectedCuisine = 'All';
      _selectedDiet = 'All';
      _selectedTime = 'All';
      _selectedSort = 'Relevance';
    });

    try {
      final result = await _searchService.search(clean);
      if (!mounted) return;
      setState(() {
        _searchResult = result;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _clearSearch() {
    setState(() {
      _searchController.clear();
      _searchResult = null;
      _errorMessage = null;
      _activeQuery = '';
      _selectedCuisine = 'All';
      _selectedDiet = 'All';
      _selectedTime = 'All';
      _selectedSort = 'Relevance';
    });
  }

  List<Recipe> _getFilteredRecipes() {
    if (_searchResult == null) return [];
    var list = List<Recipe>.from(_searchResult!.recipes);

    // Filter by Cuisine
    if (_selectedCuisine != 'All') {
      list = list
          .where((r) => r.cuisine.toLowerCase() == _selectedCuisine.toLowerCase())
          .toList();
    }

    // Filter by Diet
    if (_selectedDiet == 'Vegetarian') {
      list = list.where((r) => r.isVegetarian).toList();
    } else if (_selectedDiet == 'Non-Veg') {
      list = list.where((r) => !r.isVegetarian).toList();
    }

    // Filter by Time
    if (_selectedTime == '≤ 20 min') {
      list = list.where((r) => _parseMinutes(r.totalTime) <= 20).toList();
    } else if (_selectedTime == '≤ 35 min') {
      list = list.where((r) => _parseMinutes(r.totalTime) <= 35).toList();
    }

    // Sort
    if (_selectedSort == 'Quickest') {
      list.sort((a, b) =>
          _parseMinutes(a.totalTime).compareTo(_parseMinutes(b.totalTime)));
    } else if (_selectedSort == 'Lowest Calories') {
      list.sort((a, b) =>
          a.nutrition.calories.compareTo(b.nutrition.calories));
    }

    return list;
  }

  int _parseMinutes(String timeStr) {
    final match = RegExp(r'\d+').firstMatch(timeStr);
    return match != null ? int.tryParse(match.group(0)!) ?? 30 : 30;
  }

  @override
  Widget build(BuildContext context) {
    final filteredRecipes = _getFilteredRecipes();
    final catalog = RecipeGenerationService.getCatalogRecipes();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recipe Explorer'),
        backgroundColor: canvas,
      ),
      body: ScreenScroll(
        children: [
          const PageHeading(
            title: 'Find a Recipe',
            subtitle:
                'Search with any ingredient (e.g. bread, chicken, paneer) or recipe name (e.g. pasta, biryani).',
          ),

          // Search Box
          _buildSearchBox(),
          const SizedBox(height: 12),

          // Popular Suggestion Chips
          _buildPopularChips(),
          const SizedBox(height: 18),

          // Conditional States
          if (_isLoading)
            _buildLoadingState()
          else if (_errorMessage != null)
            _buildErrorState()
          else if (_searchResult != null)
            _buildSearchResults(filteredRecipes)
          else
            _buildInitialState(catalog),
        ],
      ),
    );
  }

  Widget _buildSearchBox() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        textInputAction: TextInputAction.search,
        onSubmitted: (val) => _performSearch(val),
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search, color: green),
          hintText: 'Search recipes or ingredients…',
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_searchController.text.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.clear, size: 20, color: Colors.grey),
                  onPressed: _clearSearch,
                ),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilledButton(
                  onPressed: () => _performSearch(_searchController.text),
                  style: FilledButton.styleFrom(
                    backgroundColor: deepGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    minimumSize: Size.zero,
                  ),
                  child: const Text('Search', style: TextStyle(fontSize: 12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPopularChips() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.auto_awesome, size: 14, color: green),
            const SizedBox(width: 6),
            Text(
              'Popular ideas',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _popularSuggestions.map((query) {
              final isSelected = _activeQuery.toLowerCase() == query.toLowerCase();
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: InkWell(
                  onTap: () => _performSearch(query),
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? deepGreen : Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isSelected ? deepGreen : const Color(0xFFE2E4DC),
                      ),
                    ),
                    child: Text(
                      query,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? Colors.white : ink,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return CardBox(
      color: const Color(0xFFF1F6E9),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Column(
          children: [
            const SizedBox(
              width: 42,
              height: 42,
              child: CircularProgressIndicator(
                strokeWidth: 4,
                color: green,
                backgroundColor: mint,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Finding recipes for "$_activeQuery"…',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: deepGreen,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            const Text(
              'Searching cuisines · Finding written recipes · Compiling cooking videos',
              style: TextStyle(fontSize: 11, color: Color(0xFF687067)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return CardBox(
      color: const Color(0xFFFFF3F3),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFC62828), size: 36),
          const SizedBox(height: 10),
          const Text(
            'Search Error',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Color(0xFFC62828),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _errorMessage ?? 'Something went wrong while finding recipes.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: Color(0xFF555555)),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: () => _performSearch(_activeQuery),
            style: FilledButton.styleFrom(
              backgroundColor: deepGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildInitialState(List<Recipe> catalog) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CardBox(
          color: mint,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text('🧑‍🍳', style: TextStyle(fontSize: 26)),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ready to Cook?',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: deepGreen,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Enter any ingredient or dish name above to discover multi-cuisine recipes & cooking tutorials.',
                      style: TextStyle(fontSize: 11, color: ink),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const SectionTitle('Curated Chef Specials'),
        ...catalog.map(
          (r) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _buildRecipeCard(r),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchResults(List<Recipe> filteredRecipes) {
    final result = _searchResult!;

    if (result.recipes.isEmpty) {
      return _buildNoResultsState();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary bar
        Row(
          children: [
            Expanded(
              child: Text(
                'Found ${result.recipes.length} recipes & ${result.videos.length} videos',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: deepGreen),
              ),
            ),
            TextButton.icon(
              onPressed: _clearSearch,
              icon: const Icon(Icons.close, size: 14),
              label: const Text('Clear', style: TextStyle(fontSize: 12)),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey.shade700,
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Cuisines filter chips
        _buildCuisineFilterRow(result.availableCuisines),
        const SizedBox(height: 10),

        // Diet & Time & Sort filters
        _buildSecondaryFilterRow(),
        const SizedBox(height: 14),

        // Written Recipes Section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SectionTitle('Written Recipes'),
            Text(
              '${filteredRecipes.length} shown',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
            ),
          ],
        ),

        if (filteredRecipes.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Column(
                children: [
                  const Text('🔍', style: TextStyle(fontSize: 32)),
                  const SizedBox(height: 8),
                  Text(
                    'No recipes match the selected filters',
                    style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w600),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedCuisine = 'All';
                        _selectedDiet = 'All';
                        _selectedTime = 'All';
                      });
                    },
                    child: const Text('Reset filters'),
                  ),
                ],
              ),
            ),
          )
        else
          ...filteredRecipes.map(
            (r) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _buildRecipeCard(r),
            ),
          ),

        const SizedBox(height: 16),

        // Cooking Videos Section
        if (result.videos.isNotEmpty) ...[
          _buildCookingVideosSection(result.videos),
          const SizedBox(height: 20),
        ],

        // Recommendations Section
        if (result.relatedRecommendations.isNotEmpty) ...[
          _buildRecommendationsSection(result.relatedRecommendations),
          const SizedBox(height: 14),
        ],
      ],
    );
  }

  Widget _buildNoResultsState() {
    return CardBox(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
        child: Column(
          children: [
            const Text('🍽️', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 12),
            Text(
              'No recipes found for "$_activeQuery"',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: ink),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            const Text(
              'Try searching with common ingredients such as "bread", "chicken", "paneer", or popular dishes like "pasta" or "biryani".',
              style: TextStyle(fontSize: 12, color: Color(0xFF687067)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                ActionChip(
                  label: const Text('Search Bread'),
                  onPressed: () => _performSearch('bread'),
                ),
                ActionChip(
                  label: const Text('Search Paneer'),
                  onPressed: () => _performSearch('paneer'),
                ),
                ActionChip(
                  label: const Text('Search Pasta'),
                  onPressed: () => _performSearch('pasta'),
                ),
              ],
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: _clearSearch,
              style: outlineStyle,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Clear search'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCuisineFilterRow(List<String> cuisines) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: cuisines.map((c) {
          final isSelected = _selectedCuisine.toLowerCase() == c.toLowerCase();
          final emoji = c == 'All' ? '🌐' : _getCuisineEmoji(c);
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: ChoiceChip(
              label: Text('$emoji $c'),
              selected: isSelected,
              selectedColor: mint,
              backgroundColor: Colors.white,
              labelStyle: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? deepGreen : ink,
              ),
              side: BorderSide(
                color: isSelected ? deepGreen : const Color(0xFFE2E4DC),
              ),
              onSelected: (selected) {
                setState(() {
                  _selectedCuisine = selected ? c : 'All';
                });
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSecondaryFilterRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // Diet filter popup or chip
          PopupMenuButton<String>(
            initialValue: _selectedDiet,
            onSelected: (val) => setState(() => _selectedDiet = val),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _selectedDiet != 'All' ? mint : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _selectedDiet != 'All' ? deepGreen : const Color(0xFFE2E4DC),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.filter_alt_outlined,
                    size: 14,
                    color: _selectedDiet != 'All' ? deepGreen : ink,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _selectedDiet == 'All' ? 'Diet: All' : _selectedDiet,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _selectedDiet != 'All' ? deepGreen : ink,
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down, size: 16),
                ],
              ),
            ),
            itemBuilder: (ctx) => const [
              PopupMenuItem(value: 'All', child: Text('Diet: All')),
              PopupMenuItem(value: 'Vegetarian', child: Text('🥬 Vegetarian')),
              PopupMenuItem(value: 'Non-Veg', child: Text('🍗 Non-Veg')),
            ],
          ),
          const SizedBox(width: 8),

          // Time filter
          PopupMenuButton<String>(
            initialValue: _selectedTime,
            onSelected: (val) => setState(() => _selectedTime = val),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _selectedTime != 'All' ? mint : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _selectedTime != 'All' ? deepGreen : const Color(0xFFE2E4DC),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 14,
                    color: _selectedTime != 'All' ? deepGreen : ink,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _selectedTime == 'All' ? 'Time: All' : _selectedTime,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _selectedTime != 'All' ? deepGreen : ink,
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down, size: 16),
                ],
              ),
            ),
            itemBuilder: (ctx) => const [
              PopupMenuItem(value: 'All', child: Text('Time: All')),
              PopupMenuItem(value: '≤ 20 min', child: Text('⚡ Quick (≤ 20 min)')),
              PopupMenuItem(value: '≤ 35 min', child: Text('⏱️ Medium (≤ 35 min)')),
            ],
          ),
          const SizedBox(width: 8),

          // Sort selector
          PopupMenuButton<String>(
            initialValue: _selectedSort,
            onSelected: (val) => setState(() => _selectedSort = val),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _selectedSort != 'Relevance' ? mint : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _selectedSort != 'Relevance' ? deepGreen : const Color(0xFFE2E4DC),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.sort,
                    size: 14,
                    color: _selectedSort != 'Relevance' ? deepGreen : ink,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Sort: $_selectedSort',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _selectedSort != 'Relevance' ? deepGreen : ink,
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down, size: 16),
                ],
              ),
            ),
            itemBuilder: (ctx) => const [
              PopupMenuItem(value: 'Relevance', child: Text('Sort: Relevance')),
              PopupMenuItem(value: 'Quickest', child: Text('Sort: Quickest')),
              PopupMenuItem(value: 'Lowest Calories', child: Text('Sort: Lowest Calories')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecipeCard(Recipe r) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RecipeDetailScreen(recipe: r),
        ),
      ),
      borderRadius: BorderRadius.circular(20),
      child: CardBox(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F6EC),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: Text(r.emoji, style: const TextStyle(fontSize: 28)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: ink,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: mint,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${_getCuisineEmoji(r.cuisine)} ${r.cuisine}',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: deepGreen,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: r.isVegetarian
                                  ? const Color(0xFFE8F5E9)
                                  : const Color(0xFFFFEBEE),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              r.isVegetarian ? '🥬 Veg' : '🍗 Non-Veg',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: r.isVegetarian
                                    ? const Color(0xFF2E7D32)
                                    : const Color(0xFFC62828),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: green),
              ],
            ),
            if (r.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                r.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, height: 1.35, color: Color(0xFF555555)),
              ),
            ],
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAF7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 13, color: Color(0xFF687067)),
                      const SizedBox(width: 4),
                      Text(r.totalTime, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(Icons.local_fire_department, size: 13, color: Colors.orange),
                      const SizedBox(width: 4),
                      Text('${r.nutrition.calories} kcal', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: deepGreen)),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(Icons.bar_chart, size: 13, color: Color(0xFF687067)),
                      const SizedBox(width: 4),
                      Text(r.difficulty, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCookingVideosSection(List<CookingVideo> videos) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.videocam_rounded, color: Color(0xFFD32F2F), size: 20),
            const SizedBox(width: 6),
            const Expanded(
              child: Text(
                'Related Cooking Videos',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: ink),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${videos.length} tutorials',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFD32F2F),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Watch step-by-step video tutorials and compilations for "$_activeQuery".',
          style: const TextStyle(fontSize: 11, color: Color(0xFF687067)),
        ),
        const SizedBox(height: 10),
        ...videos.map(
          (v) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _buildVideoCard(v),
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              final queryUrl =
                  'https://www.youtube.com/results?search_query=${Uri.encodeComponent("$_activeQuery recipes step by step")}';
              _launchExternalVideoUrl(context, queryUrl);
            },
            style: outlineStyle,
            icon: const Icon(Icons.smart_display_outlined, color: Color(0xFFD32F2F), size: 18),
            label: Text('Search more "$_activeQuery" videos on YouTube'),
          ),
        ),
      ],
    );
  }

  Widget _buildVideoCard(CookingVideo v) {
    return InkWell(
      onTap: () => _launchExternalVideoUrl(context, v.videoUrl),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF0F0EA)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Video Thumbnail Box
            Container(
              width: 72,
              height: 54,
              decoration: BoxDecoration(
                color: const Color(0xFF263238),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(
                    Icons.play_circle_fill_rounded,
                    color: Color(0xFFE53935),
                    size: 28,
                  ),
                  Positioned(
                    bottom: 3,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(.75),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        v.duration,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Title & Channel
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    v.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: ink,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.account_circle_outlined, size: 12, color: Color(0xFF687067)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          v.channelName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11, color: Color(0xFF687067)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.open_in_new, size: 16, color: Color(0xFFD32F2F)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationsSection(List<String> recommendations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.lightbulb, size: 16, color: Color(0xFFF57C00)),
            SizedBox(width: 6),
            Text(
              'You might also like',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: ink),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          'Tap any recommendation to discover curated recipes and tutorials.',
          style: TextStyle(fontSize: 11, color: Color(0xFF687067)),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: recommendations.map((rec) {
            return InkWell(
              onTap: () => _performSearch(rec),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: mint,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFD4E7BF)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.search, size: 12, color: deepGreen),
                    const SizedBox(width: 5),
                    Text(
                      rec,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: deepGreen,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Settings')),
    body: ScreenScroll(
      children: [
        const SettingsRow(
          icon: Icons.notifications_outlined,
          title: 'Meal reminders',
          value: 'On',
        ),
        const SettingsRow(
          icon: Icons.water_drop_outlined,
          title: 'Hydration reminders',
          value: 'On',
        ),
        const SettingsRow(
          icon: Icons.straighten,
          title: 'Units',
          value: 'Metric',
        ),
        const SettingsRow(
          icon: Icons.privacy_tip_outlined,
          title: 'Privacy policy',
          value: 'View',
        ),
      ],
    ),
  );
}

class ScreenScroll extends StatelessWidget {
  final List<Widget> children;
  const ScreenScroll({super.key, required this.children});
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(18, 14, 18, 22),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    ),
  );
}

class BrandMark extends StatelessWidget {
  final double size;
  const BrandMark({super.key, required this.size});
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: const BoxDecoration(shape: BoxShape.circle, color: deepGreen),
    child: Icon(
      Icons.spa_rounded,
      color: const Color(0xFF9AD043),
      size: size * .72,
    ),
  );
}

class FormFieldBox extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool obscure;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final bool enabled;

  const FormFieldBox({
    super.key,
    required this.icon,
    required this.label,
    this.obscure = false,
    this.controller,
    this.keyboardType,
    this.enabled = true,
  });
  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    enabled: enabled,
    keyboardType: keyboardType,
    obscureText: obscure,
    decoration: InputDecoration(
      prefixIcon: Icon(icon, size: 19),
      hintText: label,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE7E8E1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE7E8E1)),
      ),
    ),
  );
}

class CardBox extends StatelessWidget {
  final Widget child;
  final Color color;
  const CardBox({super.key, required this.child, this.color = Colors.white});
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(.045),
          blurRadius: 15,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: child,
  );
}

class PageHeading extends StatelessWidget {
  final String title, subtitle;
  const PageHeading({super.key, required this.title, required this.subtitle});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: ink,
          ),
        ),
        const SizedBox(height: 4),
        Text(subtitle),
      ],
    ),
  );
}

class MacroMini extends StatelessWidget {
  final String label, value, icon;
  const MacroMini({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
  });
  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: canvas,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
          ),
          Text(label, style: const TextStyle(fontSize: 10)),
        ],
      ),
    ),
  );
}

class QuickTile extends StatelessWidget {
  final String icon, title, sub;
  final VoidCallback onTap;
  const QuickTile({
    super.key,
    required this.icon,
    required this.title,
    required this.sub,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(18),
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(.04), blurRadius: 10),
        ],
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
                Text(
                  sub,
                  style: const TextStyle(fontSize: 10),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class MealRow extends StatelessWidget {
  final String emoji, meal, dish, kcal;
  const MealRow({
    super.key,
    required this.emoji,
    required this.meal,
    required this.dish,
    required this.kcal,
  });
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: mint,
            borderRadius: BorderRadius.circular(13),
          ),
          child: Center(
            child: Text(emoji, style: const TextStyle(fontSize: 23)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                meal,
                style: const TextStyle(
                  fontSize: 10,
                  color: deepGreen,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(dish, style: const TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
        ),
        Text(
          kcal,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
        ),
      ],
    ),
  );
}

class SectionTitle extends StatelessWidget {
  final String text;
  const SectionTitle(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(0, 20, 0, 9),
    child: Text(
      text,
      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
    ),
  );
}

class FoodLine extends StatelessWidget {
  final String emoji, name, portion, kcal;
  const FoodLine({
    super.key,
    required this.emoji,
    required this.name,
    required this.portion,
    required this.kcal,
  });
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 7),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
    ),
    child: Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 22)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
              Text(portion, style: const TextStyle(fontSize: 11)),
            ],
          ),
        ),
        Text(
          kcal,
          style: const TextStyle(
            color: deepGreen,
            fontWeight: FontWeight.w800,
            fontSize: 12,
          ),
        ),
        IconButton(
          onPressed: () => _message(context, 'Edit portion (demo)'),
          icon: const Icon(Icons.more_horiz),
          visualDensity: VisualDensity.compact,
        ),
      ],
    ),
  );
}

class NutrientBar extends StatelessWidget {
  final String label, value;
  final double p;
  final Color color;
  const NutrientBar({
    super.key,
    required this.label,
    required this.value,
    required this.p,
    required this.color,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: LinearProgressIndicator(
            value: p,
            minHeight: 6,
            color: color,
            backgroundColor: const Color(0xFFF0F1EA),
          ),
        ),
      ],
    ),
  );
}

class StatMini extends StatelessWidget {
  final String label, value;
  const StatMini({super.key, required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        value,
        style: const TextStyle(
          fontWeight: FontWeight.w900,
          color: deepGreen,
          fontSize: 19,
        ),
      ),
      Text(label, style: const TextStyle(fontSize: 10)),
    ],
  );
}

class GoalRow extends StatelessWidget {
  final IconData icon;
  final String title, progress;
  final double p;
  const GoalRow({
    super.key,
    required this.icon,
    required this.title,
    required this.progress,
    required this.p,
  });
  @override
  Widget build(BuildContext context) => CardBox(
    child: Column(
      children: [
        Row(
          children: [
            Icon(icon, color: green),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            Text(
              progress,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: p,
            minHeight: 6,
            color: green,
            backgroundColor: mint,
          ),
        ),
      ],
    ),
  );
}

class SettingsRow extends StatelessWidget {
  final IconData icon;
  final String title, value;
  final VoidCallback? onTap;
  const SettingsRow({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    this.onTap,
  });
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      dense: true,
      leading: Icon(icon, color: green),
      title: Text(
        title,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: const TextStyle(fontSize: 11)),
          const Icon(Icons.chevron_right, size: 17),
        ],
      ),
    ),
  );
}

class IngredientChip extends StatelessWidget {
  final String text;
  const IngredientChip(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Chip(
    label: Text(text),
    backgroundColor: Colors.white,
    side: BorderSide.none,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
  );
}

class RecipeRow extends StatelessWidget {
  final String emoji, title, meta;
  final VoidCallback? onTap;
  const RecipeRow({
    super.key,
    required this.emoji,
    required this.title,
    required this.meta,
    this.onTap,
  });
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(20),
    child: CardBox(
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 32)),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
                Text(meta, style: const TextStyle(fontSize: 11)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: green),
        ],
      ),
    ),
  );
}

import 'package:flutter/material.dart';

void main() => runApp(const AmuduApp());

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
  bool entered = false;
  @override
  Widget build(BuildContext context) => entered
      ? const MainShell()
      : Scaffold(
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
                    const SizedBox(height: 52),
                    const Text(
                      'Welcome Back!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text('Fuel your body, nourish your life.'),
                    const SizedBox(height: 28),
                    const FormFieldBox(
                      icon: Icons.mail_outline,
                      label: 'Email address',
                    ),
                    const SizedBox(height: 12),
                    const FormFieldBox(
                      icon: Icons.lock_outline,
                      label: 'Password',
                      obscure: true,
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => _message(
                          context,
                          'Password reset link sent (demo)',
                        ),
                        child: const Text('Forgot password?'),
                      ),
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => setState(() => entered = true),
                        style: filledStyle,
                      
                        child: const Text('Log In'),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => setState(() => entered = true),
                        style: outlineStyle,
                
                        child: const Text('Create an account'),
                      ),
                    ),
                    TextButton(
                      onPressed: () => setState(() => entered = true),
                      child: const Text('Continue as guest'),
                    ),
                    const SizedBox(height: 32),
                    const Text('A little more mindful, one meal at a time 🌿'),
                  ],
                ),
              ),
            ),
          ),
        );
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
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int index = 0;
  final pages = const [
    HomeScreen(),
    MealPlanScreen(),
    ChatScreen(),
    SmartPlateScreen(),
    ProfileScreen(),
  ];
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
  Widget build(BuildContext context) => ScreenScroll(
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
          const CircleAvatar(
            radius: 19,
            backgroundColor: mint,
            child: Text(
              'A',
              style: TextStyle(color: deepGreen, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      const Text(
        'Hello, Ananya! 👋',
        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 23, color: ink),
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
  @override
  Widget build(BuildContext context) => ScreenScroll(
    children: [
      const PageHeading(
        title: 'Smart Plate',
        subtitle: 'A closer look at what’s on your plate.',
      ),
      CardBox(
        color: const Color(0xFFF1F6E9),
        child: Column(
          children: [
            const Row(
              children: [
                Text('🍚🥦', style: TextStyle(fontSize: 38)),
                SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'Your plate, understood\nPhoto-based nutrition estimates, made useful.',
                    style: TextStyle(height: 1.5, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _message(context, 'Camera ready (demo)'),
                    style: outlineStyle,
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: const Text('Take photo'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        _message(context, 'Image picker ready (demo)'),
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
      const SizedBox(height: 12),
      const Text(
        'DEMO ANALYSIS · ESTIMATED',
        style: TextStyle(
          color: deepGreen,
          fontWeight: FontWeight.w800,
          fontSize: 10,
          letterSpacing: .7,
        ),
      ),
      const SizedBox(height: 6),
      const Text(
        'Rice bowl with dal & greens',
        style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
      ),
      const Text(
        'Estimated nutrition based on detected foods and portion sizes.',
        style: TextStyle(fontSize: 12),
      ),
      const SectionTitle('Detected foods'),
      const FoodLine(
        emoji: '🍚',
        name: 'Steamed rice',
        portion: '180 g',
        kcal: '230 kcal',
      ),
      const FoodLine(
        emoji: '🥣',
        name: 'Lentil dal',
        portion: '120 g',
        kcal: '140 kcal',
      ),
      const FoodLine(
        emoji: '🥚',
        name: 'Boiled egg',
        portion: '1 large',
        kcal: '78 kcal',
      ),
      const FoodLine(
        emoji: '🥦',
        name: 'Mixed vegetables',
        portion: '100 g',
        kcal: '72 kcal',
      ),
      TextButton.icon(
        onPressed: () => _message(context, 'Food editor opened (demo)'),
        icon: const Icon(Icons.add),
        label: const Text('Add or edit foods'),
      ),
      const SectionTitle('Nutrition overview'),
      CardBox(
        child: Column(
          children: [
            const Row(
              children: [
                Expanded(
                  child: Text(
                    'Meal energy',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                Text(
                  '520 kcal',
                  style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                    color: deepGreen,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const NutrientBar(
              label: 'Protein',
              value: '24 g',
              p: .52,
              color: green,
            ),
            const NutrientBar(
              label: 'Carbohydrates',
              value: '68 g',
              p: .70,
              color: Color(0xFFD6A632),
            ),
            const NutrientBar(
              label: 'Fat',
              value: '16 g',
              p: .32,
              color: Color(0xFFE98A47),
            ),
            const NutrientBar(
              label: 'Fiber',
              value: '9 g',
              p: .42,
              color: Color(0xFF5C9E83),
            ),
            const NutrientBar(
              label: 'Sugar',
              value: '7 g',
              p: .18,
              color: Color(0xFFCC7D7D),
            ),
          ],
        ),
      ),
      const SectionTitle('Vitamins & minerals'),
      CardBox(
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              [
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
                  ]
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
      const CardBox(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.spa_outlined, color: green),
                SizedBox(width: 8),
                Text(
                  'A balanced start · 78/100',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ],
            ),
            SizedBox(height: 10),
            Text(
              'Your meal brings together grains, plant protein and vegetables. A little more greens could add fiber and variety.',
              style: TextStyle(height: 1.5),
            ),
            SizedBox(height: 8),
            Text(
              'Try adding a side salad or an extra serving of greens.',
              style: TextStyle(color: deepGreen, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
      const SectionTitle('A note from Amudu'),
      const CardBox(
        color: Color(0xFFF2F6EC),
        child: Text(
          'The lentils and egg contribute protein, while vegetables add variety. Nutrition values are estimates and may vary with ingredients and preparation.',
          style: TextStyle(height: 1.5),
        ),
      ),
      const SizedBox(height: 10),
      Row(
        children: [
          Expanded(
            child: FilledButton.icon(
              onPressed: () => _message(context, 'Meal saved to your history'),
              style: filledStyle,
              icon: const Icon(Icons.bookmark_add_outlined),
              label: const Text('Save meal'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () =>
                  _message(context, 'Meal context added to AI Chat'),
              style: outlineStyle,
              icon: const Icon(Icons.chat_bubble_outline),
              label: const Text('Ask Amudu'),
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      const Text(
        'For health concerns, speak with a qualified healthcare professional.',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 10),
      ),
    ],
  );
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final input = TextEditingController();
  final messages = <String>[
    'Hi Ananya! 👋\nWhat would you like to know about food today?',
    'What are some easy protein-rich snacks?',
    'Try Greek yogurt, roasted chickpeas, boiled eggs, or a handful of nuts. Pair with fruit for a satisfying snack.',
  ];
  @override
  Widget build(BuildContext context) => Column(
    children: [
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
            final user = i == 1;
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
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context) => ScreenScroll(
    children: [
      const PageHeading(
        title: 'Your profile',
        subtitle: 'Your wellness journey, at your pace.',
      ),
      CardBox(
        child: Row(
          children: [
            const CircleAvatar(
              radius: 29,
              backgroundColor: mint,
              child: Text(
                'A',
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
                    'Ananya Sharma',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
                  ),
                  Text('ananya@example.com'),
                ],
              ),
            ),
            IconButton(
              onPressed: () => _message(context, 'Edit profile (demo)'),
              icon: const Icon(Icons.edit_outlined),
            ),
          ],
        ),
      ),
      const SectionTitle('Your week'),
      CardBox(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            const StatMini(label: 'Meals logged', value: '28'),
            const StatMini(label: 'Calories burned', value: '1,620'),
            const StatMini(label: 'Streak', value: '7 days'),
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
            SettingsRow(
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
        onPressed: () => _message(context, 'You are using demo mode'),
        style: outlineStyle,
        icon: const Icon(Icons.logout),
        label: const Text('Log out'),
      ),
    ],
  );
}

class FridgeScreen extends StatelessWidget {
  const FridgeScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Smart Fridge')),
    body: ScreenScroll(
      children: [
        const PageHeading(
          title: 'What’s in your fridge?',
          subtitle: 'Add ingredients and find something lovely to make.',
        ),
        CardBox(
          child: Column(
            children: [
              const Text('📸', style: TextStyle(fontSize: 40)),
              const Text(
                'Snap a photo of your ingredients',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: () => _message(context, 'Image picker ready (demo)'),
                style: filledStyle,
                child: const Text('Take or upload photo'),
              ),
            ],
          ),
        ),
        const SectionTitle('Detected ingredients · demo'),
        const Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            IngredientChip('🥚 Eggs'),
            IngredientChip('🍅 Tomato'),
            IngredientChip('🥬 Spinach'),
            IngredientChip('🧅 Onion'),
          ],
        ),
        const SectionTitle('Ideas for your ingredients'),
        const RecipeRow(
          emoji: '🍳',
          title: 'Spinach omelette',
          meta: '15 min · 280 kcal',
        ),
        const RecipeRow(
          emoji: '🍅',
          title: 'Tomato egg bowl',
          meta: '20 min · 340 kcal',
        ),
        const RecipeRow(
          emoji: '🥘',
          title: 'Vegetable egg scramble',
          meta: '18 min · 310 kcal',
        ),
      ],
    ),
  );
}

class RecipeScreen extends StatelessWidget {
  const RecipeScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Recipe ideas')),
    body: ScreenScroll(
      children: [
        const PageHeading(
          title: 'Made for your mood',
          subtitle: 'Simple recipes for a feel-good meal.',
        ),
        const RecipeRow(
          emoji: '🥑',
          title: 'Avocado chickpea toast',
          meta: '15 min · 360 kcal · High fiber',
        ),
        const RecipeRow(
          emoji: '🥗',
          title: 'Colorful quinoa bowl',
          meta: '25 min · 420 kcal · Vegetarian',
        ),
        const RecipeRow(
          emoji: '🍲',
          title: 'Ginger lentil soup',
          meta: '30 min · 390 kcal · Comforting',
        ),
      ],
    ),
  );
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
  const FormFieldBox({
    super.key,
    required this.icon,
    required this.label,
    this.obscure = false,
  });
  @override
  Widget build(BuildContext context) => TextField(
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
  Widget build(BuildContext context) => ListTile(
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
  const RecipeRow({
    super.key,
    required this.emoji,
    required this.title,
    required this.meta,
  });
  @override
  Widget build(BuildContext context) => CardBox(
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
  );
}

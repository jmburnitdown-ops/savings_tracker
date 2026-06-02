import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'firebase_options.dart';
import 'login_page.dart';
import 'providers/savings_provider.dart';
import 'providers/currency_provider.dart'; 
import 'widgets/animated_background.dart';
import 'widgets/profile_inspector.dart';
import 'widgets/goal_widgets.dart';
import 'widgets/digital_clock_widget.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await Hive.initFlutter();
  Hive.registerAdapter(SavingsGoalAdapter());
  Hive.registerAdapter(LedgerTransactionAdapter());

  final savingsProvider = SavingsProvider();
  await savingsProvider.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: savingsProvider),
        ChangeNotifierProvider(create: (_) => CurrencyProvider()..fetchPhpRates()),
      ],
      child: const SavingsTrackerApp(),
    ),
  );
}

class SavingsTrackerApp extends StatefulWidget {
  const SavingsTrackerApp({super.key});
  @override
  State<SavingsTrackerApp> createState() => _SavingsTrackerAppState();
}

class _SavingsTrackerAppState extends State<SavingsTrackerApp> {
  ThemeMode _themeMode = ThemeMode.dark;
  bool _animationsEnabled = true;

  void toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    });
  }

  void toggleAnimations() {
    setState(() {
      _animationsEnabled = !_animationsEnabled;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ApexSaver Tracker',
      theme: ThemeData(useMaterial3: true, brightness: Brightness.light, colorSchemeSeed: Colors.red),
      darkTheme: ThemeData(useMaterial3: true, brightness: Brightness.dark, colorSchemeSeed: Colors.red),
      themeMode: _themeMode,
      home: AuthGate(
        toggleTheme: toggleTheme,
        animationsEnabled: _animationsEnabled,
        toggleAnimations: toggleAnimations,
      ),
    );
  }
}

class AuthGate extends StatefulWidget {
  final VoidCallback toggleTheme;
  final bool animationsEnabled;
  final VoidCallback toggleAnimations;

  const AuthGate({
    super.key,
    required this.toggleTheme,
    required this.animationsEnabled,
    required this.toggleAnimations,
  });

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasData) {
          // Load user profile from Firebase when authenticated
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            await context.read<SavingsProvider>().loadUserProfileFromFirebase(snapshot.data!.uid);
          });
          return MainScreen(
            toggleTheme: widget.toggleTheme,
            animationsEnabled: widget.animationsEnabled,
            toggleAnimations: widget.toggleAnimations,
          );
        }
        return LoginScreen(animationsEnabled: widget.animationsEnabled);
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  final VoidCallback toggleTheme;
  final bool animationsEnabled;
  final VoidCallback toggleAnimations;

  const MainScreen({
    super.key,
    required this.toggleTheme,
    required this.animationsEnabled,
    required this.toggleAnimations,
  });
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  bool _showProfilePane = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SavingsProvider>(context);
    final theme = Theme.of(context);
    bool isViewingTabs = provider.activeGoal != null;
    final filteredGoals = provider.goals.where((goal) =>
        goal.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surfaceContainer,
        // Replace the title Row in your MainScreen AppBar with this:
title: Row(
  children: [
    Image.asset('assets/apexsaver_logo.png', height: 32, width: 32,
        errorBuilder: (context, error, stackTrace) => Icon(Icons.change_history_rounded, color: theme.colorScheme.primary)),
    const SizedBox(width: 12),
    Text('ApexSaver Hub', style: TextStyle(color: theme.colorScheme.onSurface)),
    const SizedBox(width: 30), // Increased spacing here
    
    // Time and Date (Clock)
    DigitalClockWidget(fontSize: 14, textColor: theme.colorScheme.onSurfaceVariant),
    
    const SizedBox(width: 40), // Pushes the currency farther away
    
    // Currency Display (Styled to match clock size)
    Consumer<CurrencyProvider>(
      builder: (context, curr, _) => curr.isLoading 
        ? const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2))
        : Text(
            "USD: ${curr.getRate('USD')?.toStringAsFixed(2)}  |  "
            "JPY: ${curr.getRate('JPY')?.toStringAsFixed(2)}  |  "
            "WON: ${curr.getRate('KRW')?.toStringAsFixed(2)}  |  "
            "GBP: ${curr.getRate('GBP')?.toStringAsFixed(2)}",
            style: TextStyle(
              fontSize: 14, // Matches DigitalClockWidget size
              fontWeight: FontWeight.w500, // Slightly bolder for better visibility
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    ),
        actions: [
          IconButton(
            tooltip: widget.animationsEnabled ? 'Disable Background Animation' : 'Enable Background Animation',
            icon: Icon(widget.animationsEnabled ? Icons.motion_photos_on : Icons.motion_photos_off),
            onPressed: widget.toggleAnimations,
          ),
          IconButton(
            icon: Icon(theme.brightness == Brightness.dark ? Icons.light_mode : Icons.dark_mode),
            onPressed: widget.toggleTheme,
          ),
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () => setState(() {
              _showProfilePane = !_showProfilePane;
              if (_showProfilePane) provider.selectGoal(null);
            }),
          ),
          IconButton(icon: const Icon(Icons.logout), onPressed: () => FirebaseAuth.instance.signOut()),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: const InputDecoration(labelText: 'Search Goals', prefixIcon: Icon(Icons.search), border: OutlineInputBorder()),
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: ColorFiltered(
                    colorFilter: ColorFilter.mode(theme.brightness == Brightness.dark ? Colors.black.withOpacity(0.7) : Colors.white.withOpacity(0.5), BlendMode.srcATop),
                    child: Image.asset('assets/apexsaver_bg.png', fit: BoxFit.cover),
                  ),
                ),
                if (widget.animationsEnabled)
                  const Positioned.fill(child: AnimatedBackgroundOverlay(opacity: 0.75)),
                LayoutBuilder(
                  builder: (context, constraints) {
                    bool useSplitScreen = constraints.maxWidth > 950 && (_showProfilePane || isViewingTabs);
                    return Row(
                      children: [
                        Expanded(
                          flex: useSplitScreen ? 3 : 5,
                          child: Stack(
                            children: [
                              GridView.builder(
                                padding: const EdgeInsets.all(24.0),
                                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 320, mainAxisExtent: 110, crossAxisSpacing: 16, mainAxisSpacing: 16),
                                itemCount: filteredGoals.length,
                                itemBuilder: (context, index) => MiniGoalCard(goal: filteredGoals[index], onTap: () {
                                  setState(() => _showProfilePane = false);
                                  provider.selectGoal(filteredGoals[index].id);
                                }),
                              ),
                              if (useSplitScreen && provider.activeGoal != null)
                                Positioned(
                                  left: 0,
                                  right: 0,
                                  bottom: 28,
                                  child: IgnorePointer(
                                    child: Center(
                                      child: GoalFillCircle(goal: provider.activeGoal!),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (useSplitScreen) ...[
                          VerticalDivider(width: 1, color: theme.colorScheme.outlineVariant),
                          Expanded(flex: _showProfilePane ? 5 : 7, child: _showProfilePane ? const ProfileInspector(isBottomSheet: false) : SplitDetailsInspector(goal: provider.activeGoal!)),
                        ]
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: (isViewingTabs || _showProfilePane) ? null : FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Create New Goal'),
        onPressed: () => showDialog(context: context, builder: (context) => const CreateGoalDialog()),
      ),
    );
  }
}

class GoalFillCircle extends StatelessWidget {
  final SavingsGoal goal;

  const GoalFillCircle({super.key, required this.goal});

  @override
  Widget build(BuildContext context) {
    final progress = goal.progress.clamp(0.0, 1.0);
    final percent = (progress * 100).round();

    return SizedBox(
      width: 360,
      height: 360,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size.square(360),
            painter: GoalFillCirclePainter(progress: progress),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$percent%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 46,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${goal.currency}${goal.currentSavings.toStringAsFixed(0)} saved',
                style: const TextStyle(
                  color: Colors.redAccent,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'of ${goal.currency}${goal.targetAmount.toStringAsFixed(0)}',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class GoalFillCirclePainter extends CustomPainter {
  final double progress;

  const GoalFillCirclePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = size.width * 0.02;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide - strokeWidth) / 2;
    final circlePath = Path()..addOval(Rect.fromCircle(center: center, radius: radius - strokeWidth));
    final fillHeight = (radius * 2 - strokeWidth) * progress;
    final fillRect = Rect.fromLTWH(
      center.dx - radius,
      center.dy + radius - fillHeight - strokeWidth / 2,
      radius * 2,
      fillHeight + strokeWidth,
    );

    canvas.save();
    canvas.clipPath(circlePath);
    canvas.drawCircle(center, radius, Paint()..color = Colors.black.withValues(alpha: 0.48));
    canvas.drawRect(fillRect, Paint()..color = Colors.red.withValues(alpha: 0.62));

    if (progress > 0) {
      canvas.drawLine(
        Offset(center.dx - radius * 0.68, fillRect.top),
        Offset(center.dx + radius * 0.68, fillRect.top),
        Paint()
          ..color = Colors.redAccent.withValues(alpha: 0.82)
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round,
      );
    }
    canvas.restore();

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..color = Colors.redAccent,
    );

    canvas.drawCircle(
      center,
      radius - strokeWidth * 0.7,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = Colors.white.withValues(alpha: 0.16),
    );
  }

  @override
  bool shouldRepaint(covariant GoalFillCirclePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

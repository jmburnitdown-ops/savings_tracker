import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'savings_provider.g.dart';

class UserProfile {
  final String username;
  final String? profileImageBase64;
  final String? firstName;
  final String? middleName;
  final String? lastName;
  final DateTime? birthday;

  UserProfile({
    required this.username,
    this.profileImageBase64,
    this.firstName,
    this.middleName,
    this.lastName,
    this.birthday,
  });

  UserProfile copyWith({
    String? username,
    String? profileImageBase64,
    String? firstName,
    String? middleName,
    String? lastName,
    DateTime? birthday,
  }) {
    return UserProfile(
      username: username ?? this.username,
      profileImageBase64: profileImageBase64 ?? this.profileImageBase64,
      firstName: firstName ?? this.firstName,
      middleName: middleName ?? this.middleName,
      lastName: lastName ?? this.lastName,
      birthday: birthday ?? this.birthday,
    );
  }
}

@HiveType(typeId: 0)
class LedgerTransaction extends HiveObject {
  @HiveField(0) final String type;
  @HiveField(1) final double amount;
  @HiveField(2) final DateTime timestamp;
  LedgerTransaction({required this.type, required this.amount, required this.timestamp});
}

@HiveType(typeId: 1)
class SavingsGoal extends HiveObject {
  @HiveField(0) final String id;
  @HiveField(1) final String name;
  @HiveField(2) final double targetAmount;
  @HiveField(3) final double currentSavings;
  @HiveField(4) final String currency;
  @HiveField(5) final DateTime? targetDate;
  @HiveField(6) final String? imageBase64;
  @HiveField(7) final bool isArchived;
  @HiveField(8) final List<String> unlockedMilestonesTitles; 
  @HiveField(9) final List<LedgerTransaction> ledgerHistory;

  // COMPATIBILITY: Mapping for widgets that expect the old Map format
  List<Map<String, String>> get unlockedMilestones {
    return unlockedMilestonesTitles.map((t) => {'title': t, 'desc': 'Milestone achieved'}).toList();
  }

  SavingsGoal({
    required this.id, required this.name, required this.targetAmount,
    this.currentSavings = 0.0, this.currency = '₱', this.targetDate,
    this.imageBase64, this.isArchived = false,
    this.unlockedMilestonesTitles = const [],
    this.ledgerHistory = const [],
  });

  double get progress => (currentSavings / targetAmount).clamp(0.0, 1.0);

  String get dynamicPaceAdvice {
    if (progress >= 1.0) return "Goal reached! Archive it to your vault.";
    if (targetDate == null) return "No target deadline set.";
    final daysRemaining = targetDate!.difference(DateTime.now()).inDays;
    return daysRemaining <= 0 ? "Timeline passed." : "Keep steady to secure your target.";
  }

  SavingsGoal copyWith({
    String? name, double? targetAmount, double? currentSavings,
    DateTime? targetDate, bool? isArchived, List<String>? unlockedMilestonesTitles,
    List<LedgerTransaction>? ledgerHistory,
  }) {
    return SavingsGoal(
      id: id, name: name ?? this.name, targetAmount: targetAmount ?? this.targetAmount,
      currentSavings: currentSavings ?? this.currentSavings, currency: currency,
      targetDate: targetDate ?? this.targetDate, imageBase64: imageBase64,
      isArchived: isArchived ?? this.isArchived,
      unlockedMilestonesTitles: unlockedMilestonesTitles ?? this.unlockedMilestonesTitles,
      ledgerHistory: ledgerHistory ?? this.ledgerHistory,
    );
  }
}

class SavingsProvider extends ChangeNotifier {
  late Box<SavingsGoal> _goalBox;
  String? _selectedGoalId;
  UserProfile _userProfile = UserProfile(username: "Apex User");

  UserProfile get userProfile => _userProfile;
  String? get selectedGoalId => _selectedGoalId;

  Future<void> init() async {
    _goalBox = await Hive.openBox<SavingsGoal>('savings_goals');
    notifyListeners();
  }

  // Load user profile from Firebase
  Future<void> loadUserProfileFromFirebase(String userId) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      if (doc.exists) {
        final data = doc.data() ?? {};
        _userProfile = UserProfile(
          username: _userProfile.username,
          profileImageBase64: _userProfile.profileImageBase64,
          firstName: data['firstName'] as String?,
          middleName: data['middleName'] as String?,
          lastName: data['lastName'] as String?,
          birthday: (data['birthday'] as Timestamp?)?.toDate(),
        );
        notifyListeners();
      }
    } catch (e) {
      // Error loading profile, continue with default
    }
  }

  // FIXED: Changed from Future to void to resolve "type void" error
  void updateProfile(UserProfile updatedProfile) {
    _userProfile = updatedProfile;
    notifyListeners();
  }

  List<SavingsGoal> get goals => _goalBox.values.where((g) => !g.isArchived).toList();

  SavingsGoal? get activeGoal => _selectedGoalId != null ? _goalBox.get(_selectedGoalId) : null;

  void selectGoal(String? id) { _selectedGoalId = id; notifyListeners(); }
  void clearSelection() { _selectedGoalId = null; notifyListeners(); }

  Future<void> addGoal(String name, double target, String currency, String? imageBase64, {DateTime? targetDate}) async {
    final newGoal = SavingsGoal(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name, targetAmount: target, currency: currency,
      imageBase64: imageBase64, targetDate: targetDate,
    );
    await _goalBox.put(newGoal.id, newGoal);
    notifyListeners();
  }

  Future<void> updateGoalDetails(String id, String name, double target, {DateTime? newTargetDate}) async {
    final goal = _goalBox.get(id);
    if (goal != null) {
      await _goalBox.put(id, goal.copyWith(name: name, targetAmount: target, targetDate: newTargetDate));
      notifyListeners();
    }
  }

  Future<void> addSavingsToGoal(String id, double amount) async {
    final goal = _goalBox.get(id);
    if (goal != null) {
      final history = List<LedgerTransaction>.from(goal.ledgerHistory)
        ..insert(0, LedgerTransaction(type: 'Deposit', amount: amount, timestamp: DateTime.now()));
      await _goalBox.put(id, goal.copyWith(currentSavings: goal.currentSavings + amount, ledgerHistory: history));
      notifyListeners();
    }
  }

  Future<void> withdrawFromGoal(String id, double amount) async {
    final goal = _goalBox.get(id);
    if (goal != null) {
      final history = List<LedgerTransaction>.from(goal.ledgerHistory)
        ..insert(0, LedgerTransaction(type: 'Withdrawal', amount: amount, timestamp: DateTime.now()));
      await _goalBox.put(id, goal.copyWith(currentSavings: (goal.currentSavings - amount).clamp(0.0, double.infinity), ledgerHistory: history));
      notifyListeners();
    }
  }

  Future<void> toggleArchiveGoal(String id) async {
    final goal = _goalBox.get(id);
    if (goal != null) {
      await _goalBox.put(id, goal.copyWith(isArchived: !goal.isArchived));
      if (_selectedGoalId == id) _selectedGoalId = null;
      notifyListeners();
    }
  }

  Future<void> deleteGoal(String id) async {
    await _goalBox.delete(id);
    if (_selectedGoalId == id) _selectedGoalId = null;
    notifyListeners();
  }
}
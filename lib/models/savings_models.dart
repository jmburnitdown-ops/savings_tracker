import 'package:cloud_firestore/cloud_firestore.dart';

class LedgerEntry {
  final String type; // 'Deposit' or 'Withdrawal'
  final double amount;
  final DateTime timestamp;

  LedgerEntry({required this.type, required this.amount, required this.timestamp});

  factory LedgerEntry.fromMap(Map<String, dynamic> map) {
    return LedgerEntry(
      type: map['type'] ?? 'Deposit',
      amount: (map['amount'] as num).toDouble(),
      timestamp: (map['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'amount': amount,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}

class SavingsGoal {
  final String id;
  final String name;
  final double targetAmount;
  double currentSavings;
  final String currency; 
  final String? imageBase64; 
  final List<LedgerEntry> ledgerHistory;
  final DateTime? targetDate; // NEW FEATURE: Target Deadline Date

  SavingsGoal({
    required this.id,
    required this.name,
    required this.targetAmount,
    this.currentSavings = 0.0,
    required this.currency,
    this.imageBase64,
    required this.ledgerHistory,
    this.targetDate,
  });

  double get progress => (targetAmount > 0) ? (currentSavings / targetAmount).clamp(0.0, 1.0) : 0.0;

  // NEW FEATURE: Reminders calculation engine
  String get dynamicPaceAdvice {
    if (targetDate == null) return "No deadline set for this asset goal.";
    final remainingDays = targetDate!.difference(DateTime.now()).inDays;
    final remainingAmount = targetAmount - currentSavings;

    if (remainingAmount <= 0) return "Goal achieved! Excellent job! 🎉";
    if (remainingDays <= 0) return "Deadline reached! Target short by $currency${remainingAmount.toStringAsFixed(0)}";

    final weeks = (remainingDays / 7).clamp(1, double.infinity);
    final weeklyPace = remainingAmount / weeks;
    return "To hit your target, save roughly $currency${weeklyPace.toStringAsFixed(0)} / week for the next $remainingDays days.";
  }

  // NEW FEATURE: Gamification milestone calculations
  List<Map<String, dynamic>> get unlockedMilestones {
    List<Map<String, dynamic>> badges = [];
    if (ledgerHistory.any((entry) => entry.type == 'Deposit')) {
      badges.add({'title': 'First Step 🚀', 'desc': 'Deposited into your savings!'});
    }
    if (progress >= 0.50) {
      badges.add({'title': 'Halfway Hero 🛡️', 'desc': '50% of target limit reached!'});
    }
    if (progress >= 1.0) {
      badges.add({'title': 'Apex Achiever 👑', 'desc': '100% Fully Funded!'});
    }
    return badges;
  }

  factory SavingsGoal.fromMap(String id, Map<String, dynamic> map) {
    var list = map['ledgerHistory'] as List?;
    List<LedgerEntry> history = list != null 
        ? list.map((item) => LedgerEntry.fromMap(Map<String, dynamic>.from(item))).toList()
        : [];
        
    return SavingsGoal(
      id: id,
      name: map['name'] ?? '',
      targetAmount: (map['targetAmount'] as num).toDouble(),
      currentSavings: (map['currentSavings'] as num).toDouble(),
      currency: map['currency'] ?? '\$',
      imageBase64: map['imageBase64'],
      ledgerHistory: history..sort((a, b) => b.timestamp.compareTo(a.timestamp)),
      targetDate: map['targetDate'] != null ? (map['targetDate'] as Timestamp).toDate() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'targetAmount': targetAmount,
      'currentSavings': currentSavings,
      'currency': currency,
      'imageBase64': imageBase64,
      'ledgerHistory': ledgerHistory.map((e) => e.toMap()).toList(),
      'targetDate': targetDate != null ? Timestamp.fromDate(targetDate!) : null,
    };
  }
}
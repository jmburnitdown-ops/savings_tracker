// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'savings_provider.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LedgerTransactionAdapter extends TypeAdapter<LedgerTransaction> {
  @override
  final int typeId = 0;

  @override
  LedgerTransaction read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LedgerTransaction(
      type: fields[0] as String,
      amount: fields[1] as double,
      timestamp: fields[2] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, LedgerTransaction obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.type)
      ..writeByte(1)
      ..write(obj.amount)
      ..writeByte(2)
      ..write(obj.timestamp);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LedgerTransactionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SavingsGoalAdapter extends TypeAdapter<SavingsGoal> {
  @override
  final int typeId = 1;

  @override
  SavingsGoal read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SavingsGoal(
      id: fields[0] as String,
      name: fields[1] as String,
      targetAmount: fields[2] as double,
      currentSavings: fields[3] as double,
      currency: fields[4] as String,
      targetDate: fields[5] as DateTime?,
      imageBase64: fields[6] as String?,
      isArchived: fields[7] as bool,
      unlockedMilestonesTitles: (fields[8] as List).cast<String>(),
      ledgerHistory: (fields[9] as List).cast<LedgerTransaction>(),
    );
  }

  @override
  void write(BinaryWriter writer, SavingsGoal obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.targetAmount)
      ..writeByte(3)
      ..write(obj.currentSavings)
      ..writeByte(4)
      ..write(obj.currency)
      ..writeByte(5)
      ..write(obj.targetDate)
      ..writeByte(6)
      ..write(obj.imageBase64)
      ..writeByte(7)
      ..write(obj.isArchived)
      ..writeByte(8)
      ..write(obj.unlockedMilestonesTitles)
      ..writeByte(9)
      ..write(obj.ledgerHistory);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SavingsGoalAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

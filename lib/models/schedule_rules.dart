import 'enums.dart';

class ScheduleRules {
  const ScheduleRules({
    required this.minDinlenmeSaat,
    required this.haftalikMaxNobet,
    required this.esitlikYontemi,
  });

  final int minDinlenmeSaat;
  final int haftalikMaxNobet;
  final FairnessMethod esitlikYontemi;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'minDinlenmeSaat': minDinlenmeSaat,
      'haftalikMaxNobet': haftalikMaxNobet,
      'esitlikYontemi': esitlikYontemi.name,
    };
  }

  factory ScheduleRules.fromMap(Map<String, dynamic> map) {
    return ScheduleRules(
      minDinlenmeSaat: map['minDinlenmeSaat'] as int,
      haftalikMaxNobet: map['haftalikMaxNobet'] as int,
      esitlikYontemi: FairnessMethod.totalHours,
    );
  }
}

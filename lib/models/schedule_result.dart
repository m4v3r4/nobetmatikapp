import 'assignment.dart';
import 'schedule_request.dart';
import 'unfilled_slot.dart';

class ScheduleResult {
  const ScheduleResult({
    required this.request,
    required this.assignments,
    required this.unfilledSlots,
    required this.targetHours,
  });

  final ScheduleRequest request;
  final List<Assignment> assignments;
  final List<UnfilledSlot> unfilledSlots;
  final double targetHours;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'request': request.toMap(),
      'assignments': assignments.map((e) => e.toMap()).toList(),
      'unfilledSlots': unfilledSlots.map((e) => e.toMap()).toList(),
      'targetHours': targetHours,
    };
  }

  factory ScheduleResult.fromMap(Map<String, dynamic> map) {
    return ScheduleResult(
      request: ScheduleRequest.fromMap(map['request'] as Map<String, dynamic>),
      assignments: (map['assignments'] as List<dynamic>)
          .map((e) => Assignment.fromMap(e as Map<String, dynamic>))
          .toList(),
      unfilledSlots: (map['unfilledSlots'] as List<dynamic>)
          .map((e) => UnfilledSlot.fromMap(e as Map<String, dynamic>))
          .toList(),
      targetHours: (map['targetHours'] as num).toDouble(),
    );
  }
}

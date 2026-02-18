class DutyLocation {
  const DutyLocation({
    required this.id,
    required this.ad,
    required this.kapasite,
  });

  final int id;
  final String ad;
  final int kapasite;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'ad': ad,
      'kapasite': kapasite,
    };
  }

  factory DutyLocation.fromMap(Map<String, dynamic> map) {
    return DutyLocation(
      id: map['id'] as int,
      ad: map['ad'] as String,
      kapasite: map['kapasite'] as int,
    );
  }
}

class Person {
  const Person({
    required this.id,
    required this.adSoyad,
    required this.aktifMi,
  });

  final int id;
  final String adSoyad;
  final bool aktifMi;

  Person copyWith({String? adSoyad, bool? aktifMi}) {
    return Person(
      id: id,
      adSoyad: adSoyad ?? this.adSoyad,
      aktifMi: aktifMi ?? this.aktifMi,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'adSoyad': adSoyad,
      'aktifMi': aktifMi,
    };
  }

  factory Person.fromMap(Map<String, dynamic> map) {
    return Person(
      id: map['id'] as int,
      adSoyad: map['adSoyad'] as String,
      aktifMi: map['aktifMi'] as bool,
    );
  }
}

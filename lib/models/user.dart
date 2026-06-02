enum Gender { husband, wife }

class AppUser {
  final String id;
  final String name;
  final String? avatarUrl;
  final Gender gender;
  final String? familyId;
  final DateTime createdAt;

  AppUser({
    required this.id,
    required this.name,
    this.avatarUrl,
    required this.gender,
    this.familyId,
    required this.createdAt,
  });

  factory AppUser.fromMap(Map<String, dynamic> data, String id) {
    String? _str(Map d, String key) => d[key]?.toString();
    int _int(dynamic v) => v is int ? v : int.tryParse(v?.toString() ?? '0') ?? 0;

    final genderStr = _str(data, 'gender') ?? _str(data, 'gender');
    final familyIdVal = data['familyId'] ?? data['family_id'];

    return AppUser(
      id: id,
      name: _str(data, 'name') ?? '',
      avatarUrl: data['avatarUrl']?.toString() ?? data['avatar_url']?.toString(),
      gender: genderStr == 'wife' ? Gender.wife : Gender.husband,
      familyId: familyIdVal?.toString(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(_int(data['createdAt'] ?? data['created_at'])),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'avatarUrl': avatarUrl,
      'gender': gender == Gender.husband ? 'husband' : 'wife',
      'familyId': familyId,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  AppUser copyWith({
    String? name,
    String? avatarUrl,
    Gender? gender,
    String? familyId,
  }) {
    return AppUser(
      id: id,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      gender: gender ?? this.gender,
      familyId: familyId ?? this.familyId,
      createdAt: createdAt,
    );
  }
}
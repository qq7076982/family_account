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
    return AppUser(
      id: id,
      name: data['name'] ?? '',
      avatarUrl: data['avatarUrl'],
      gender: data['gender'] == 'husband' ? Gender.husband : Gender.wife,
      familyId: data['familyId'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(data['createdAt'] ?? 0),
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
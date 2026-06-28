class UserProfile {
  String name;
  String email;
  String studyLevel;
  int age;
  String? photoUrl;

  UserProfile({
    required this.name,
    required this.email,
    this.studyLevel = 'Undergraduate',
    this.age = 20,
    this.photoUrl,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'email': email,
    'studyLevel': studyLevel,
    'age': age,
    'photoUrl': photoUrl,
  };
}
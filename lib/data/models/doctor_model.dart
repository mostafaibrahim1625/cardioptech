class DoctorModel {
  final String firstName;
  final String lastName;
  final String fullName;
  final String email;
  final String? password;
  final String? specialization;
  final String? description;
  final String? imageUrl;

  DoctorModel({
    required this.firstName,
    required this.lastName,
    required this.fullName,
    required this.email,
    this.password,
    this.specialization,
    this.description,
    this.imageUrl,
  });

  factory DoctorModel.fromJson(Map<String, dynamic> json) {
    return DoctorModel(
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      fullName: json['full_name'] ?? '',
      email: json['email'] ?? '',
      password: json['password'],
      specialization: json['specialization'],
      description: json['description'],
      imageUrl: json['image_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'first_name': firstName,
      'last_name': lastName,
      'full_name': fullName,
      'email': email,
      'password': password,
      'specialization': specialization,
      'description': description,
      'image': imageUrl,
    };
  }

  DoctorModel copyWith({
    String? firstName,
    String? lastName,
    String? fullName,
    String? email,
    String? password,
    String? specialization,
    String? description,
    String? imageUrl,
  }) {
    return DoctorModel(
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      password: password ?? this.password,
      specialization: specialization ?? this.specialization,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  @override
  String toString() {
    return 'DoctorModel(firstName: $firstName, lastName: $lastName, fullName: $fullName, email: $email, password: $password, specialization: $specialization, description: $description, imageUrl: $imageUrl)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DoctorModel &&
        other.firstName == firstName &&
        other.lastName == lastName &&
        other.fullName == fullName &&
        other.email == email &&
        other.password == password &&
        other.specialization == specialization &&
        other.description == description &&
        other.imageUrl == imageUrl;
  }

  @override
  int get hashCode {
    return firstName.hashCode ^
        lastName.hashCode ^
        fullName.hashCode ^
        email.hashCode ^
        password.hashCode ^
        specialization.hashCode ^
        description.hashCode ^
        imageUrl.hashCode;
  }

  // Utility method to capitalize first letter of each word
  String get capitalizedFullName {
    if (fullName.isEmpty) return fullName;
    return fullName.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }
}

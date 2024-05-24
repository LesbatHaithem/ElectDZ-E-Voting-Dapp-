class User {
  String firstName;
  String lastName;
  String image;

  User({required this.firstName, required this.lastName, required this.image});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      firstName: json['firstName'] ?? '', // Default to empty string if null
      lastName: json['lastName'] ?? '', // Default to empty string if null
      image: json['image'] ?? '', // Default to empty string if null
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'image': image,
    };
  }
}

class UserModel {
  final String id;
  final String fullName;
  final String email;
  final String phone;
  final String persona; // 'customer', 'salon_owner', 'stylist'
  final String? profileImage;

  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.persona,
    this.profileImage,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'persona': persona,
      'profileImage': profileImage,
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      fullName: json['fullName'],
      email: json['email'],
      phone: json['phone'],
      persona: json['persona'],
      profileImage: json['profileImage'],
    );
  }

 
}

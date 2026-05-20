class ReviewModel {
  final String id;
  final String salonId;
  final String serviceId;
  final String userId;
  final String userName;
  final String? userAvatar;
  final double rating;
  final String comment;
  final List<String> tags;
  final DateTime date;
  final int helpful;

  ReviewModel({
    required this.id,
    required this.salonId,
    required this.serviceId,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.rating,
    required this.comment,
    required this.tags,
    required this.date,
    required this.helpful,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'salonId': salonId,
      'serviceId': serviceId,
      'userId': userId,
      'userName': userName,
      'userAvatar': userAvatar,
      'rating': rating,
      'comment': comment,
      'tags': tags,
      'date': date.toIso8601String(),
      'helpful': helpful,
    };
  }

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: json['id'],
      salonId: json['salonId'],
      serviceId: json['serviceId'],
      userId: json['userId'],
      userName: json['userName'],
      userAvatar: json['userAvatar'],
      rating: json['rating'],
      comment: json['comment'],
      tags: List<String>.from(json['tags']),
      date: DateTime.parse(json['date']),
      helpful: json['helpful'],
    );
  }
}

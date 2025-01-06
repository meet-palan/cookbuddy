class CommentRatingModel {
  int? id;
  int recipeId;
  int userId;
  String comment;
  double rating;

  CommentRatingModel({
    this.id,
    required this.recipeId,
    required this.userId,
    required this.comment,
    required this.rating,
  });

  // Convert a CommentRating object to a Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'recipeId': recipeId,
      'userId': userId,
      'comment': comment,
      'rating': rating,
    };
  }

  // Convert a Map to a CommentRating object
  factory CommentRatingModel.fromMap(Map<String, dynamic> map) {
    return CommentRatingModel(
      id: map['id'],
      recipeId: map['recipeId'],
      userId: map['userId'],
      comment: map['comment'],
      rating: map['rating'],
    );
  }
}

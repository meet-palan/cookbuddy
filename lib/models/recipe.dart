class RecipeModel {
  int? id;
  String name;
  String ingredients;
  String instructions;
  String category;
  String imageUrl;
  int uploaderId;

  RecipeModel({
    this.id,
    required this.name,
    required this.ingredients,
    required this.instructions,
    required this.category,
    required this.imageUrl,
    required this.uploaderId,
  });

  // Convert a Recipe object to a Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'ingredients': ingredients,
      'instructions': instructions,
      'category': category,
      'imageUrl': imageUrl,
      'uploaderId': uploaderId,
    };
  }

  // Convert a Map to a Recipe object
  factory RecipeModel.fromMap(Map<String, dynamic> map) {
    return RecipeModel(
      id: map['id'],
      name: map['name'],
      ingredients: map['ingredients'],
      instructions: map['instructions'],
      category: map['category'],
      imageUrl: map['imageUrl'],
      uploaderId: map['uploaderId'],
    );
  }
}

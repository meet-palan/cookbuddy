class CategoryModel {
  int? id;
  String name;

  CategoryModel({this.id, required this.name});

  // Convert a Category object to a Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
    };
  }

  // Convert a Map to a Category object
  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'],
      name: map['name'],
    );
  }
}

class Model {
  final int id;
  final String name;

  Model({
    required this.id,
    required this.name,
  });

  factory Model.fromJson(Map<String, dynamic> json) {
    return Model(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}

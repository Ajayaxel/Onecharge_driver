class IssueCategory {
  final int id;
  final String name;

  IssueCategory({
    required this.id,
    required this.name,
  });

  factory IssueCategory.fromJson(Map<String, dynamic> json) {
    return IssueCategory(
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

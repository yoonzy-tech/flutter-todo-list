class TodoList {
  final int? id;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;

  TodoList({
    this.id,
    required this.name,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory TodoList.fromMap(Map<String, dynamic> map) {
    return TodoList(
      id: map['id'],
      name: map['name'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'TodoList(id: $id, name: "$name", createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}

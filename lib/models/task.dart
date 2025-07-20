class Task {
  final int? id;
  final int listId;
  final String title;
  final String? description;
  final bool isCompleted;
  final DateTime? dueDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  Task({
    this.id,
    required this.listId,
    required this.title,
    this.description,
    this.isCompleted = false,
    this.dueDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'],
      listId: map['list_id'],
      title: map['title'],
      description: map['description'],
      isCompleted: map['is_completed'] == 1,
      dueDate: map['due_date'] != null ? DateTime.tryParse(map['due_date']) : null,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'list_id': listId,
      'title': title,
      'description': description,
      'is_completed': isCompleted ? 1 : 0,
      'due_date': dueDate?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'Task(id: $id, listId: $listId, title: "$title", description: "${description ?? ''}", '
        'isCompleted: $isCompleted, dueDate: $dueDate, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}
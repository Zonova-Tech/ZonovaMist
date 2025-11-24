class Todo {
  final String id;
  final String title;
  final String description;
  final DateTime dueDate;
  final String priority; // "High", "Medium", "Low"
  final String assignedToId;
  final String? assignedToName;
  final String? assignedToEmail;
  final String createdById;
  final String? createdByName;
  final String? createdByEmail;
  final DateTime createdDate;
  final bool completed;
  final DateTime? completedAt;
  final bool deleted;

  Todo({
    required this.id,
    required this.title,
    required this.description,
    required this.dueDate,
    required this.priority,
    required this.assignedToId,
    this.assignedToName,
    this.assignedToEmail,
    required this.createdById,
    this.createdByName,
    this.createdByEmail,
    required this.createdDate,
    this.completed = false,
    this.completedAt,
    this.deleted = false,
  });

  factory Todo.fromJson(Map<String, dynamic> json) {
    return Todo(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      dueDate: DateTime.parse(json['dueDate']),
      priority: json['priority'] ?? 'Medium',
      assignedToId: json['assignedTo'] is Map
          ? json['assignedTo']['_id']
          : json['assignedTo'],
      assignedToName: json['assignedTo'] is Map
          ? json['assignedTo']['fullName']
          : null,
      assignedToEmail: json['assignedTo'] is Map
          ? json['assignedTo']['email']
          : null,
      createdById: json['createdBy'] is Map
          ? json['createdBy']['_id']
          : json['createdBy'],
      createdByName: json['createdBy'] is Map
          ? json['createdBy']['fullName']
          : null,
      createdByEmail: json['createdBy'] is Map
          ? json['createdBy']['email']
          : null,
      createdDate: DateTime.parse(json['createdDate'] ?? json['createdAt']),
      completed: json['completed'] ?? false,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
      deleted: json['deleted'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'dueDate': dueDate.toIso8601String(),
      'priority': priority,
      'assignedTo': assignedToId,
    };
  }

  Todo copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? dueDate,
    String? priority,
    String? assignedToId,
    String? assignedToName,
    String? assignedToEmail,
    String? createdById,
    String? createdByName,
    String? createdByEmail,
    DateTime? createdDate,
    bool? completed,
    DateTime? completedAt,
    bool? deleted,
  }) {
    return Todo(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      priority: priority ?? this.priority,
      assignedToId: assignedToId ?? this.assignedToId,
      assignedToName: assignedToName ?? this.assignedToName,
      assignedToEmail: assignedToEmail ?? this.assignedToEmail,
      createdById: createdById ?? this.createdById,
      createdByName: createdByName ?? this.createdByName,
      createdByEmail: createdByEmail ?? this.createdByEmail,
      createdDate: createdDate ?? this.createdDate,
      completed: completed ?? this.completed,
      completedAt: completedAt ?? this.completedAt,
      deleted: deleted ?? this.deleted,
    );
  }
}

class User {
  final String id;
  final String fullName;
  final String email;

  User({
    required this.id,
    required this.fullName,
    required this.email,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? json['id'] ?? '',
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
    );
  }
}
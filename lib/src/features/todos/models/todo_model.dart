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
  final String status; // "New", "Completed", "Approved"
  final List<TodoImage> images;
  final DateTime? completedAt;
  final DateTime? approvedAt;
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
    this.status = 'New',
    this.images = const [],
    this.completedAt,
    this.approvedAt,
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
      status: json['status'] ?? 'New',
      images: (json['images'] as List<dynamic>?)
          ?.map((img) => TodoImage.fromJson(img))
          .toList() ?? [],
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
      approvedAt: json['approvedAt'] != null
          ? DateTime.parse(json['approvedAt'])
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

  bool get isOverdue => dueDate.isBefore(DateTime.now()) && status == 'New';

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
    String? status,
    List<TodoImage>? images,
    DateTime? completedAt,
    DateTime? approvedAt,
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
      status: status ?? this.status,
      images: images ?? this.images,
      completedAt: completedAt ?? this.completedAt,
      approvedAt: approvedAt ?? this.approvedAt,
      deleted: deleted ?? this.deleted,
    );
  }
}

class TodoImage {
  final String url;
  final String publicId;

  TodoImage({
    required this.url,
    required this.publicId,
  });

  factory TodoImage.fromJson(Map<String, dynamic> json) {
    return TodoImage(
      url: json['url'] ?? '',
      publicId: json['public_id'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'public_id': publicId,
    };
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
class TaskModel {
  final String id;
  final String title;
  final String description;
  final String status;
  final String remarks;
  final DateTime updatedAt;
  final bool isSynced;

  TaskModel({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.remarks,
    required this.updatedAt,
    required this.isSynced,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      status: json['status'],
      remarks: json['remarks'],
      updatedAt: DateTime.parse(json['updatedAt']),
      isSynced: true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "id": id,
      "title": title,
      "description": description,
      "status": status,
      "remarks": remarks,
      "updatedAt": updatedAt.toIso8601String(),
      "isSynced": isSynced,
    };
  }

  factory TaskModel.fromMap(Map map) {
    return TaskModel(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      status: map['status'],
      remarks: map['remarks'],
      updatedAt: DateTime.parse(map['updatedAt']),
      isSynced: map['isSynced'],
    );
  }

  TaskModel copyWith({String? status, String? remarks, bool? isSynced}) {
    return TaskModel(
      id: id,
      title: title,
      description: description,
      status: status ?? this.status,
      remarks: remarks ?? this.remarks,
      updatedAt: DateTime.now(),
      isSynced: isSynced ?? this.isSynced,
    );
  }
}

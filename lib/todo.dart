class Todo {
  String? id;
  String? title;
  String? description;
  DateTime? startDateTime;
  DateTime? endDateTime;
  String? friendId;

  Todo({this.id, this.title, this.description, this.startDateTime, this.endDateTime, this.friendId});

  factory Todo.fromMap(Map<String, dynamic> map) {
    return Todo(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      startDateTime: map['startDateTime']?.toDate(),
      endDateTime: map['endDateTime']?.toDate(),
      friendId: map['friendId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'startDateTime': startDateTime,
      'endDateTime': endDateTime,
      'friendId': friendId,
    };
  }

  Todo copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? startDateTime,
    DateTime? endDateTime,
    String? friendId,
  }) {
    return Todo(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      startDateTime: startDateTime ?? this.startDateTime,
      endDateTime: endDateTime ?? this.endDateTime,
      friendId: friendId ?? this.friendId,
    );
  }
}
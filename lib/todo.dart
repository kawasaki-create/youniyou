class Todo {
  String? id;
  String? title;
  String? description;
  DateTime? date;
  String? friendId;

  Todo({this.id, this.title, this.description, this.date, this.friendId});

  factory Todo.fromMap(Map<String, dynamic> map) {
    return Todo(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      date: map['date']?.toDate(),
      friendId: map['friendId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'date': date,
      'friendId': friendId,
    };
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

class Todo {
  String? id;
  String? description;
  DateTime? startDateTime;
  DateTime? endDateTime;
  String? friendId;

  Todo({this.id, this.description, this.startDateTime, this.endDateTime, this.friendId});

  factory Todo.fromMap(Map<String, dynamic> map) {
    return Todo(
      id: map['id'],
      description: map['description'],
      startDateTime: map['startDateTime'] != null ? (map['startDateTime'] as Timestamp).toDate() : null,
      endDateTime: map['endDateTime'] != null ? (map['endDateTime'] as Timestamp).toDate() : null,
      friendId: map['friendId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'description': description,
      'startDateTime': startDateTime != null ? Timestamp.fromDate(startDateTime!) : null,
      'endDateTime': endDateTime != null ? Timestamp.fromDate(endDateTime!) : null,
      'friendId': friendId,
    };
  }

  Todo copyWith({
    String? id,
    String? description,
    DateTime? startDateTime,
    DateTime? endDateTime,
    String? friendId,
  }) {
    return Todo(
      id: id ?? this.id,
      description: description ?? this.description,
      startDateTime: startDateTime ?? this.startDateTime,
      endDateTime: endDateTime ?? this.endDateTime,
      friendId: friendId ?? this.friendId,
    );
  }
}

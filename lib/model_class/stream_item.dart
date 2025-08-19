import 'package:equatable/equatable.dart';

class StreamItem extends Equatable {
  final String id;
  final String classId;
  final String authorId;
  final String authorName;
  final String type;
  final String content; // For announcements or assignment descriptions
  final String? title; // For assignments
  final DateTime timestamp;
  final DateTime? dueDate; // For assignments
  final String? subjectName;
  final String? attachmentUrl;
  final String? attachmentFileName;
  final String? session; // For year-wise assignments

  const StreamItem({
    required this.id,
    required this.classId,
    required this.authorId,
    required this.authorName,
    required this.type,
    required this.content,
    this.title,
    required this.timestamp,
    this.dueDate,
    this.subjectName,
    this.attachmentUrl,
    this.attachmentFileName,
    this.session,
  });

  factory StreamItem.fromMap(Map<String, dynamic> map, String id) {
    return StreamItem(
      id: id,
      classId: map['classId'] as String,
      authorId: map['authorId'] as String,
      authorName: map['authorName'] as String,
      type: map['type'] as String,
      content: map['content'] as String,
      title: map['title'] as String?,
      timestamp: DateTime.parse(map['timestamp'] as String),
      dueDate: map['dueDate'] != null
          ? DateTime.parse(map['dueDate'] as String)
          : null,
      subjectName: map['subjectName'] as String?,
      attachmentUrl: map['attachmentUrl'] as String?,
      attachmentFileName: map['attachmentFileName'] as String?,
      session: map['session'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'classId': classId,
      'authorId': authorId,
      'authorName': authorName,
      'type': type,
      'content': content,
      'title': title,
      'timestamp': timestamp.toIso8601String(),
      'dueDate': dueDate?.toIso8601String(),
      'subjectName': subjectName,
      'attachmentUrl': attachmentUrl,
      'attachmentFileName': attachmentFileName,
      'session': session,
    };
  }

  @override
  List<Object?> get props => [
        id,
        classId,
        authorId,
        type,
        content,
        timestamp,
        subjectName,
        attachmentUrl,
        attachmentFileName,
        session,
      ];
}
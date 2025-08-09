class Classroom {
  final String id;
  final String name;
  final String subject;
  final String status; // e.g., 'active', 'archived'
  final DateTime creationDate;

  Classroom({
    required this.id,
    required this.name,
    required this.subject,
    required this.status,
    required this.creationDate,
  });

  factory Classroom.fromMap(Map<String, dynamic> map, String id) {
    return Classroom(
      id: id,
      // Assumes 'className' from Firebase maps to 'name' in the model.
      name: map['className'] ?? 'Unnamed Class',
      subject: map['subject'] ?? 'No Subject',
      // Defaults to 'active' if status is not specified in Firebase.
      status: map['status'] ?? 'active',
      // Assumes 'createdAt' is a Unix timestamp (milliseconds since epoch).
      creationDate: map['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'])
          : DateTime.now(),
    );
  }
}

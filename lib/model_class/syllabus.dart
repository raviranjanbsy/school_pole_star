class Syllabus {
  final String id;
  final String className;
  final String subject;
  final String title;
  final String description;
  final String? fileUrl;
  final int createdAt; // Using int for timestamp

  Syllabus({
    required this.id,
    required this.className,
    required this.subject,
    required this.title,
    required this.description,
    this.fileUrl,
    required this.createdAt,
  });

  // Factory to create a Syllabus from a map
  factory Syllabus.fromMap(String id, Map<dynamic, dynamic> value) {
    return Syllabus(
      id: id,
      className: value['className'] ?? '',
      subject: value['subject'] ?? '',
      title: value['title'] ?? '',
      description: value['description'] ?? '',
      fileUrl: value['fileUrl'],
      createdAt: value['createdAt'] ?? 0,
    );
  }

  // Method to convert a Syllabus object to a map for Firebase
  Map<String, dynamic> toMap() {
    return {
      'className': className,
      'subject': subject,
      'title': title,
      'description': description,
      'fileUrl': fileUrl,
      // createdAt will be set by the server for consistency
    };
  }
}

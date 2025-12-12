class Attachment {
  final int id;
  final String fileName;
  final String fileType;
  final int fileSize;
  final String fileUrl;

  Attachment({
    required this.id,
    required this.fileName,
    required this.fileType,
    required this.fileSize,
    required this.fileUrl,
  });

  factory Attachment.fromJson(Map<String, dynamic> json) {
    return Attachment(
      id: json['id'] ?? 0,
      fileName: json['file_name'] ?? '',
      fileType: json['file_type'] ?? '',
      fileSize: json['file_size'] ?? 0,
      fileUrl: json['file_url'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'file_name': fileName,
      'file_type': fileType,
      'file_size': fileSize,
      'file_url': fileUrl,
    };
  }
}

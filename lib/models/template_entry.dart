class TemplateEntry {
  final String name;
  final String filename;
  final String iconCode;
  final List<String> categories;

  TemplateEntry({
    required this.name,
    required this.filename,
    required this.iconCode,
    required this.categories,
  });

  factory TemplateEntry.fromJson(Map<String, dynamic> json) {
    return TemplateEntry(
      name: json['name'] as String,
      filename: json['filename'] as String,
      iconCode: json['iconCode'] as String,
      categories: List<String>.from(json['categories'] as List),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'filename': filename,
      'iconCode': iconCode,
      'categories': categories,
    };
  }
}

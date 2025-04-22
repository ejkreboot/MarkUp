import 'dart:convert';
import 'template_entry.dart';

class TemplatesList {
  final List<TemplateEntry> templates;

  TemplatesList({required this.templates});

  Map<String, dynamic> toJson() {
    return {
      'templates': templates.map((entry) => entry.toJson()).toList(),
    };
  }

  factory TemplatesList.fromJson(String jsonString) {
    final data = json.decode(jsonString) as Map<String, dynamic>;
    final templatesData = data['templates'] as List;
    final templatesList = templatesData.map((entry) => TemplateEntry.fromJson(entry)).toList();
    return TemplatesList(templates: templatesList);
  }

  String toJsonString() {
    final data = {
      'templates': templates.map((e) => e.toJson()).toList(),
    };
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(data);
  }

  void addTemplate({required String name, required String filename}) {
    final newEntry = TemplateEntry(
      name: name,
      filename: filename,
      iconCode: '\ue9a9', // Default for now
      categories: ['User'], // Default for now
    );
    templates.add(newEntry);
  }
}

import 'id_parse.dart';

class ImageModel {
  final int id;
  final String title;
  final String url;

  ImageModel({required this.id, required this.title, required this.url});

  factory ImageModel.fromJson(Map<String, dynamic> json) {
    return ImageModel(
      id: json['@id'] != null
          ? IdParser.fromIri(json['@id'] as String)
          : (json['id'] as int? ?? 0),
      title: json['title'] ?? '',
      url: json['url'] ?? '',
    );
  }
}

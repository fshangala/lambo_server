class SiteModel {
  String name;
  String url;

  SiteModel({required this.name, required this.url});

  factory SiteModel.fromJson(Map<String, dynamic> json) {
    return SiteModel(
      name: json['name'],
      url: json['url'],
    );
  }

  Map<String, String> toMap() {
    return {
      'name': name,
      'url': url,
    };
  }

  @override
  String toString() {
    return toMap().toString();
  }
}

class SiteModel {
  String name;
  String url;
  String openBetScript;
  String placeBetScript;
  String confirmBetScript;

  SiteModel({required this.name, required this.url, required this.openBetScript, required this.placeBetScript, required this.confirmBetScript});

  factory SiteModel.fromJson(Map<String, dynamic> json) {
    return SiteModel(
      name: json['name'],
      url: json['url'],
      openBetScript: json['openBetScript'],
      placeBetScript: json['placeBetScript'],
      confirmBetScript: json['confirmBetScript'],
    );
  }

  Map<String, String> toMap() {
    return {
      'name': name,
      'url': url,
      'openBetScript': openBetScript,
      'placeBetScript': placeBetScript,
      'confirmBetScript': confirmBetScript,
    };
  }

  @override
  String toString() {
    return toMap().toString();
  }
}
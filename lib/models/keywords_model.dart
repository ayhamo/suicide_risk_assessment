class Keywords {
  final Map<String, double> keywords;

  Keywords({required this.keywords});

  Keywords.fromJson(Map<String, dynamic> json)
      : this(keywords: Map<String, double>.from(json));
}

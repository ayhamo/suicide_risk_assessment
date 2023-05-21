class Predictions {
  final Map<String, double> emotions;
  final Map<String, double> sentiment;
  final String suicideRisk;

  Predictions({
    required this.emotions,
    required this.sentiment,
    required this.suicideRisk,
  });

  Predictions.fromJson(Map<String, dynamic> json)
      : this(
    emotions: Map<String, double>.from(json['Emotions']),
    sentiment: Map<String, double>.from(json['Sentiment']),
    suicideRisk: json['Suicide_Risk'],
  );
}

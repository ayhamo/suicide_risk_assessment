import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:suicide_risk_assessment/models/prediction_model.dart';

import 'Models/keywords_model.dart';

const baseUrl = 'http://127.0.0.1:5000/';
late String endPoint;

Future<String> loadModels() async {
  endPoint = 'load_models';
  final url = '$baseUrl$endPoint';

  final response = await http.get(Uri.parse(url));
  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    if (data['message'].toString().contains("Server error occurred") ||
        data['message'] == "Models already loaded" ||
        data['message'] == "Models loaded successfully") {
      return data['message'];
    } else {
      return data;
    }
  } else {
    return 'failed to reach server';
  }
}

Future<Predictions> getPrediction(String value) async {
  endPoint = '/predict';
  final url = '$baseUrl$endPoint';

  final response = await http.post(
    Uri.parse(url),
    body: jsonEncode({"text": value}),
    headers: {"Content-Type": "application/json"},
  );
  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    if (data['message'].toString().contains("Server error occurred") ||
        data['message'] == "Models already loaded" ||
        data['message'] == "Models loaded successfully") {
      return data['message'];
    } else {
      return Predictions.fromJson(data);
    }
  } else {
    throw Exception('failed to reach server');
  }
}

Future<Keywords> getKeywordExtraction() async {
  endPoint = 'keywords_graph';
  final url = '$baseUrl$endPoint';

  final response = await http.get(Uri.parse(url));
  final data = jsonDecode(response.body);
  if (response.statusCode == 200) {
    if (data['message'].toString().contains("Server error occurred")) {
      return data['message'];
    } else {
      return Keywords.fromJson(data);
    }
  } else {
    throw Exception('failed to reach server');
  }
}


//TODO Fix the loadingBuilder
Image getKeywordsWordcloud() {
  endPoint = 'keywords_wordcloud';
  final url = '$baseUrl$endPoint';
  return Image.network(url, errorBuilder: (context, error, stackTrace) {
    return Text('Failed to load image: $error');
  }, loadingBuilder:
      (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
    if (loadingProgress == null) return child;
    return Center(
      child: CircularProgressIndicator(
        value: loadingProgress.expectedTotalBytes != null
            ? loadingProgress.cumulativeBytesLoaded /
                loadingProgress.expectedTotalBytes!
            : 0,
      ),
    );
  });
}

//TODO Fix the loadingBuilder
Image getOccurrences() {
  endPoint = 'occurrence_matrix';
  final url = '$baseUrl$endPoint';
  return Image.network(url, errorBuilder: (context, error, stackTrace) {
    return Text('Failed to load occurrence matrix: $error');
  }, loadingBuilder:
      (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
    if (loadingProgress == null) return child;
    return Center(
      child: CircularProgressIndicator(
        value: loadingProgress.expectedTotalBytes != null
            ? loadingProgress.cumulativeBytesLoaded /
                loadingProgress.expectedTotalBytes!
            : null,
      ),
    );
  });
}

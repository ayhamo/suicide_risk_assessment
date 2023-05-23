import 'dart:convert';

import 'package:flutter/cupertino.dart';
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
    if (data['message'] == "Critical Server problem occurred" ||
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
    if (data['message'] == "Critical Server problem occurred" ||
        data['message'] == "Models already loaded") {
      throw Exception(data['message']);
    } else {
      return Predictions.fromJson(data);
    }
  } else {
    throw Exception('failed to reach server');
  }
}

Future<Keywords> getKeywordExtraction() async {
  endPoint = 'keyword_extraction';
  final url = '$baseUrl$endPoint';

  final response = await http.get(Uri.parse(url));
  if (response.statusCode == 200) {
    return Keywords.fromJson(jsonDecode(response.body));
  } else {
    throw Exception('failed to reach server');
  }
}

Image getOccurrences() {
  endPoint = 'occurrence_matrix';
  final url = '$baseUrl$endPoint';
  return Image.network(url, errorBuilder: (context, error, stackTrace) {
    return Text('Failed to load image: $error');
  });
}

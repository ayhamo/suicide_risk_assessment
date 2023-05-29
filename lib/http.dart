import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/rendering.dart';
import 'package:http/http.dart' as http;
import 'package:suicide_risk_assessment/models/prediction_model.dart';

import 'export_manager.dart';
import 'Models/keywords_model.dart';

const baseUrl = 'http://127.0.0.1:5000/';
late String endPoint;

Future<String> loadModels() async {
  endPoint = 'load_models';
  final url = '$baseUrl$endPoint';
  final http.Response response;
  try {
    response = await http.get(Uri.parse(url));
  } catch (e) {
    return "Failed to reach server";
  }
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
    // This check for status code other than 200, not needed but can keep, has to be handled here
    return 'Server did not return OK code';
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
    // This check for status code other than 200, not needed but can keep, handled in the future builder
    throw Exception('Server did not return OK code');
  }
}

Future<Keywords> getKeywordGraph() async {
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
    // This check for status code other than 200, not needed but can keep, handled in the future builder
    throw Exception('Server did not return OK code');
  }
}

final GlobalKey _wordCloudImageKey = GlobalKey();

Widget getKeywordsWordcloud() {
  endPoint = 'keywords_wordcloud';
  final url = '$baseUrl$endPoint';
  return CachedNetworkImage(
      imageUrl: url,
      imageBuilder: (context, imageProvider) => Column(
            children: [
              Image(key: _wordCloudImageKey, image: imageProvider),
              Container(
                margin: const EdgeInsets.only(top: 30, bottom: 0),
                child: ElevatedButton(
                  onPressed: () async {
                    // Find the Image widget
                    final image = findRenderImage(_wordCloudImageKey
                        .currentContext
                        ?.findRenderObject()) as RenderImage?;

                    if (image != null) {
                      //just a check, but the image will always exist if button appears
                      exportImage(image, "WordCloud");
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        Colors.orange, // Set the background color to orange
                  ),
                  child: const Text('Export Word Cloud',
                      style: TextStyle(fontSize: 17)),
                ),
              )
            ],
          ),
      placeholder: (context, url) => const Padding(
            padding: EdgeInsets.symmetric(vertical: 50),
            child: CircularProgressIndicator(color: Colors.orange),
          ),
      errorWidget: (context, url, error) => Container(
          margin: const EdgeInsets.symmetric(vertical: 30),
          child: const Text(
              textAlign: TextAlign.center,
              'Failed to load Word Cloud\n[object ProgressEvent]')));
}

final GlobalKey _occurrenceMatrixImageKey = GlobalKey();

Widget getOccurrences() {
  endPoint = 'occurrence_matrix';
  final url = '$baseUrl$endPoint';
  return CachedNetworkImage(
      imageUrl: url,
      imageBuilder: (context, imageProvider) => Column(
            children: [
              InteractiveViewer(
                  boundaryMargin: const EdgeInsets.all(5.0),
                  minScale: 0.1,
                  maxScale: 2,
                  child: Image(
                      key: _occurrenceMatrixImageKey, image: imageProvider)),
              Container(
                margin: const EdgeInsets.only(top: 30, bottom: 0),
                child: ElevatedButton(
                  onPressed: () async {
                    // Find the Image widget
                    final image = findRenderImage(_occurrenceMatrixImageKey
                        .currentContext
                        ?.findRenderObject()) as RenderImage?;

                    if (image != null) {
                      //just a check, but the image will always exist if button appears
                      exportImage(image, "Occurrence_Matrix");
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        Colors.orange, // Set the background color to orange
                  ),
                  child: const Text('Export Correlation Matrix',
                      style: TextStyle(fontSize: 17)),
                ),
              )
            ],
          ),
      placeholder: (context, url) => const Padding(
            padding: EdgeInsets.symmetric(vertical: 70),
            child: CircularProgressIndicator(color: Colors.orange),
          ),
      errorWidget: (context, url, error) => Container(
          margin: const EdgeInsets.symmetric(vertical: 70),
          child: const Text(
              textAlign: TextAlign.center,
              'Failed to load Occurrence Matrix\n[object ProgressEvent]')));
}

RenderObject? findRenderImage(RenderObject? object) {
  if (object == null) return null;
  if (object is RenderImage) return object;
  if (object is RenderProxyBox) {
    return findRenderImage(object.child);
  }
  return findRenderImage(object.parent as RenderObject?);
}

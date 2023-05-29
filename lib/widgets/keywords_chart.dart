import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../export_manager.dart';
import '../Models/keywords_model.dart';
import '../http.dart';

class KeywordsChart extends StatefulWidget {
  const KeywordsChart({Key? key}) : super(key: key);

  @override
  State<KeywordsChart> createState() => _KeywordsChartState();
}

class _KeywordsChartState extends State<KeywordsChart> {
  final GlobalKey<SfCartesianChartState> _cartesianChartKey = GlobalKey();

  late Future<Keywords> data;

  @override
  void initState() {
    data = getKeywordGraph();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Keywords>(
        future: data,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            // contains a non-null data value
            final keywordList = snapshot.data!.keywords.entries;

            // Return chart widget
            return Column(
              children: [
                SfCartesianChart(
                    key: _cartesianChartKey,
                    primaryXAxis: CategoryAxis(),
                    series: [
                      BarSeries<MapEntry<String, double>, String>(
                        name: 'Keywords',
                        dataSource: keywordList.toList()
                          ..sort((a, b) => a.value.compareTo(b.value)),
                        xValueMapper: (entry, _) => entry.key,
                        yValueMapper: (entry, _) => entry.value,
                      ),
                    ],
                    isTransposed: false,
                    trackballBehavior: TrackballBehavior(
                      enable: true,
                      activationMode: ActivationMode.singleTap,
                      tooltipSettings: const InteractiveTooltip(
                        format: 'point.x : point.y',
                      ),
                    )),
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  child: ElevatedButton(
                    onPressed: () async {
                      final ui.Image data = await _cartesianChartKey
                          .currentState!
                          .toImage(pixelRatio: 3.0);
                      final ByteData? bytes =
                          await data.toByteData(format: ui.ImageByteFormat.png);
                      final Uint8List imageBytes = bytes!.buffer.asUint8List(
                          bytes.offsetInBytes, bytes.lengthInBytes);

                      exportKeywordsChart(imageBytes);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          Colors.orange, // Set the background color to orange
                    ),
                    child: const Text('Export KeyWords Chart',
                        style: TextStyle(fontSize: 17)),
                  ),
                )
              ],
            );
          } else if (snapshot.hasError) {
            return Container(
                margin: const EdgeInsets.fromLTRB(50, 0, 50, 25),
                child: Text(
                    textAlign: TextAlign.center,
                    'Failed to load Keywords\n${snapshot.error}'));
          } else {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 50, vertical: 100),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.orange),
              ),
            );
          }
        });
  }
}

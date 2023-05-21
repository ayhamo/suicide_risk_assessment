import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../Models/keywords_model.dart';
import '../http.dart';

class KeywordsChart extends StatefulWidget {
  const KeywordsChart({Key? key}) : super(key: key);

  @override
  State<KeywordsChart> createState() => _KeywordsChartState();
}

class _KeywordsChartState extends State<KeywordsChart> {

  late Future<Keywords> data;

  @override
  void initState() {
    data = getKeywordExtraction();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Keywords>(
        future: data,
        builder: (context, snapshot) {
          if (snapshot.hasData) {  // contains a non-null data value
            final keywordList = snapshot.data!.keywords.entries;

            // Return chart widget
            return SfCartesianChart(
                primaryXAxis: CategoryAxis(),
                series: [
                  BarSeries<MapEntry<String, double>, String>(
                    name: 'Keywords',
                    dataSource: keywordList.toList()..sort((a, b) => a.value.compareTo(b.value)),
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
                )
            );

          } else if (snapshot.hasError) {
            return Text('${snapshot.error}');
          } else {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
        }
    );
  }
}
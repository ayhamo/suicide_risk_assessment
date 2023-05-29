import 'package:flutter/material.dart';
import 'package:suicide_risk_assessment/widgets/utils.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../http.dart';
import '../models/prediction_model.dart';

//ignore: must_be_immutable
class PredictionsChart extends StatefulWidget {
  String text;
  bool defaultChart;
  Predictions? arrData;

  //flag used to prevent future from update on widget update
  bool predictNewData;

  //call back to update variables in main
  final Function(Predictions) onArrUpdate;

  //call back to update predict risk button if no internet
  final VoidCallback updateButton; //

  PredictionsChart({
    Key? key,
    required this.text,
    required this.defaultChart,
    required this.arrData,
    required this.predictNewData,
    required this.onArrUpdate,
    required this.updateButton,
  }) : super(key: key);

  @override
  State<PredictionsChart> createState() => _PredictionsChartState();
}

class _PredictionsChartState extends State<PredictionsChart> {
  late Future<Predictions> data;

  final tooltipBehavior = TooltipBehavior(
    enable: true,
    format: 'point.x: point.y',
    textStyle: const TextStyle(
      color: Colors.white,
      fontSize: 13,
    ),
  );

  final defaultChartData = [
    PredictionData("anger", 1.0, const Color(0xff4b87b9)),
    PredictionData("disgust", 1.0, const Color(0xfff67280)),
    PredictionData("fear", 0.5, const Color(0xfff8b195)),
    PredictionData("hopefullness", 1.0, const Color(0xff74b49b)),
    PredictionData("hopelessness", 1.0, const Color(0xff00a8b5)),
    PredictionData("joy", 1.0, const Color(0xff494ca2)),
    PredictionData("sadness", 1.0, const Color(0xffffcd60)),
  ];

  @override
  void didUpdateWidget(covariant PredictionsChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.defaultChart && widget.predictNewData) {
      Predictions? value;

      data = getPrediction(widget.text).then((result) {
        //callback to update variables in main
        value = result;
        widget.onArrUpdate(value!);
        return result;
      }).catchError((e) {
        widget.updateButton();
        throw e;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.arrData != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 30),
        child: Container(
          width: 450,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.5),
                spreadRadius: 1,
                blurRadius: 2,
              ),
            ],
          ),
          child: Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 20, horizontal: 50),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          'Suicide Risk',
                          style: TextStyle(color: Colors.black, fontSize: 15),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            widget.arrData!.suicideRisk.toTitleCase(),
                            style: const TextStyle(
                                color: Colors.blue,
                                fontSize: 30,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          'Sentiment Analysis',
                          style: TextStyle(color: Colors.black, fontSize: 15),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            widget.arrData!.sentiment.entries
                                        .reduce(
                                            (a, b) => a.value > b.value ? a : b)
                                        .key ==
                                    'pos'
                                ? 'Positive'
                                : 'Negative',
                            style: const TextStyle(
                                color: Colors.blue,
                                fontSize: 30,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              MouseRegion(
                onExit: (_) {
                  // Hide the tooltip when the mouse pointer leaves the chart area
                  tooltipBehavior.hide();
                },
                child: Column(
                  children: [
                    SfCircularChart(
                      tooltipBehavior: tooltipBehavior,
                      series: <CircularSeries>[
                        PieSeries<PredictionData, String>(
                          dataSource: widget.arrData!.emotions.entries
                              .map((entry) => PredictionData(entry.key,
                                  entry.value, getColorForEmotion(entry.key)))
                              .toList(),
                          xValueMapper: (PredictionData data, _) =>
                              data.emotion,
                          yValueMapper: (PredictionData data, _) => data.value,
                          pointColorMapper: (PredictionData data, _) =>
                              data.color,
                          legendIconType: LegendIconType.circle,
                          radius: "120",
                        ),
                      ],
                    ),
                    Center(
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children:
                                defaultChartData.getRange(0, 4).map((data) {
                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    height: 20,
                                    width: 20,
                                    //color: data.color,
                                    decoration: BoxDecoration(
                                      color: data.color,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    data.emotion,
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            runSpacing: 8,
                            alignment: WrapAlignment.center,
                            children: defaultChartData
                                .getRange(4, defaultChartData.length)
                                .map((data) {
                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    height: 20,
                                    width: 20,
                                    decoration: BoxDecoration(
                                      color: data.color,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    data.emotion,
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                              );
                            }).toList(),
                          )
                        ],
                      ),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 20)
            ],
          ),
        ),
      );
    } else if (!widget.defaultChart) {
      return FutureBuilder<Predictions>(
          future: data,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 460,
                child: Center(
                  child: CircularProgressIndicator(
                    color: Colors.orange,
                  ),
                ),
              );
            }
            if (snapshot.hasData) {
              final predictions = snapshot.data;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 30),
                child: Container(
                  width: 450,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.5),
                        spreadRadius: 1,
                        blurRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 20, horizontal: 50),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Text(
                                  'Suicide Risk',
                                  style: TextStyle(
                                      color: Colors.black, fontSize: 15),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    predictions!.suicideRisk,
                                    style: const TextStyle(
                                        color: Colors.blue,
                                        fontSize: 30,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Text(
                                  'Sentiment Analysis',
                                  style: TextStyle(
                                      color: Colors.black, fontSize: 15),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    predictions.sentiment.entries
                                                .reduce((a, b) =>
                                                    a.value > b.value ? a : b)
                                                .key ==
                                            'pos'
                                        ? 'Positive'
                                        : 'Negative',
                                    style: const TextStyle(
                                        color: Colors.blue,
                                        fontSize: 30,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      MouseRegion(
                        onExit: (_) {
                          // Hide the tooltip when the mouse pointer leaves the chart area
                          tooltipBehavior.hide();
                        },
                        child: Column(
                          children: [
                            SfCircularChart(
                              tooltipBehavior: tooltipBehavior,
                              series: <CircularSeries>[
                                PieSeries<PredictionData, String>(
                                  dataSource: predictions.emotions.entries
                                      .map((entry) => PredictionData(
                                          entry.key,
                                          entry.value,
                                          getColorForEmotion(entry.key)))
                                      .toList(),
                                  xValueMapper: (PredictionData data, _) =>
                                      data.emotion,
                                  yValueMapper: (PredictionData data, _) =>
                                      data.value,
                                  pointColorMapper: (PredictionData data, _) =>
                                      data.color,
                                  legendIconType: LegendIconType.circle,
                                  radius: "120",
                                ),
                              ],
                            ),
                            Center(
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: defaultChartData
                                        .getRange(0, 4)
                                        .map((data) {
                                      return Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            height: 20,
                                            width: 20,
                                            //color: data.color,
                                            decoration: BoxDecoration(
                                              color: data.color,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            data.emotion,
                                            style:
                                                const TextStyle(fontSize: 16),
                                          ),
                                          const SizedBox(width: 8),
                                        ],
                                      );
                                    }).toList(),
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    runSpacing: 8,
                                    alignment: WrapAlignment.center,
                                    children: defaultChartData
                                        .getRange(4, defaultChartData.length)
                                        .map((data) {
                                      return Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            height: 20,
                                            width: 20,
                                            decoration: BoxDecoration(
                                              color: data.color,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            data.emotion,
                                            style:
                                                const TextStyle(fontSize: 16),
                                          ),
                                          const SizedBox(width: 8),
                                        ],
                                      );
                                    }).toList(),
                                  )
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                      const SizedBox(height: 20)
                    ],
                  ),
                ),
              );
            } else if (snapshot.hasError) {
              return Container(
                margin: const EdgeInsets.only(top: 40),
                height: 70,
                child: Text(
                  textAlign: TextAlign.center,
                  'Server Error have occurred\n${snapshot.error}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              );
            } else {
              return const SizedBox(
                height: 460,
                child: Center(
                  child: CircularProgressIndicator(
                    color: Colors.orange,
                  ),
                ),
              );
            }
          });
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 30),
      child: Container(
        width: 450,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.5),
              spreadRadius: 1,
              blurRadius: 2,
            ),
          ],
        ),
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20, horizontal: 50),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Suicide Risk',
                        style: TextStyle(color: Colors.black, fontSize: 15),
                      ),
                      Padding(
                        padding: EdgeInsets.only(top: 8.0),
                        child: Text(
                          '- - -',
                          style: TextStyle(
                              color: Colors.blue,
                              fontSize: 30,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Sentiment Analysis',
                        style: TextStyle(color: Colors.black, fontSize: 15),
                      ),
                      Padding(
                        padding: EdgeInsets.only(top: 8.0),
                        child: Text(
                          '- - -',
                          style: TextStyle(
                              color: Colors.blue,
                              fontSize: 30,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            MouseRegion(
              onExit: (_) {
                // Hide the tooltip when the mouse pointer leaves the chart area
                tooltipBehavior.hide();
              },
              child: Column(
                children: [
                  SfCircularChart(
                    tooltipBehavior: tooltipBehavior,
                    series: <CircularSeries>[
                      PieSeries<PredictionData, String>(
                        dataSource: defaultChartData,
                        xValueMapper: (PredictionData data, _) => data.emotion,
                        yValueMapper: (PredictionData data, _) => data.value,
                        pointColorMapper: (PredictionData data, _) =>
                            data.color,
                        legendIconType: LegendIconType.circle,
                        radius: "120",
                      ),
                    ],
                  ),
                  Center(
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: defaultChartData.getRange(0, 4).map((data) {
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  height: 20,
                                  width: 20,
                                  //color: data.color,
                                  decoration: BoxDecoration(
                                    color: data.color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  data.emotion,
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const SizedBox(width: 8),
                              ],
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: defaultChartData
                              .getRange(4, defaultChartData.length)
                              .map((data) {
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  height: 20,
                                  width: 20,
                                  decoration: BoxDecoration(
                                    color: data.color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  data.emotion,
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const SizedBox(width: 8),
                              ],
                            );
                          }).toList(),
                        )
                      ],
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 20)
          ],
        ),
      ),
    );
  }
}

Color getColorForEmotion(String emotion) {
  switch (emotion) {
    case "anger":
      return const Color(0xff4b87b9);
    case "disgust":
      return const Color(0xfff67280);
    case "fear":
      return const Color(0xfff8b195);
    case "hopefullness":
      return const Color(0xff74b49b);
    case "hopelessness":
      return const Color(0xff00a8b5);
    case "joy":
      return const Color(0xff494ca2);
    case "sadness":
      return const Color(0xffffcd60);
    default:
      return Colors.grey;
  }
}

class PredictionData {
  final String emotion;
  final double value;
  final Color color;

  PredictionData(this.emotion, this.value, this.color);
}

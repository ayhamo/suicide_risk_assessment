import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:suicide_risk_assessment/Widgets/predictions_chart.dart';
import 'package:suicide_risk_assessment/widgets/keywords_chart.dart';
import 'package:suicide_risk_assessment/widgets/responsive.dart';

import 'data.dart';
import 'http.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Suicide Risk Assessment',
      builder: FToastBuilder(),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _textController = TextEditingController();

  bool _isMenuVisible = false;
  bool defaultChartFlag = true;

  final double mainHorizontalPadding = 50;
  late FToast fToast;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      fToast = FToast();
      fToast.init(context);

      loadModels().then((result) {
        fToast.showToast(
          child: toast(result),
          gravity: ToastGravity.BOTTOM,
          toastDuration: const Duration(seconds: 5),
        );
      });
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!ResponsiveWidget.isSmallScreen(context)) {
      _isMenuVisible = false;
    }
    return SelectionArea(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          toolbarHeight: _isMenuVisible ? 140 : 75,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Image.asset(
                'assets/logo.png',
                fit: BoxFit.contain,
                height: 65,
              ),
              Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                  child: const Text(
                    'Suicide Risk\nAssessment',
                    style: TextStyle(color: Colors.black),
                  ))
            ],
          ),
          actions: <Widget>[
            ResponsiveWidget.isSmallScreen(context)
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(10, 10, 30, 10),
                    child: IconButton(
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      icon: const Icon(
                        Icons.menu,
                        color: Colors.orange,
                      ),
                      onPressed: () {
                        setState(() {
                          _isMenuVisible = !_isMenuVisible;
                        });
                      },
                    ))
                : Padding(
                    padding: const EdgeInsets.only(right: 30),
                    child: Row(
                      children: [
                        TextButton(
                          style: ButtonStyle(
                            foregroundColor:
                                MaterialStateProperty.resolveWith<Color>(
                                    (Set<MaterialState> states) {
                              if (states.contains(MaterialState.hovered)) {
                                return Colors.orange;
                              }
                              return Colors.black;
                            }),
                            overlayColor:
                                MaterialStateProperty.all(Colors.transparent),
                          ),
                          onPressed: () {},
                          child: const Text("Predict"),
                        ),
                        TextButton(
                          style: ButtonStyle(
                            foregroundColor:
                                MaterialStateProperty.resolveWith<Color>(
                                    (Set<MaterialState> states) {
                              if (states.contains(MaterialState.hovered)) {
                                return Colors.orange;
                              }
                              return Colors.black;
                            }),
                            overlayColor:
                                MaterialStateProperty.all(Colors.transparent),
                          ),
                          onPressed: () {},
                          child: const Text("Keywords\nExtracted"),
                        ),
                        TextButton(
                          style: ButtonStyle(
                            foregroundColor:
                                MaterialStateProperty.resolveWith<Color>(
                                    (Set<MaterialState> states) {
                              if (states.contains(MaterialState.hovered)) {
                                return Colors.orange;
                              }
                              return Colors.black;
                            }),
                            overlayColor:
                                MaterialStateProperty.all(Colors.transparent),
                          ),
                          onPressed: () {},
                          child: const Text("Correlation\nAnalysis"),
                        ),
                      ],
                    ),
                  ),
          ],
          bottom: _isMenuVisible
              ? PreferredSize(
                  preferredSize: const Size.fromHeight(kToolbarHeight),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Column(
                        //TODO Add slide in/out animation https://komprehend.io/text-classification
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Divider(),
                          TextButton(
                            style: ButtonStyle(
                              foregroundColor:
                                  MaterialStateProperty.resolveWith<Color>(
                                      (Set<MaterialState> states) {
                                if (states.contains(MaterialState.hovered)) {
                                  return Colors.orange;
                                }
                                return Colors.black;
                              }),
                              overlayColor:
                                  MaterialStateProperty.all(Colors.transparent),
                            ),
                            onPressed: () {},
                            child: const Text("Predict"),
                          ),
                          const SizedBox(height: 10),
                          TextButton(
                            style: ButtonStyle(
                              foregroundColor:
                                  MaterialStateProperty.resolveWith<Color>(
                                      (Set<MaterialState> states) {
                                if (states.contains(MaterialState.hovered)) {
                                  return Colors.orange;
                                }
                                return Colors.black;
                              }),
                              overlayColor:
                                  MaterialStateProperty.all(Colors.transparent),
                            ),
                            onPressed: () {},
                            child: const Text("Keywords Extracted"),
                          ),
                          const SizedBox(height: 10),
                          TextButton(
                            style: ButtonStyle(
                              foregroundColor:
                                  MaterialStateProperty.resolveWith<Color>(
                                      (Set<MaterialState> states) {
                                if (states.contains(MaterialState.hovered)) {
                                  return Colors.orange;
                                }
                                return Colors.black;
                              }),
                              overlayColor:
                                  MaterialStateProperty.all(Colors.transparent),
                            ),
                            onPressed: () {},
                            child: const Text("Correlation Analysis"),
                          ),
                          const SizedBox(height: 10),
                        ],
                      ),
                    ),
                  ),
                )
              : const PreferredSize(
                  preferredSize: Size(0, 0), child: SizedBox()),
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(
                    vertical: 20, horizontal: mainHorizontalPadding),
                child: TextField(
                  decoration: InputDecoration(
                    labelText: 'Review Text',
                    alignLabelWithHint: true,
                    fillColor: Colors.transparent,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          const BorderSide(color: Colors.black, width: 2),
                    ),
                  ),
                  autofocus: true,
                  controller: _textController,
                  keyboardType: TextInputType.multiline,
                  maxLength: null,
                  maxLines: 8,
                ),
              ),
              Padding(
                padding:
                    EdgeInsets.symmetric(horizontal: mainHorizontalPadding),
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: TextButton(
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                          ),
                          onPressed: () {
                            setState(() {
                              if (!Data.disableButton) {
                                defaultChartFlag = false;
                                Data.disableButton = true;
                                Data.predictionNewData = true;
                              }
                            });
                          },
                          child: const Text(
                            'Predict Risk',
                            style: TextStyle(color: Colors.white, fontSize: 20),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Colors.orange,
                      ),
                      onPressed: () {},
                      iconSize: 40,
                    ),
                    const SizedBox(width: 20),
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_forward,
                        color: Colors.orange,
                      ),
                      onPressed: () {},
                      iconSize: 40,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(
                    vertical: 20, horizontal: mainHorizontalPadding),
                child: const Divider(thickness: 1),
              ),
              const Text(
                'PREDICTION',
                style: TextStyle(
                    color: Colors.grey,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 3),
              ),
              PredictionsChart(
                  text: _textController.text, defaultChart: defaultChartFlag),
              const SizedBox(height: 30),
              Text("TEST"),
              //KeywordsChart(),
              //getOccurrences(),
            ],
          ),
        ),
      ),
    );
  }
}

Widget toast(String string) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(25.0),
      color: const Color(0xFF656565),
    ),
    child: Text(
      string,
      style: const TextStyle(color: Colors.white),
    ),
  );
}

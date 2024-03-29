import 'package:flutter/material.dart';

import 'package:fluttertoast/fluttertoast.dart';
import 'package:suicide_risk_assessment/widgets/responsive.dart';
import 'package:suicide_risk_assessment/Widgets/predictions_chart.dart';
import 'package:suicide_risk_assessment/widgets/keywords_chart.dart';

import 'export_manager.dart';
import 'http.dart';
import 'models/prediction_model.dart';

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
  bool _textValidate = false;
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _keywordsDividerKey = GlobalKey();
  final GlobalKey _matrixDividerKey = GlobalKey();

  bool _isMenuVisible = false;

  List<Predictions> predictionsList = [];

  //Store texts for export
  List<String> predictionTextList = [];

  //prediction chart placeholder
  bool defaultPieChartFlag = true;

  //prevent multiple request abuse, wait till first request ends
  bool disableButton = false;

  bool disableImportButton = false;

  //used to prevent didUpdateWidget in predictions_chart from requesting
  //server(rebuild) when widget updates (screen size changes)
  bool predictNewData = false;

  //traversing data
  int currentArrIndex = -1;
  Predictions? arrData;

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
                          onPressed: () {
                            // Scroll to top of page
                            _scrollController.animateTo(0.0,
                                duration: const Duration(milliseconds: 500),
                                curve: Curves.easeInOut);
                          },
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
                          onPressed: () {
                            Scrollable.ensureVisible(
                                _keywordsDividerKey.currentContext!,
                                duration: const Duration(milliseconds: 500),
                                curve: Curves.easeInOut);
                          },
                          child: const Text(
                              textAlign: TextAlign.center,
                              "Keywords\nExtracted"),
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
                          onPressed: () {
                            Scrollable.ensureVisible(
                                _matrixDividerKey.currentContext!,
                                duration: const Duration(milliseconds: 500),
                                curve: Curves.easeInOut);
                          },
                          child: const Text(
                              textAlign: TextAlign.center,
                              "Correlation\nAnalysis"),
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
                            onPressed: () {
                              setState(() {
                                _isMenuVisible = false;
                              });

                              _scrollController.animateTo(0.0,
                                  duration: const Duration(milliseconds: 500),
                                  curve: Curves.easeInOut);
                            },
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
                            onPressed: () {
                              setState(() {
                                _isMenuVisible = false;
                              });

                              Scrollable.ensureVisible(
                                  _keywordsDividerKey.currentContext!,
                                  duration: const Duration(milliseconds: 500),
                                  curve: Curves.easeInOut);
                            },
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
                            onPressed: () {
                              setState(() {
                                _isMenuVisible = false;
                              });

                              Scrollable.ensureVisible(
                                  _matrixDividerKey.currentContext!,
                                  duration: const Duration(milliseconds: 500),
                                  curve: Curves.easeInOut);
                            },
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
          controller: _scrollController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                    mainHorizontalPadding, 20, mainHorizontalPadding, 10),
                child: TextField(
                  decoration: InputDecoration(
                    labelText: 'Review Text',
                    errorText: _textValidate
                        ? 'Review Text Can\'t Be Less Than 5 Characters'
                        : null,
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
              const Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: Text(
                    "* The more text you provide the more accurate results you will get.",
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
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
                            backgroundColor: disableButton
                                ? Colors.black.withOpacity(0.5)
                                : Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                          ),
                          onPressed: () {
                            setState(() {
                              if (_textController.text.length < 5) {
                                _textValidate = true;
                              } else {
                                _textValidate = false;
                                if (!disableButton) {
                                  //all flags are explained above
                                  defaultPieChartFlag = false;
                                  disableButton = true;
                                  predictNewData = true;

                                  //stop the traversal and go to new prediction
                                  arrData = null;
                                }
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
                      icon: Icon(
                        Icons.arrow_back,
                        color: currentArrIndex == 0 || currentArrIndex == -1
                            ? Colors.grey
                            : Colors.orange,
                      ),
                      onPressed: () {
                        setState(() {
                          if (currentArrIndex > 0) {
                            currentArrIndex--;
                            arrData = predictionsList[currentArrIndex];
                            _textController.text =
                                predictionTextList[currentArrIndex];
                          }
                        });
                      },
                      iconSize: 40,
                    ),
                    const SizedBox(width: 20),
                    IconButton(
                      icon: Icon(
                        Icons.arrow_forward,
                        color: currentArrIndex == predictionsList.length - 1
                            ? Colors.grey
                            : Colors.orange,
                      ),
                      onPressed: () {
                        setState(() {
                          if (currentArrIndex < predictionsList.length - 1) {
                            currentArrIndex++;
                            arrData = predictionsList[currentArrIndex];
                            _textController.text =
                                predictionTextList[currentArrIndex];
                          }
                        });
                      },
                      iconSize: 40,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 15),
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
                            backgroundColor: disableImportButton
                                ? Colors.black.withOpacity(0.5)
                                : Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                          ),
                          onPressed: () async {
                            if (disableImportButton) {
                              null;
                            }
                            setState(() {
                              disableImportButton = true;
                            });
                            await importPredictions().then((result) {
                              var (a, b) = result;
                              predictionTextList = a; //.addAll(a);
                              predictionsList = b;
                              setState(() {
                                if (predictionsList.isNotEmpty) {
                                  arrData = predictionsList[0];
                                  currentArrIndex = 0;
                                  _textController.text = predictionTextList[0];
                                }
                                disableImportButton = false;
                              });
                            }).catchError((e) {
                              setState(() {
                                disableImportButton = false;
                              });
                              showDialog<void>(
                                  context: context,
                                  barrierDismissible: true,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: const Text(
                                        'ALERT',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(color: Colors.red),
                                      ),
                                      content: Text(
                                          textAlign: TextAlign.center,
                                          "Error reading excel file\n$e",
                                          style: const TextStyle(fontSize: 17)),
                                      actions: <Widget>[
                                        TextButton(
                                          child: const Text('OK'),
                                          onPressed: () {
                                            Navigator.pop(context);
                                          },
                                        ),
                                      ],
                                    );
                                  });
                            });
                          },
                          child: const Text(
                            'Import Data',
                            style: TextStyle(color: Colors.white, fontSize: 20),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: TextButton(
                          style: TextButton.styleFrom(
                            backgroundColor: predictionsList.isEmpty
                                ? Colors.black.withOpacity(0.5)
                                : Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                          ),
                          onPressed: () async {
                            predictionsList
                                    .isEmpty //no need to check the text list as both are updated in same place on a callback
                                ? null
                                : exportPredictions(
                                    predictionTextList, predictionsList);
                          },
                          child: const Text(
                            'Export Data',
                            style: TextStyle(color: Colors.white, fontSize: 20),
                          ),
                        ),
                      ),
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
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 3),
              ),
              PredictionsChart(
                  text: _textController.text,
                  defaultChart: defaultPieChartFlag,
                  arrData: arrData,
                  predictNewData: predictNewData,
                  onArrUpdate: (result) {
                    setState(() {
                      //add the prediction text to the list
                      predictionTextList.add(_textController.text);

                      //add the new prediction to the traversal list
                      predictionsList.add(result);

                      //make button enabled
                      disableButton = false;

                      //no more predicting, so stop updating the future on widget update
                      predictNewData = false;

                      //increment index to match last prediction
                      currentArrIndex = predictionsList.length - 1;
                    });
                  },
                  updateButton: () {
                    setState(() {
                      //make button enabled
                      disableButton = false;

                      //no more predicting, so stop updating the future on widget update
                      predictNewData = false;
                    });
                  }),
              Padding(
                padding: EdgeInsets.symmetric(
                    vertical: 10, horizontal: mainHorizontalPadding),
                child: Divider(key: _keywordsDividerKey, thickness: 1),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  'DATASET KEYWORDS EXTRACTION',
                  style: TextStyle(
                      color: Colors.grey,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 3),
                ),
              ),
              Container(
                  margin: const EdgeInsets.symmetric(horizontal: 60),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
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
                      const KeywordsChart(),
                      const Divider(),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Text(
                          'WORD CLOUD',
                          style: TextStyle(
                              color: Colors.grey,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 3),
                        ),
                      ),
                      getKeywordsWordcloud(),
                    ],
                  )),
              Padding(
                padding: EdgeInsets.symmetric(
                    vertical: 10, horizontal: mainHorizontalPadding),
                child: Divider(key: _matrixDividerKey, thickness: 1),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 20),
                child: Text(
                  'DATASET CORRELATION ANALYSIS',
                  style: TextStyle(
                      color: Colors.grey,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 3),
                ),
              ),
              ResponsiveWidget.isSmallScreen(context)
                  ? const SizedBox()
                  : const Text("(hold CTRL while zooming)",
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 20,
                      )),
              Container(
                  width: double.infinity,
                  margin:
                      const EdgeInsets.symmetric(horizontal: 60, vertical: 30),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 30, vertical: 30),
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
                  child: Center(
                    child: getOccurrences(),
                  )),
            ],
          ),
        ),
      ),
    );
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
}

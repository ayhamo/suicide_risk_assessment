import 'dart:ui' as ui;
import 'dart:html' as html;

import 'package:flutter/foundation.dart';
import 'package:excel/excel.dart' as excel;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/rendering.dart';

import 'models/prediction_model.dart';

void exportPredictions(
    List<String> predictionTextList, List<Predictions> predictionsList) async {
  // Move the heavy processing code to a separate isolate
  final blob =
      await compute(processExportData, [predictionTextList, predictionsList]); //TODO Check discord on why compute still lags

  final now = DateTime.now();
  final fileName =
      '${now.day}_${now.month}_${now.hour}_${now.minute}_risk_result.xlsx';

  // Create a new AnchorElement with a download attribute
  html.AnchorElement()
    ..href = html.Url.createObjectUrlFromBlob(blob)
    ..download = fileName
    ..click();
}

// Function to process export data in a separate isolate
html.Blob processExportData(List<dynamic> args) {
  // Unpack arguments
  final predictionTextList = args[0] as List<String>;
  final predictionsList = args[1] as List<Predictions>;

  // Create a new Excel object
  final excelObject = excel.Excel.createExcel();

  // Get a reference to the default "Sheet1"
  const sheet = 'Sheet1';

  // Add headers to the first row of the sheet
  excelObject.updateCell(sheet, excel.CellIndex.indexByString("A1"), 'Text');
  excelObject.updateCell(
      sheet, excel.CellIndex.indexByString("B1"), 'Suicide Risk');
  excelObject.updateCell(
      sheet, excel.CellIndex.indexByString("C1"), 'Positive');
  excelObject.updateCell(
      sheet, excel.CellIndex.indexByString("D1"), 'Negative');
  excelObject.updateCell(sheet, excel.CellIndex.indexByString("E1"), 'Anger');
  excelObject.updateCell(sheet, excel.CellIndex.indexByString("F1"), 'Fear');
  excelObject.updateCell(
      sheet, excel.CellIndex.indexByString("G1"), 'Hopefullness');
  excelObject.updateCell(
      sheet, excel.CellIndex.indexByString("H1"), 'Hopelessness');
  excelObject.updateCell(sheet, excel.CellIndex.indexByString("I1"), 'Joy');
  excelObject.updateCell(sheet, excel.CellIndex.indexByString("J1"), 'Sadness');
  excelObject.updateCell(sheet, excel.CellIndex.indexByString("K1"), 'Disgust');

  // Add data to the sheet
  for (int i = 0; i < predictionsList.length; i++) {
    final prediction = predictionsList[i];
    final row = i + 1;
    excelObject.updateCell(
        sheet,
        excel.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row),
        predictionTextList[i]);
    excelObject.updateCell(
        sheet,
        excel.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row),
        prediction.suicideRisk);
    excelObject.updateCell(
        sheet,
        excel.CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row),
        prediction.sentiment['pos']);
    excelObject.updateCell(
        sheet,
        excel.CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row),
        prediction.sentiment['neg']);
    excelObject.updateCell(
        sheet,
        excel.CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row),
        prediction.emotions['anger']);
    excelObject.updateCell(
        sheet,
        excel.CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row),
        prediction.emotions['fear']);
    excelObject.updateCell(
        sheet,
        excel.CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: row),
        prediction.emotions['hopefullness']);
    excelObject.updateCell(
        sheet,
        excel.CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: row),
        prediction.emotions['hopelessness']);
    excelObject.updateCell(
        sheet,
        excel.CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: row),
        prediction.emotions['joy']);
    excelObject.updateCell(
        sheet,
        excel.CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: row),
        prediction.emotions['sadness']);
    excelObject.updateCell(
        sheet,
        excel.CellIndex.indexByColumnRow(columnIndex: 10, rowIndex: row),
        prediction.emotions['disgust']);
  }

  final bytes = excelObject.encode();

  // Create a new Blob from the Uint8List
  final blob = html.Blob([bytes],
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');

  return blob;
}

Future<(List<String>, List<Predictions>)> importPredictions() async {
  // Get the file from the user
  final result = await FilePicker.platform
      .pickFiles(type: FileType.custom, allowedExtensions: ['xlsx']);

  if (result != null) {
    // Move the heavy file processing code to a separate isolate
    final data = await compute(processSheetData, result);

    return data;
  } else {
    //User cancelled
  }
  // Return empty lists
  return (<String>[], <Predictions>[]);
}

// Function to process sheet data in a separate isolate
Future<(List<String>, List<Predictions>)> processSheetData(FilePickerResult result) async{
  // Decode the file as an Excel object
  final bytes = result.files.single.bytes;
  final excelObject = excel.Excel.decodeBytes(bytes as List<int>);

  // Get a reference to the default "Sheet1"
  const sheet = 'Sheet1';
  final sheetData = excelObject.tables[sheet];

  // Check if sheetData is not null
  if (sheetData != null) {
    // Create new lists to hold the imported data
    final predictionTextList = <String>[];
    final predictionsList = <Predictions>[];

    // Check if first row has exact column values
    final firstRowValues = [
      'text',
      'suicide risk',
      'positive',
      'negative',
      'anger',
      'fear',
      'hopefullness',
      'hopelessness',
      'joy',
      'sadness',
      'disgust'
    ];

    //Define the valid values for suicideRisk
    final suicideRiskValues = [
      'anxiety',
      'suicidewatch',
      'bipolar',
      'depression',
      'offmychest'
    ];

    for (int col = 0; col < firstRowValues.length; col++) {
      final cellValue = sheetData
          .cell(excel.CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0))
          .value
          .toString()
          .toLowerCase();
      if (cellValue != firstRowValues[col]) {
        throw Exception(
            "First row headers (${firstRowValues[col]}) mismatched");
      }
    }

    // Iterate over the rows of data in the sheet
    for (int row = 1; row < sheetData.maxRows; row++) {
      // Get the data from each cell in the row
      final textCell = sheetData.cell(
          excel.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row));
      final suicideRiskCell = sheetData.cell(
          excel.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row));
      final positiveCell = sheetData.cell(
          excel.CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row));
      final negativeCell = sheetData.cell(
          excel.CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row));
      final angerCell = sheetData.cell(
          excel.CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row));
      final fearCell = sheetData.cell(
          excel.CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row));
      final hopefullnessCell = sheetData.cell(
          excel.CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: row));
      final hopelessnessCell = sheetData.cell(
          excel.CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: row));
      final joyCell = sheetData.cell(
          excel.CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: row));
      final sadnessCell = sheetData.cell(
          excel.CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: row));
      final disgustCell = sheetData.cell(
          excel.CellIndex.indexByColumnRow(columnIndex: 10, rowIndex: row));

      // Get the value of each cell
      final text = textCell.value.toString();
      final suicideRisk = suicideRiskCell.value.toString().toLowerCase();
      final positive = positiveCell.value;
      final negative = negativeCell.value;
      final anger = angerCell.value;
      final fear = fearCell.value;
      final hopefullness = hopefullnessCell.value;
      final hopelessness = hopelessnessCell.value;
      final joy = joyCell.value;
      final sadness = sadnessCell.value;
      final disgust = disgustCell.value;

      if (text.isEmpty) {
        throw Exception("No Text at row: ${row + 1}");
      }

      if (suicideRisk.isEmpty || !suicideRiskValues.contains(suicideRisk)) {
        throw Exception("Suicide risk mismatch at row: ${row + 1}");
      }

      validateDouble(positiveCell.value, 'Positive', row);
      validateDouble(negativeCell.value, 'Negative', row);
      validateDouble(angerCell.value, 'Anger', row);
      validateDouble(fearCell.value, 'Fear', row);
      validateDouble(hopefullnessCell.value, 'Hopefullness', row);
      validateDouble(hopelessnessCell.value, 'Hopelessness', row);
      validateDouble(joyCell.value, 'Joy', row);
      validateDouble(sadnessCell.value, 'Sadness', row);
      validateDouble(disgustCell.value, 'Disgust', row);

      // Add the data to the lists
      predictionTextList.add(text);
      predictionsList.add(Predictions(
        suicideRisk: suicideRisk,
        sentiment: {'pos': positive, 'neg': negative},
        emotions: {
          'anger': anger,
          'fear': fear,
          'hopefullness': hopefullness,
          'hopelessness': hopelessness,
          'joy': joy,
          'sadness': sadness,
          'disgust': disgust
        },
      ));
    }

    // Return the lists
    return (predictionTextList, predictionsList);
  } else {
    throw Exception("Prediction Sheet does not exist");
  }
}

void validateDouble(double? value, String varName, int index) {
  if (value == 1) {
    value = 1.00;
  }
  if (value is! double || value >= 1.01) {
    throw Exception(
        '$varName column at row ${index + 1} is not a double value');
  }
}

void exportKeywordsChart(Uint8List imageBytes) async {
// Create a blob with the image data
  final blob = html.Blob([imageBytes], 'image/png');

// Create an anchor element and simulate a click to download the image
  html.AnchorElement()
    ..href = html.Url.createObjectUrlFromBlob(blob).toString()
    ..download = 'KeyWords_Extraction_Chart.png'
    ..style.display = 'none'
    ..click();
}

//Export WordCloud or Correlation matrix
void exportImage(RenderImage image, String fileName) async {
// Get the image data
  final bytes = await image.image?.toByteData(format: ui.ImageByteFormat.png);
  final buffer = bytes?.buffer.asUint8List();

  if (buffer != null) {
// Create a blob with the image data
    final blob = html.Blob([buffer], 'image/png');

// Create an anchor element and simulate a click to download the image
    html.AnchorElement()
      ..href = html.Url.createObjectUrlFromBlob(blob).toString()
      ..download = '$fileName.png'
      ..style.display = 'none'
      ..click();
  }
}

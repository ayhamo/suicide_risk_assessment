import 'package:flutter/material.dart';

import '../http.dart';

class OccurrencesMatrix extends StatelessWidget {
  const OccurrencesMatrix({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return getOccurrences();
  }
}

import 'package:flutter/material.dart';

import '../http.dart';

class WordCloud extends StatelessWidget {
  const WordCloud({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return getKeywordsWordcloud();
  }
}

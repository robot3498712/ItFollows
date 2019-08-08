import 'package:flutter/material.dart';
import 'package:ItFollows/list.dart';

void main() => runApp(MaterialApp(
  home: ListNotes(),
  theme: ThemeData(
      primaryColor: Colors.grey,
      primarySwatch: Colors.grey
  ),
  debugShowCheckedModeBanner: false,
));

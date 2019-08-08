import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:validators/validators.dart' as valid;
//import 'package:flutter/gestures.dart'; // gesture, url_launcher not used
//import 'package:url_launcher/url_launcher.dart' as url_launcher;
import 'package:device_apps/device_apps.dart';
import 'dart:io'; // file juggling
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Conf {
 static String urlGet = "";
 static String urlPost = "";
}

String dataShared = "";

getConf() async { // see list::initState()
  SharedPreferences prefs = await SharedPreferences.getInstance();
  Conf.urlGet = prefs.getString('urlGet') ?? "";
  Conf.urlPost = prefs.getString('urlPost') ?? "";
}

setConf(_get, _post) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  Conf.urlGet = _get;
  Conf.urlPost = _post;
  prefs.setString('urlGet', _get);
  prefs.setString('urlPost', _post);
}

String generateMd5(String input) {
  return md5.convert(utf8.encode(input)).toString();
}

Future<String> get _localPath async {
  final directory = await getApplicationDocumentsDirectory();
  return directory.path;
}

Future<File> get _localFile async {
  final path = await _localPath;
  return File('$path/notes.json');
}

Future<File> writeNotes(String notes) async {
  final file = await _localFile;
  return file.writeAsString('$notes');
}

Future<String> readNotes() async {
  try {
    final file = await _localFile;
    String contents = await file.readAsString();
    return contents;
  } catch (e) {
    return '[]';
  }
}

enum BinaryAction {
  yes,
  no,
}

List<TextSpan> _getSpans(String text) {
  List<TextSpan> spans = [];
  var words = text.split(" ");
  var _len = words.length;

  for(var i = 0; i < _len; i++) {
    String pad = (i == _len-1) ? '' : " ";
    if (valid.isURL(words[i])) {
      spans.add(
          TextSpan(
            text: "${words[i]}$pad",
            /* does not work with selections implemented - need to go lower level */
            /*recognizer: TapGestureRecognizer()
              ..onTap = () {
                url_launcher.launch(words[i]);
              },*/
            style: TextStyle(color: Colors.blue),
          )
      );
    } else {
      spans.add(
          TextSpan(
            text: "${words[i]}$pad",
            style: TextStyle(color: Colors.black),
          )
      );
    }
  }
  return spans;
}

class Note {
  final List note;
  final String note_flat;
  final String id;
  Note._({
    this.note,
    this.note_flat,
    this.id,
  });
  factory Note.fromJson(Map<String, dynamic> json) {

    return Note._(
      note: _getSpans(json['note']),
      note_flat: json['note'],
      id: json['id'],
    );
  }
}

/*_getApps() async {
  // org.mozilla.klar
  // com.opera.browser
  // com.android.chrome
  List<Application> apps = await DeviceApps.getInstalledApplications();
  for(var i = 0; i < apps.length; i++) {
    print(apps[i]);
  }
}*/

void openApp(i) {
  // todo: throws exception
  // Failed to handle method call .. java.lang.IllegalStateException: Reply already submitted
  DeviceApps.openApp(apps[i].packageName);
}

class App {
  const App({
    this.name,
    this.packageName
  });
  final String name;
  final String packageName;
}

const List<App> apps = const <App>[
  const App(name: 'Klar', packageName: 'org.mozilla.klar'),
  const App(name: 'Chrome', packageName: 'com.android.chrome'),
  const App(name: 'Opera', packageName: 'com.opera.browser'),
];

class Choice {
  const Choice({
    this.enabled,
    this.title
  });
  final bool enabled;
  final String title;
}

const List<Choice> choices = const <Choice>[
  const Choice(enabled: true, title: 'List'),
  const Choice(enabled: true, title: 'Add Note'),
  const Choice(enabled: true, title: 'Open Klar'),
  const Choice(enabled: true, title: 'Open Chrome'),
  const Choice(enabled: false, title: 'Open Opera'),
  const Choice(enabled: true, title: 'Settings'),
  const Choice(enabled: true, title: 'Exit'),
];

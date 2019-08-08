import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart'; // used for Exit
import 'package:ItFollows/library.dart';
import 'package:ItFollows/add.dart';
import 'package:ItFollows/settings.dart';

class ListNotes extends StatefulWidget {
  @override
  _ListNotesState createState() => _ListNotesState();
}

class _ListNotesState extends State<ListNotes> {
  List<Note> list = List();
  bool _isLoading = false;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  static const platform = const MethodChannel('app.channel.shared.data');

  List<Choice> _choices = choices.where(
          (i) => i.enabled && !i.title.startsWith("List")
  ).toList();

  Future navigateToAddNote(context) async {
    bool _upd = await Navigator.push(context, MaterialPageRoute(builder: (context) => AddNote()));
    if (_upd) _fetchData();
  }

  Future navigateToSettings(context) async {
    bool _upd = await Navigator.push(context, MaterialPageRoute(builder: (context) => Settings()));
    if (_upd) _fetchData();
  }

  void _select(Choice choice) { // todo: move to lib
    setState(() {
      switch(choice.title) {
        case 'Exit':
          SystemChannels.platform.invokeMethod('SystemNavigator.pop');
          break;
        case 'Add Note':
          navigateToAddNote(context);
          break;
        case 'Settings':
          navigateToSettings(context);
          break;
        case 'Open Klar':
          openApp(0);
          break;
        case 'Open Chrome':
          openApp(1);
          break;
        case 'Open Opera':
          openApp(2);
          break;
      }
    });
  }

  Future _fetchData() async {
    String failNotice = 'Failed to fetch data';
    setState(() {
      _isLoading = true;
    });
    final response = await http.get(Conf.urlGet).timeout(
      Duration(seconds: 3),
      onTimeout: () {
        failNotice = 'Failed to fetch data (offline)';
      },
    ).catchError((err) { return null; });
    if (response == null || response.statusCode != 200) {
      final notes = await readNotes();
      if (notes != '[]') {
        list = (json.decode(notes) as List)
            .map((data) => Note.fromJson(data))
            .toList();
        setState(() {
          _isLoading = false;
          final snackBar = SnackBar(content: Text('Showing backup (offline)'));
          _scaffoldKey.currentState.showSnackBar(snackBar);
        });
        return;
      }
      setState(() {
        _isLoading = false;
        final snackBar = SnackBar(content: Text(failNotice));
        _scaffoldKey.currentState.showSnackBar(snackBar);
      });
    } else {
      if (generateMd5(await readNotes()) != generateMd5(response.body))
        writeNotes(response.body);
      list = (json.decode(response.body) as List)
          .map((data) => Note.fromJson(data))
          .toList();
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void initState() {
    getConf();
    _onStartup().then((value){
      _fetchData();
    });
    super.initState();
    _init();
  }

  _init() async {
    // Check incoming share intent:
    // Case 1: App is already running in background:
    SystemChannels.lifecycle.setMessageHandler((msg) {
      if (msg.contains('resumed')) {
        _getSharedText().then((d) {
          if (d == null || d.isEmpty) return;
          navigateToAddNote(context);
        });
      }
    });
    // Case 2: App is started by the intent:
    await _getSharedText().then((d) {
      if (d == null || d.isEmpty) return;
      navigateToAddNote(context);
    });
  }

  Future<String> _getSharedText() async {
    var d = await platform.invokeMethod("getSharedText");
    if (d != null) dataShared = d;
    return d;
  }

  void _onDelete(BinaryAction choice, String id){
    Navigator.pop(context);
    if (choice == BinaryAction.yes) {
      Map<String, String> body = {
        'delete': id,
        'api': '1',
      };
      _postData(body);
    }
  }

  Future _postData(body) async {
    String failNotice = 'Failed to delete note';
    Map<String, String> headers = {
      "Content-type": "application/x-www-form-urlencoded",
      "charset": "utf-8",
    };
    setState(() {
      _isLoading = true;
    });
    final response = await http.post(
        Conf.urlPost,
        headers: headers,
        body: body
    ).timeout(
      Duration(seconds: 3),
      onTimeout: () {
        failNotice = 'Failed to delete note (offline)';
      },
    ).catchError((err) { return null; });
    if (response == null || response.statusCode != 200) {
      setState(() {
        _isLoading = false;
        final snackBar = SnackBar(content: Text(failNotice));
        _scaffoldKey.currentState.showSnackBar(snackBar);
      });
    } else {
      setState(() {
        final snackBar = SnackBar(content: Text('Note deleted'));
        _scaffoldKey.currentState.showSnackBar(snackBar);
      });
      _fetchData();
    }
  }

  void _promptDelete(String note, String id) {
    note = note.length > 50 ? '${note.substring(0, 50)}..' : note;
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('Delete Note?'),
          content: Text(
            note,
            style: TextStyle(fontSize: 15.0),
          ),
          actions: <Widget>[
            FlatButton(
                color: Colors.red,
                textColor: Colors.white,
                splashColor: Colors.redAccent,
                onPressed: () {_onDelete(BinaryAction.yes, id);},
                  child: Text('yes')
            ),
            FlatButton(
                color: Colors.blue,
                textColor: Colors.white,
                splashColor: Colors.blueAccent,
                onPressed: () {_onDelete(BinaryAction.no, id);},
                child: Text('no')
            ),
          ],
        )
    );
  }

  Future _onStartup() async {
    await Future.delayed(Duration(seconds: 2));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: Text("It Follows"),
          actions: <Widget>[
            // overflow menu
            PopupMenuButton<Choice>(
              onSelected: _select,
              itemBuilder: (BuildContext context) {
                return _choices.map((Choice choice) {
                  return PopupMenuItem<Choice>(
                    value: choice,
                    child: Text(choice.title),
                  );
                }).toList();
              },
            ),
          ],
        ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.all(8.0),
          child: RaisedButton(
            child: Text("Refresh"),
            onPressed: _fetchData,
          ),
        ),
        body: _isLoading
            ? Center(
              child: CircularProgressIndicator(),
            )
            : Container(
              child: RefreshIndicator(
                onRefresh: _fetchData,
                child: ListView.builder(
                  itemCount: list.length,
                  itemBuilder: (BuildContext context, int index) {
                    return Card(child: ListTile(
                      contentPadding: EdgeInsets.all(10.0),
                      title: Align(
                        alignment: Alignment.centerLeft,
                        child: SelectableText.rich(
                          TextSpan(
                            children: list[index].note,
                          ),
                        ),
                      ),
                      trailing: IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () {
                            _promptDelete(list[index].note_flat, list[index].id);
                          }
                      )
                    ));
                  }
                 ),
              ),
            ),
    );
  }
}
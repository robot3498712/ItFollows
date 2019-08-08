import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart'; // used for Exit
import 'package:ItFollows/library.dart';
import 'package:ItFollows/settings.dart';

class AddNote extends StatefulWidget {
  @override
  _AddNoteState createState() => _AddNoteState();
}

class _AddNoteState extends State<AddNote> {
  bool _isLoading = false;
  bool _validate = false;
  bool _isInit = true;
  final _noteController = TextEditingController();
  FocusNode _noteField = FocusNode();
  FocusNode _saveBtn = FocusNode();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _returnMsg = false; // true if change (= note saved)

  List<Choice> _choices = choices.where(
          (i) => i.enabled && !i.title.startsWith("Add")
  ).toList();

  @override
  void initState() {
    if (dataShared != "") {
      _onStartupDelay().then((value) { _promptSharedNote(); });
    }
    super.initState();
    _noteField.addListener(_onFocusChange);
    _saveBtn.addListener(_onFocusChange);
  }

  Future _onStartupDelay() async {
    await Future.delayed(Duration(seconds: 1));
  }

  void _onSharedNote(BinaryAction choice) {
    Navigator.pop(context);
    if (choice == BinaryAction.yes) {
      Map<String, String> body = {
        'save': '1',
        'api': '1',
        'text': dataShared,
      };
      _postData(body);
    }
    dataShared = "";
  }

  void _promptSharedNote() {
    var note = dataShared.length > 50 ? '${dataShared.substring(0, 50)}..' : dataShared;
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('Add shared Note?'),
          content: Text(
            note,
            style: TextStyle(fontSize: 15.0),
          ),
          actions: <Widget>[
            FlatButton(
                color: Colors.red,
                textColor: Colors.white,
                splashColor: Colors.redAccent,
                onPressed: () {_onSharedNote(BinaryAction.yes);},
                child: Text('yes')
            ),
            FlatButton(
                color: Colors.blue,
                textColor: Colors.white,
                splashColor: Colors.blueAccent,
                onPressed: () {_onSharedNote(BinaryAction.no);},
                child: Text('no')
            ),
          ],
        )
    );
  }

  Future navigateToSettings(context) async {
    bool _upd = await Navigator.push(context, MaterialPageRoute(builder: (context) => Settings()));
  }

  void _select(Choice choice) { // todo: move to lib
    setState(() {
      switch(choice.title) {
        case 'Exit':
          SystemChannels.platform.invokeMethod('SystemNavigator.pop');
          break;
        case 'List':
          Navigator.pop(context, _returnMsg);
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

  _postData(body) async {
    String failNotice = 'Failed to post note';
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
        failNotice = 'Failed to post note (offline)';
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
        _noteController.text = '';
        _setReturnMsg(true);
        _isLoading = false;
        final snackBar = SnackBar(content: Text('Note saved'));
        _scaffoldKey.currentState.showSnackBar(snackBar);
      });
    }
  }

  void _setReturnMsg(b) {
    if (!_returnMsg) _returnMsg = b;
  }

  void _sendNote() {
    String note = _noteController.text;
    Map<String, String> body = {
    'save': '1',
    'api': '1',
    'text': note,
    };
    _postData(body);
  }

  void _onFocusChange(){ // todo: review
    if (_noteField.hasFocus || _saveBtn.hasFocus) {
      setState(() {
        _validate = true; // hide errorText
      });
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          leading: IconButton( /* override back-button to provide return msg */
            icon:Icon(Icons.chevron_left),
            onPressed:() => Navigator.pop(context, _returnMsg),
          ),
          title: Text("Add Note"),
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
            focusNode: _saveBtn,
            child: Text("Save"),
            onPressed: () {
              setState(() {
                _isInit = false;
                _noteController.text.isEmpty ? _validate = false : _validate = true;
              });
              if (_validate) _sendNote();
            },
          ),
        ),
        body: _isLoading
            ? Center(
          child: CircularProgressIndicator(),
        )
            : GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                FocusScope.of(context).requestFocus(FocusNode());
              },
              child: Card(child: Column(children: <Widget>[
                TextFormField(
                  controller: _noteController,
                  focusNode: _noteField,
                  autofocus: false, /* true interferes with <paste> */
                  enableInteractiveSelection: true,
                  textAlign: TextAlign.left,
                  decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Enter note',
                      errorText: _validate || _isInit ? null : 'Can\'t Be Empty',
                      contentPadding: const EdgeInsets.all(20.0),
                  ),
                ),
              ]
            ),)
          )
    );
  }
}
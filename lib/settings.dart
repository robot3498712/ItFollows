import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // used for Exit
import 'package:ItFollows/library.dart';

class Settings extends StatefulWidget {
  @override
  _SettingsState createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _returnMsg = false; // true if change (= settings saved), todo: implement
  FocusNode _saveBtn = FocusNode();
  final _settingsGetController = TextEditingController();
  FocusNode _settingsGetField = FocusNode();
  final _settingsPostController = TextEditingController();
  FocusNode _settingsPostField = FocusNode();

  List<Choice> _choices = choices.where(
          (i) => i.enabled && i.title.startsWith("Exit")
  ).toList();

  void _select(Choice choice) { // todo: move to lib
    setState(() {
      switch(choice.title) {
        case 'Exit':
          SystemChannels.platform.invokeMethod('SystemNavigator.pop');
          break;
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _settingsGetController.text = Conf.urlGet.isEmpty ? '' : Conf.urlGet;
    _settingsPostController.text = Conf.urlPost.isEmpty ? '' : Conf.urlPost;
  }

  @override
  void dispose() {
    _settingsGetController.dispose();
    _settingsPostController.dispose();
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
        title: Text("Settings"),
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
            _saveSettings();
          },
        ),
      ),
      body:
        Card(child: Column(children: <Widget>[
          Container(
            height: 75,
            color: Colors.white,
            child: TextFormField(
              controller: _settingsGetController,
              focusNode: _settingsGetField,
              autofocus: false,
              enableInteractiveSelection: true,
              textAlign: TextAlign.left,
              decoration: InputDecoration(
                border: InputBorder.none,
                labelText: 'API URL (GET):',
                hintText: 'Enter URL like https://<path to>/<notes>.json',
                contentPadding: const EdgeInsets.all(20.0),
              ),
            ),
          ),
          Container(
              height: 75,
              color: Colors.white,
              child: TextFormField(
                controller: _settingsPostController,
                focusNode: _settingsPostField,
                autofocus: false,
                enableInteractiveSelection: true,
                textAlign: TextAlign.left,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  labelText: 'API URL (POST):',
                  hintText: 'Enter URL like https://<path>/',
                  contentPadding: const EdgeInsets.all(20.0),
                ),
              ),
          ),
          Container(
            height: 150,
            padding: EdgeInsets.only(left: 20.0, right: 0, top: 100, bottom: 15.0),
            alignment: Alignment.centerLeft,
            color: Colors.white,
            child: Padding(
              padding: EdgeInsets.all(0),
              child: FlatButton(
                color: Colors.grey,
                textColor: Colors.white,
                splashColor: Colors.blueGrey,
                onPressed: () { _onDlgAbout(); },
                child: Text('About')
              ),
            ),
          ),
        ]
        ),),
    );
  }

  void _onDlgAbout() {
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('It Follows: Sync Notes by robot'),
          content: Text(
            "License: GNU General Public\r\n\r\nBuilt with flutter in 2019. You should find a copy on github.",
            style: TextStyle(fontSize: 15.0),
          ),
          actions: <Widget>[
            FlatButton(
                color: Colors.grey,
                textColor: Colors.white,
                splashColor: Colors.blueGrey,
                onPressed: () { Navigator.pop(context); },
                child: Text('close')
            ),
          ],
        )
    );
  }

  void _saveSettings() {
    setConf(_settingsGetController.text, _settingsPostController.text);
    setState(() {
      final snackBar = SnackBar(content: Text('Settings saved'));
      _scaffoldKey.currentState.showSnackBar(snackBar);
    });
  }

}
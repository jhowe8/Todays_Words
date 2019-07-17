import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:translator/translator.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'auth.dart';

class VocabPage extends StatefulWidget {
  final String page;
  final String userEmail;
  final String userID;

  final BaseAuth auth;
  final VoidCallback onSignedOut;

  VocabPage(this.page, this.userEmail, this.userID, this.auth, this.onSignedOut);

  @override
  VocabPageState createState() {
    return VocabPageState();
  }
}

class VocabPageState extends State<VocabPage> {
  String id;
  final db = Firestore.instance;
  final _formKey = GlobalKey<FormState>();
  String vocab;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.page),
      ),
      body: ListView(
        padding: EdgeInsets.all(8),
        children: <Widget>[
          // Stream of vocab words
          StreamBuilder<QuerySnapshot>(
            stream: db.collection('users').document(widget.userID)
                .collection('pages').document(widget.page)
                .collection('vocab').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return Column(children: snapshot.data.documents.map((doc) => buildVocabItem(doc)).toList());
              } else {
                return SizedBox();
              }
            },
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        child: Container(
          color: Colors.green[800],
          height: 60,
          child: Column(
            children: <Widget>[
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  InkWell(
                    onTap: addVocabButtonTapped,
                    child: Column(
                      children: <Widget> [
                        Icon(Icons.library_add),
                        Text('Add Vocab')
                      ]
                    ),
                  ),
                  InkWell(
                    onTap: _signOut,
                    child: Column(
                      children: <Widget> [
                        Icon(Icons.exit_to_app),
                        Text('Sign Out')
                      ]
                    )
                  )
                ]
              )
            ]
          )
        )
      ),
    );
  }

  void addVocabButtonTapped() {
    AlertDialog dialog = new AlertDialog(
      content: new Container(
        height: 180,
        width: 100,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            new Text('Enter Chinese:'),
            Form(
              key: _formKey,
              child: buildTextFormField(),
            ),
            new Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget> [
                new FlatButton(
                    child: new Text('Add', style: TextStyle(color: Colors.white)),
                    color: Colors.green[300],
                    onPressed: addVocab
                ),
                new FlatButton(
                  child: new Text('Cancel', style: TextStyle(color: Colors.white)),
                  color: Colors.redAccent,
                  onPressed: () {
                    Navigator.pop(context);
                  },
                )
              ]
            )
          ],
        )
      )
    );

    showDialog(context: context, builder: (BuildContext context) => dialog);
  }


  TextFormField buildTextFormField() {
    return TextFormField(
      decoration: InputDecoration(
        border: InputBorder.none,
        hintText: 'enter vocabulary',
        fillColor: Colors.black,
        filled: true,
      ),
      validator: (value) {
        if (value.isEmpty) {
          return 'Please enter some text';
        }
      },
      onSaved: (value) => vocab = value,
    );
  }

  Card buildVocabItem(DocumentSnapshot doc) {
    return Card(
      elevation: 8,
      child: Container(
        decoration: BoxDecoration(color: Color.fromRGBO(129, 195, 199, .25)),
        child: Padding(
          padding: const EdgeInsets.all(6.0),
          child: Row(
            children: <Widget>[
              Container(
                height: 60,
                width: MediaQuery.of(context).size.width * 0.25,
                child: AutoSizeText(
                  '${doc.data['en']}', style: TextStyle(fontSize: 12),
                  minFontSize: 6,
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis
                ),
              ),
              Container(
                height: 60.0,
                child: VerticalDivider(
                  color: Colors.green[300],
                )
              ),
              Container(
                height: 60,
                width: MediaQuery.of(context).size.width * 0.25,
                child: AutoSizeText(
                  '${doc.data['py']}', style: TextStyle(fontSize: 12),
                    minFontSize: 8,
                    maxLines: 5,
                    overflow: TextOverflow.ellipsis
                ),
              ),
              Container(
                  height: 60,
                  child: VerticalDivider(
                    color: Colors.green[300],
                  )
              ),
              Container(
                  height: 60,
                  width: MediaQuery.of(context).size.width * 0.15,
                  child: AutoSizeText(
                    '${doc.data['ch']}', style: TextStyle(fontSize: 12),
                      minFontSize: 8,
                      maxLines: 5,
                      overflow: TextOverflow.ellipsis
                  )
              ),
              Container(
                  height: 60,
                  child: VerticalDivider(
                    color: Colors.green[300],
                  )
              ),
              Container(
                height: 60,
                width: MediaQuery.of(context).size.width * 0.07,
                child: IconButton(
                  icon: new Icon(Icons.remove_circle_outline, color: Colors.red[300], size: 20),
                  onPressed: () => deleteVocab(doc),
                ),
              ),
            ],
          ),
        )
      )
    );
  }

  void _signOut() async {
    try {
      await widget.auth.signOut();
      widget.onSignedOut();
      Navigator.pop(context);
    } catch (e) {
      print(e);
    }
  }

  void addVocab() async {
    Navigator.pop(context);
    String py;
    String en;

    if (_formKey.currentState.validate()) {
      _formKey.currentState.save();

      /*
      // GET PINYIN FROM GLOSBE.COM
      // may receive too many requests. github is more reliable
      String pinyinAPIcall = 'https://glosbe.com/transliteration/api?from=Han&dest=Latin&text=$vocab&format=json';
      final pyResponse = await http.get(pinyinAPIcall);
      if (pyResponse.statusCode == 200) {
        print(json.decode(pyResponse.body)['text']);
      }
      */

      // GET PINYIN FROM https://github.com/lucwastiaux/python-pinyin-jyutping-sentence
      String url = "http://api.mandarincantonese.com/pinyin/$vocab";
      final pyResponse = await http.get(url);
      if (pyResponse.statusCode == 200) {
        py = json.decode(pyResponse.body)['pinyin'];
      }

      final translator = new GoogleTranslator();
      en = await translator.translate(vocab, from: 'zh-cn', to: 'en');

      DocumentReference ref = await db.collection('users').document(widget.userID)
          .collection('pages').document(widget.page)
          .collection('vocab').add({'ch': vocab, 'en': en, 'py': py});

      setState(() => id = ref.documentID);
    }

    _formKey.currentState.reset();
  }

  deleteVocab(DocumentSnapshot doc) async {
    print('delete');
    await db.collection('users').document(widget.userID)
        .collection('pages').document(widget.page)
        .collection('vocab').document(doc.documentID).delete();
    setState(() => id = null);
  }
}
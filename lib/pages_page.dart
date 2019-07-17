import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'vocab_page.dart';
import 'auth.dart';

class PagesPage extends StatefulWidget {
  final BaseAuth auth;
  final VoidCallback onSignedOut;

  PagesPage({this.auth, this.onSignedOut});

  @override
  PagesPageState createState() => PagesPageState();
}

class PagesPageState extends State<PagesPage> {
  final db = Firestore.instance;
  final _formKey = GlobalKey<FormState>();
  String page;
  String id;
  String userID;
  String userEmail;

  @override
  void initState() {
    super.initState();
    // check status of current user when app is turned on
    widget.auth.currentUser().then((_userID) {
      setState(() {
        userID = _userID;
      });
    });
    widget.auth.currentUserEmail().then((_userEmail) {
      setState(() {
        userEmail = _userEmail;
        // add user to database if necessary
        var data = {'user': userEmail};
        CollectionReference ref = db.collection('users');
        ref.document(userID).setData(data);
      });
    });
  }

  double getExpirationOpacity(int expiration) {
    return (0.4 + ((7 - expiration) * 0.1));
  }

  Card buildPageItem(DocumentSnapshot doc) {
    return Card(
      elevation: 8,
      margin: new EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
      child: Container(
        decoration: BoxDecoration(color: Color.fromRGBO(129, 195, 199, .25)),
        child: ListTile(
          contentPadding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          leading: Container(
            padding: EdgeInsets.only(right: 12.0),
            decoration: new BoxDecoration(
                border: new Border(
                    right: new BorderSide(width: 1.0, color: Colors.white24))),
            child: Icon(Icons.insert_drive_file, color: Colors.white)
            ),
          title: Text(doc.data['pagename'], style: TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('Expires in ${doc.data['expiration']} day(s)', style: TextStyle(color: Colors.red.withOpacity(getExpirationOpacity(doc.data['expiration'])))),
          trailing:
            IconButton(
              icon: new Icon(Icons.keyboard_arrow_right, color: Colors.white, size: 30.0),
              onPressed: () {
                setState(() {});
                print(doc.data['pagename']);
                Navigator.push(context, MaterialPageRoute(
                    builder: (context) => VocabPage(doc.data['pagename'], userEmail, userID, widget.auth, widget.onSignedOut)),
                );
              },
            ),
        )
      )
    );
  }

  TextFormField buildTextFormField() {
    return TextFormField(
      decoration: InputDecoration(
        border: InputBorder.none,
        hintText: 'page name',
        fillColor: Colors.grey,
        filled: true,
      ),
      validator: (value) {
        if (value.isEmpty) {
          return 'Please enter some text';
        } else if (value.length > 13) {
          return 'Page name must be less than 14 characters';
        }
      },
      onSaved: (value) => page = value,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pages')
      ),
      body: ListView(
        padding: EdgeInsets.all(8),
        children: <Widget>[
          StreamBuilder<QuerySnapshot>(
            stream: db.collection('users').document(userID)
                .collection('pages').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return Column(children: snapshot.data.documents.map((doc) => buildPageItem(doc)).toList());
              } else {
                return SizedBox();
              }
            },
          )
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
                    onTap: addPageButtonTapped,
                    child: Column(
                      children: <Widget> [
                        Icon(Icons.library_add),
                        Text('Add Page')
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

  // Bottom nav bar clicked
  void addPageButtonTapped() {
    AlertDialog dialog = new AlertDialog(
      content: Form(
        key: _formKey,
        child: buildTextFormField(),
      ),
      actions: <Widget>[
        new FlatButton(
          child: new Text('Add', style: TextStyle(color: Colors.white)),
          color: Colors.green[300],
          onPressed: addPage
        ),
        new FlatButton(
          child: new Text('Cancel', style: TextStyle(color: Colors.white)),
          color: Colors.redAccent,
          onPressed: () {
            Navigator.pop(context);
          },
        )
      ],
    );

    showDialog(context: context, builder: (BuildContext context) => dialog);
  }

  void _signOut() async {
    try {
      await widget.auth.signOut();
      widget.onSignedOut();
    } catch (e) {
      print(e);
    }
  }

  void addPage() async {
    if (_formKey.currentState.validate()) {
      Navigator.pop(context);
      _formKey.currentState.save();

      print(page);
      var data = {'pagename': page, 'expiration': 7, 'created': FieldValue.serverTimestamp()};

      CollectionReference ref = db.collection('users').document(userID)
          .collection('pages');

      await ref.document(page).setData(data);

      setState(() => id = page);
    }
    _formKey.currentState.reset();
  }

  deletePage(DocumentSnapshot doc) async {
    await db.collection('users').document(userID)
        .collection('pages').document(doc.documentID).delete();
    setState(() => id = null);
  }
}
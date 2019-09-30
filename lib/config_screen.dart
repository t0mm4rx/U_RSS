import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:progress_dialog/progress_dialog.dart';
import 'streams_manager.dart';

class ConfigScreen extends StatelessWidget {
  @override
  Widget build(BuildContext) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.black,
          bottom: TabBar(
            tabs: [
              Tab(icon: Icon(Icons.add)),
              Tab(icon: Icon(Icons.list)),
            ],
          ),
          title: Text('Settings'),
          centerTitle: true,
        ),
        body: TabBarView(
          children: [
            AddStreamScreen(),
            Container(child: ListStreamsScreen()),
          ],
        ),
      ),
    );
  }
}

class AddStreamScreen extends StatelessWidget {
  final TextEditingController text_controller = new TextEditingController();

  void add_source(BuildContext context) async {
    if (text_controller.text == '') return;
    ProgressDialog pr = new ProgressDialog(context);
    pr.style(
      message: "Adding the new source...",
      progressWidget: Container(
          padding: EdgeInsets.all(8.0), child: CircularProgressIndicator()),
      progressTextStyle: TextStyle(
          color: Colors.black, fontSize: 13.0, fontWeight: FontWeight.w400),
      messageTextStyle: TextStyle(
          color: Colors.black, fontSize: 15.0, fontWeight: FontWeight.w600),
    );
    pr.show();
    await add_stream(text_controller.text);
    text_controller.text = "";
    pr.hide();
  }

  @override
  Widget build(BuildContext context) {
    Clipboard.getData('text/plain').then((data) {
      if (data.text != '') {
        text_controller.text = data.text;
      }
    });
    return Container(
        child: Padding(
            padding: EdgeInsets.all(10),
            child: Column(
              children: <Widget>[
                TextFormField(
                  controller: text_controller,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Paste RSS stream URL',
                    suffixIcon: IconButton(
                        icon: Icon(Icons.clear),
                        onPressed: () {
                          text_controller.text = "";
                        }),
                  ),
                ),
                FlatButton(
                  onPressed: () {
                    add_source(context);
                  },
                  child:
                      Text("Add source", style: TextStyle(color: Colors.white)),
                  color: Colors.teal,
                )
              ],
            )));
  }
}

class ListStreamsScreen extends StatefulWidget {
  @override
  State<ListStreamsScreen> createState() => ListStreamsState();
}

class ListStreamsState extends State<ListStreamsScreen> {
  List<Map> streams = [];

  @override
  void initState() {
    get_streams().then((streams) {
      setState(() {
        this.streams = streams;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: this
          .streams
          .map((stream) => StreamItemWidget(stream: stream, list: this))
          .toList(),
    );
  }
}

class StreamItemWidget extends StatelessWidget {
  Map stream;
  State list;

  StreamItemWidget({this.stream, this.list});

  void deleteItem(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: new Text("Remove a source"),
          content: new Text(
              'Are you sure you want to remove ${this.stream["name"]} from your feed ?'),
          actions: <Widget>[
            new FlatButton(
              child: new Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            new FlatButton(
              child: new Text("Delete", style: TextStyle(color: Colors.red)),
              onPressed: () async {
                await remove_stream(this.stream);
                this.list.initState();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Row(
        children: <Widget>[
          Expanded(
              flex: 1,
              child: Padding(
                  padding: EdgeInsets.all(10),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(this.stream["name"],
                            textAlign: TextAlign.left,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            )),
                        Text(this.stream["url"], textAlign: TextAlign.left),
                      ]))),
          IconButton(
            icon: Icon(Icons.clear),
            color: Colors.black,
            onPressed: () {
              deleteItem(context);
            },
          ),
        ],
      ),
    );
  }
}

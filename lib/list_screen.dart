import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'config_screen.dart';
import 'streams_manager.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:progress_dialog/progress_dialog.dart';

State<NewsListWidget> news_list = NewsListState();

class ListScreen extends StatefulWidget {
  @override
  State<ListScreen> createState() => ListScreenState();
}

class ListScreenState extends State<ListScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("News"),
        centerTitle: true,
        backgroundColor: Colors.black,
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => ConfigScreen()));
            },
          ),
        ],
      ),
      body: Column(
        children: <Widget>[NewsListWidget()],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: news_list.initState,
        child: Icon(Icons.refresh),
        backgroundColor: Colors.teal,
      ),
    );
  }
}

class NewsListWidget extends StatefulWidget {
  @override
  State<NewsListWidget> createState() => news_list;
}

class NewsListState extends State<NewsListWidget> {
  List<Map> feed = [];

  @override
  void initState() {
    get_feed().then((List<Map> res) {
      setState(() {
        this.feed = res;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Flexible(
        child: ListView(
      children: this.feed.map((el) => NewsItemWidget(news: el)).toList(),
    ));
  }
}

class NewsItemWidget extends StatelessWidget {
  Map news;
  TextStyle style_title = TextStyle(
    color: Colors.black,
    fontWeight: FontWeight.bold,
    fontSize: 18,
  );
  TextStyle style_description = TextStyle(
    color: Colors.black,
    fontSize: 14,
  );
  TextStyle style_date = TextStyle(
    fontSize: 12,
  );
  NewsItemWidget({this.news});

  @override
  Widget build(BuildContext) {
    return InkWell(
        onTap: open_url,
        child: Card(
            elevation: 30,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
            color: Colors.white,
            margin: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Column(children: <Widget>[
              if (this.news['image'] != '')
                new ClipRRect(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(8.0)),
                    child: CachedNetworkImage(
                      placeholder: (context, url) => Padding(
                          child: CircularProgressIndicator(),
                          padding: EdgeInsets.all(20)),
                      imageUrl: this.news['image'],
                    )),
              Padding(
                  padding: EdgeInsets.all(15),
                  child: Column(
                    children: <Widget>[
                      Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Expanded(
                                child: Text(
                              this.news['source'],
                              style: this.style_date,
                              textAlign: TextAlign.left,
                            )),
                            Text(
                              format_date(this.news['date']),
                              style: this.style_date,
                              textAlign: TextAlign.left,
                            ),
                          ]),
                      SizedBox(height: 10),
                      Text(
                        this.news['title'],
                        style: this.style_title,
                        textAlign: TextAlign.left,
                      ),
                      Text(
                        this.news['description'],
                        style: this.style_description,
                        textAlign: TextAlign.left,
                      ),
                    ],
                  )),
            ])));
  }

  String format_date(String date) {
    if (date == '') return '';
    var d = DateTime.parse(date);
    return str_to_int(d.day) +
        '/' +
        str_to_int(d.month) +
        ' ' +
        str_to_int(d.hour) +
        ':' +
        str_to_int(d.minute);
  }

  String str_to_int(int i) {
    if (i < 10) return '0' + i.toString();
    return i.toString();
  }

  void open_url() async {
    if (await canLaunch(this.news['link'])) {
      await launch(this.news['link'], forceWebView: true);
    } else {
      throw 'Could not launch ${this.news["link"]}';
    }
  }
}

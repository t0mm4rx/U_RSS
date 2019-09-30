import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart';
import 'package:xml/xml.dart';
import 'dart:convert';

final Uuid uuid = new Uuid();

void add_stream(String url) async {
  String name = "Unknown";
  var rep = await get(url);
  var obj = parse(rep.body);
  name = obj.findAllElements("title").toList()[0].text;
  Map stream = {
    'name': name,
    'url': url,
    'id': uuid.v4(),
    'content': '',
    'last_update': 0,
  };
  List<Map> streams = await get_streams();
  for (int i = 0; i < streams.length; i++) {
    if (streams[i]['url'] == url) {
      print('Stream already added ! : ${url}');
      return;
    }
  }
  streams.add(stream);
  await save_streams(streams);
  await update_streams();
  print('New steam saved in shared preferences : ${name}');
}

void remove_stream(Map stream) async {
  List<Map> streams = await get_streams();
  for (int i = 0; i < streams.length; i++) {
    if (streams[i]["id"] == stream["id"]) streams.removeAt(i);
  }
  print(streams.length);
  await save_streams(streams);
  print('A stream has been deleted : ${stream["name"]}');
}

Future<List<Map>> get_streams() async {
  final prefs = await SharedPreferences.getInstance();
  List<String> streams = (prefs.getStringList('streams') ?? List<String>());
  List<Map> streams_json = streams.map((el) => string_to_stream(el)).toList();
  return streams_json;
}

void save_streams(List<Map> streams) async {
  final prefs = await SharedPreferences.getInstance();
  List<String> streams_text = streams.map((el) => jsonEncode(el)).toList();
  prefs.setStringList('streams', streams_text);
}

void clear_streams() async {
  await save_streams([]);
  print("Streams cleared");
}

Future<List<Map>> get_stream(Map stream) async {
  var rep = await get(stream['url']);
  // Error managment
  var obj = parse(rep.body);
  List<Map> res = [];
  obj
      .findAllElements("item")
      .toList()
      .forEach((el) => res.add(item_to_json(el)));
  return res;
}

void update_streams() async {
  print("Updating streams...");
  List<Map> streams = await get_streams();
  for (int i = 0; i < streams.length; i++) {
    if (DateTime.now().millisecondsSinceEpoch - streams[i]['last_update'] >
        1000 * 60 * 10) {
      streams[i]['content'] = await get_stream(streams[i]);
      streams[i]['last_update'] = DateTime.now().millisecondsSinceEpoch;
    }
  }
  await save_streams(streams);
}

Future<List<Map>> get_feed() async {
  List<Map> feed = [];
  List<Map> streams = await get_streams();
  streams.forEach((stream) {
    stream["content"].forEach((news) {
      news["source"] = stream["name"];
      news["date"] = format_date(news["date"]);
      feed.add(news);
    });
  });
  return sort_feed(feed);
}

List<Map> sort_feed(List<Map> feed) {
  feed.sort((a, b) => DateTime.parse(b["date"])
      .difference(DateTime.parse(a["date"]))
      .inSeconds);
  return feed;
}

String str_to_int(int i) {
  if (i < 10) return '0' + i.toString();
  return i.toString();
}

String format_date(String date) {
  if (date == '') {
    var now = DateTime.now();
    now = now.subtract(Duration(days: 1));
    return str_to_int(now.year) +
        '-' +
        str_to_int(now.month) +
        '-' +
        str_to_int(now.day) +
        ' ' +
        str_to_int(now.hour) +
        ':' +
        str_to_int(now.minute) +
        ':' +
        str_to_int(now.second);
  }
  date = date.replaceAll('Jan', '01');
  date = date.replaceAll('Feb', '02');
  date = date.replaceAll('Mar', '03');
  date = date.replaceAll('Apr', '04');
  date = date.replaceAll('May', '05');
  date = date.replaceAll('Jun', '06');
  date = date.replaceAll('Jul', '07');
  date = date.replaceAll('Aug', '08');
  date = date.replaceAll('Sep', '09');
  date = date.replaceAll('Oct', '10');
  date = date.replaceAll('Nov', '11');
  date = date.replaceAll('Dec', '12');
  date = date.replaceAll('GMT', '');
  date = date.split(', ')[1];
  List<String> splits = date.split(' ');
  date = splits[2] +
      '-' +
      splits[1] +
      '-' +
      splits[0] +
      ' ' +
      splits[3] +
      splits[4];
  return date;
}

Map string_to_stream(String json) {
  return jsonDecode(json);
}

Map item_to_json(dynamic xml_item) {
  String image_url = "";
  var enclosure = xml_item.findElements("enclosure").toList();
  if (enclosure.length > 0) {
    for (int i = 0; i < enclosure[0].attributes.length; i++) {
      if (enclosure[0].attributes[i].name.toString() == "url")
        image_url = enclosure[0].attributes[i].value;
    }
  }
  String date = "";
  String description = "";
  String title = "";
  String link = "";
  if (xml_item.findElements("pubDate").toList().length > 0)
    date = remove_html(xml_item.findElements("pubDate").single.text);
  if (xml_item.findElements("description").toList().length > 0)
    description = remove_html(xml_item.findElements("description").single.text);
  if (xml_item.findElements("title").toList().length > 0)
    title = remove_html(xml_item.findElements("title").single.text);
  if (xml_item.findElements("link").toList().length > 0)
    link = remove_html(xml_item.findElements("link").single.text);
  return {
    'title': title,
    'description': description,
    'date': date,
    'link': link,
    'image': image_url,
  };
}

String remove_html(String htmlText) {
  RegExp exp = RegExp(r"<[^>]*>", multiLine: true, caseSensitive: true);

  return htmlText.replaceAll(exp, '');
}

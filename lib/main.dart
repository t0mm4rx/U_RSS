import 'package:flutter/material.dart';
import 'list_screen.dart';
import 'streams_manager.dart';

void main() async {
  await add_stream('https://www.journaldunet.com/rss/');
  await add_stream('https://www.lemonde.fr/pixels/rss_full.xml');
  await add_stream(
      'https://www.01net.com/rss/info/flux-rss/flux-toutes-les-actualites/');
  await update_streams();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'U_RSS',
      home: ListScreen(),
    );
  }
}

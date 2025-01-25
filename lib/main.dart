import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

void main() {
  runApp(DictionaryApp());
}

class DictionaryApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'دیکشنری ویرا',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          fontFamily: 'iranyekan',
        ),
        home: Directionality(
          textDirection: TextDirection.rtl, // Set the text direction to RTL
          child: DictionaryHomePage(),
        ));
  }
}

class DictionaryHomePage extends StatefulWidget {
  @override
  _DictionaryHomePageState createState() => _DictionaryHomePageState();
}

class _DictionaryHomePageState extends State<DictionaryHomePage> {
  Database? _database;
  final TextEditingController _controller = TextEditingController();
  String _searchWord = '';
  List<String> _definition = [];

  @override
  void initState() {
    super.initState();
    _initializeDatabase();
  }

  Future<void> _initializeDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'dictionary.db');

    // Check if the database file exists
    final file = File(path);
    if (!await file.exists()) {
      // Copy database from assets to the device
      final byteData = await rootBundle.load('assets/dictionary.db');
      final buffer = byteData.buffer;
      await file.writeAsBytes(
          buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
    }

    // Open the database
    _database = await openDatabase(path);
    setState(() {});
  }

  Future<void> _searchDictionary() async {
    if (_database == null || _searchWord.isEmpty) return;
    if (_definition.isNotEmpty) {
      _definition.clear();
    }
    final List<Map<String, dynamic>> exactResults = await _database!
        .rawQuery('SELECT * FROM words WHERE en = ${_searchWord} GROUP BY en');
    setState(() {
      if (exactResults.isNotEmpty) {
        if (exactResults.length > 1) {
          _definition =
              exactResults.map((result) => result['fa'] as String).toList();
        } else {
          _definition.add(exactResults.first['fa'] ?? 'ترجمه پیدا نشد.');
        }
      } else {
        _definition.add('ترجمه پیدا نشد');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('دیکشنری ویرا', style: TextStyle(fontFamily: 'iranyekan')),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                  labelText: 'لغت انگلیسی را وارد کنید',
                  border: OutlineInputBorder(),
                  labelStyle: TextStyle(fontFamily: 'iranyekan')),
              onChanged: (value) {
                _searchWord = value;
              },
              textDirection: TextDirection
                  .ltr, // Keep input text direction LTR for English
              onSubmitted: (value) {
                _searchDictionary();
              },
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _searchDictionary,
              child: Text('نمایش ترجمه',
                  style: TextStyle(fontFamily: 'iranyekan')),
            ),
            SizedBox(height: 32),
            Text(
              'ترجمه:',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  fontFamily: 'iranyekan'),
            ),
            SizedBox(height: 8),
            if (_definition.isNotEmpty) ...[
              SizedBox(height: 8),
              ..._definition.map((translation) => Text(
                    translation,
                    style: TextStyle(fontSize: 16),
                    textDirection: TextDirection.rtl,
                  )),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _database?.close();
    super.dispose();
  }
}

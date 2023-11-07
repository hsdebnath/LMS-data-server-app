import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(LocalServerApp());
}

class LocalServerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: LocalServerScreen(),
    );
  }
}

class LocalServerScreen extends StatefulWidget {
  @override
  _LocalServerScreenState createState() => _LocalServerScreenState();
}

class _LocalServerScreenState extends State<LocalServerScreen> {
  HttpServer? _server;
  String _serverStatus = 'Server not running';

  @override
  void initState() {
    super.initState();
    _startLocalServer();
  }

  @override
  void dispose() {
    _stopLocalServer();
    super.dispose();
  }

  Future<void> _startLocalServer() async {
    try {
      _server = await HttpServer.bind('0.0.0.0', 8080);
      _serverStatus = 'Server running on ${_server!.address.host}:${_server!.port}';
      setState(() {});
      await for (var request in _server!.asBroadcastStream()) {
        if (request.uri.path == '/download') {
          final file = File('${(await getApplicationDocumentsDirectory()).path}/course_one.zip');
          if (await file.exists()) {
            request.response.headers.contentType = ContentType('application', 'zip');
            await request.response.addStream(file.openRead());
          } else {
            request.response.statusCode = HttpStatus.notFound;
            request.response.write(jsonEncode({'error': 'File not found'}));
          }
        } else {
          request.response.statusCode = HttpStatus.notFound;
          request.response.write(jsonEncode({'error': 'Endpoint not found'}));
        }
        await request.response.close();
      }
    } catch (e) {
      _serverStatus = 'Error starting server: $e';
      setState(() {});
    }
  }


  void _stopLocalServer() {
    if (_server != null) {
      _server!.close();
      _serverStatus = 'Server stopped';
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Local Server App'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_serverStatus),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => FileDownloadScreen()),
                );
              },
              child: Text('Download File'),
            ),
          ],
        ),
      ),
    );
  }
}

class FileDownloadScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Download File'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            _startFileDownload(context);
          },
          child: Text('Start File Download'),
        ),
      ),
    );
  }

  Future<void> _startFileDownload(BuildContext context) async {
    final url = 'http://<emulator_ip>:8080/download'; // Replace <emulator_ip> with your emulator's IP address
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      // Handle error if the URL can't be opened.
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Error'),
          content: Text('Failed to open URL'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        ),
      );
    }
  }
}

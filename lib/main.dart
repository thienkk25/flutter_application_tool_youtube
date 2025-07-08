import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  TextEditingController textEditingController = TextEditingController();
  Map data = {};
  bool checkId = false;
  bool isLoading = false;

  void covertLinkYt() {
    RegExp regExp = RegExp(
      r'''(?:https?:\/\/)?(?:www\.)?(?:youtube\.com\/(?:shorts\/|[^\/\n\s]+\/\S+\/|(?:v|e(?:mbed)?)\/|\S*?[?&]v=)|youtu\.be\/)([a-zA-Z0-9_-]{11})''',
      multiLine: true,
    );
    RegExpMatch? expMatch = regExp.firstMatch(textEditingController.text);
    if (expMatch != null) {
      String videoId = expMatch.group(1)!;
      getData(videoId);
    } else {
      setState(() {
        checkId = false;
        isLoading = false;
      });
    }
  }

  Future<void> getData(String videoId) async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.get(Uri.parse(
          "https://www.youtube.com/oembed?url=https://www.youtube.com/watch?v=$videoId&format=json"));

      if (response.statusCode == 200) {
        final dataGet = jsonDecode(response.body);
        setState(() {
          data = dataGet;
          checkId = true;
          isLoading = false;
        });
      } else {
        setState(() {
          checkId = false;
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        checkId = false;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: TextField(
                  controller: textEditingController,
                  decoration:
                      const InputDecoration(hintText: "Nhập link YouTube"),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  covertLinkYt();
                },
                child: const Text("Lấy dữ liệu"),
              ),
              const SizedBox(height: 30),
              if (isLoading) const CircularProgressIndicator(),
              if (!isLoading && checkId)
                Column(
                  children: [
                    Text(data['title'].toString()),
                    const SizedBox(height: 10),
                    Image.network(
                      data['thumbnail_url'],
                      height: 200,
                      width: 200,
                      fit: BoxFit.cover,
                    ),
                  ],
                ),
              if (!isLoading && !checkId)
                const Text("Không tìm thấy video hợp lệ."),
            ],
          ),
        ),
      ),
    );
  }
}

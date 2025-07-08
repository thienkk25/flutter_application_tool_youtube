import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';

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
      final response = await Dio().get(
        "https://www.youtube.com/oembed",
        queryParameters: {
          'url': 'https://www.youtube.com/watch?v=$videoId',
          'format': 'json',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          data = response.data;
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

  Future<Map?> downloadImage(String imageUrl, String fileName) async {
    try {
      if (await Permission.storage.request().isDenied) {
        //print("Không có quyền truy cập bộ nhớ");
        return null;
      }

      final dio = Dio();
      final response = await dio.get<List<int>>(
        imageUrl,
        options: Options(responseType: ResponseType.bytes),
      );

      final Uint8List imageBytes = Uint8List.fromList(response.data!);

      final result = await ImageGallerySaver.saveImage(
        imageBytes,
        name: fileName,
      );

      return result;
    } catch (e) {
      return null;
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
                    data['thumbnail_url'] != null
                        ? ElevatedButton(
                            onPressed: () async {
                              final result = await downloadImage(
                                  data['thumbnail_url'], data['title']);
                              if (!mounted) return;
                              if (result!['isSuccess']) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        "Tải thành công! ${result['filePath']}"),
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Có lỗi, vui lòng thử lại!"),
                                  ),
                                );
                              }
                            },
                            child: const Text("Tải ảnh về"),
                          )
                        : const SizedBox(),
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

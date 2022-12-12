import 'dart:io';

import 'package:exif/exif.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as imgLib;
import 'package:flutter_toastr/flutter_toastr.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: '右下にアレ入れるやつ'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  File? pickedImage;

  String Make = "";
  String Model = "";
  String ISOSpeedRatings = "";
  String ExposureTime = "";
  String FNumber = "";
  String MotoPath = "";
  String TimeStamp = "";

  void _selectImage() async {
    String targetpath = "";

    try {
      if (Platform.isAndroid) {
        final ImagePicker _picker = ImagePicker();
        final XFile? image =
            await _picker.pickImage(source: ImageSource.gallery);

        targetpath = image!.path;
      } else {
        FilePickerResult? result = await FilePicker.platform
            .pickFiles(allowedExtensions: ["jpg", "jpeg", "JPG", "JPEG"]);

        if (result != null) {
          targetpath = result.files.single.path!;
        } else {
          // User canceled the picker
        }
      }
    } catch (ex) {
      setState(() {
        FlutterToastr.show("error: $ex", context,
            duration: FlutterToastr.lengthShort,
            position: FlutterToastr.bottom);
      });
    }

    if (targetpath != "") {
      final tags =
          await readExifFromBytes(await File(targetpath).readAsBytes());

      if (kDebugMode) {
        for (var r in tags.keys) {
          print("$r : ${tags[r]}");
        }
      }

      setState(() {
        pickedImage = File(targetpath);

        if (tags.containsKey("Image DateTime")) {
          DateFormat outputFormat = DateFormat('yy.MM.dd HH:mm');
          TimeStamp = outputFormat.format(DateFormat("yyyy:MM:dd HH:mm:ss")
              .parse(tags["Image DateTime"]!.printable));
        }
        if (tags.containsKey("Image Make")) {
          Make = tags["Image Make"]!.printable.trimRight();
        }
        if (tags.containsKey("Image Model")) {
          Model = tags["Image Model"]!.printable.trimRight();
        }
        if (tags.containsKey("EXIF ISOSpeedRatings")) {
          ISOSpeedRatings = tags["EXIF ISOSpeedRatings"]!.printable.trimRight();
        }
        if (tags.containsKey("EXIF ExposureTime")) {
          ExposureTime = tags["EXIF ExposureTime"]!.printable.trimRight();
        }
        if (tags.containsKey("EXIF FNumber")) {
          FNumber = tags["EXIF FNumber"]!.printable.trimRight();
          if (FNumber.contains("/")) {
            FNumber = (double.parse(FNumber.split("/")[0]) /
                    double.parse(FNumber.split("/")[1]))
                .toString();
          }
        }
      });

      MotoPath = targetpath;
    }
  }

  void _writeImage() async {
    if (pickedImage != null) {
      imgLib.Image? image =
          imgLib.decodeImage(File(MotoPath).readAsBytesSync());
      String kakumoji = TimeStamp;
      String kakumoji2 = 'lin@pixelfed.gdgd.jp.net';
      String kakumoji3 =
          'camera: $Make $Model [ F$FNumber $ExposureTime ISO$ISOSpeedRatings ]';

      var digitalseven = await rootBundle.load("assets/fonts/digital7.zip");

      var bfDigitalseven =
          imgLib.BitmapFont.fromZip(digitalseven.buffer.asUint8List());

      imgLib.drawString(image!, bfDigitalseven, image.width - 32,
          image.height - 215, kakumoji,
          color: 0xff00c0ff, rightJustify: true);
      imgLib.drawString(image!, bfDigitalseven, image.width - 32,
          image.height - 145, kakumoji2,
          color: 0xff00c0ff, rightJustify: true);
      imgLib.drawString(image!, bfDigitalseven, image.width - 32,
          image.height - 75, kakumoji3,
          color: 0xff00c0ff, rightJustify: true);

      Directory tempDir = await getTemporaryDirectory();
      String tempPath = "${tempDir.path}/${MotoPath.split("/").last}.moji.jpg";
      File outfile_a = File(tempPath);
      await outfile_a.writeAsBytes(imgLib.encodeJpg(image));
      Share.shareXFiles([XFile(tempPath)], text: '文字入りの写真');

      setState(() {
        FlutterToastr.show("終わったぜ", context,
            duration: FlutterToastr.lengthShort,
            position: FlutterToastr.bottom);
      });
    }
  }

  Widget _imageViewer() {
    return Expanded(
        child: pickedImage != null
            ? Padding(
                padding: const EdgeInsets.all(5),
                child: Image.file(pickedImage!))
            : const Center(child: Text("No Image")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            _imageViewer(),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: ElevatedButton(
                    onPressed: _selectImage,
                    child: const Text("画像選択"),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(3),
                  child: Text(Make),
                ),
                Padding(
                  padding: const EdgeInsets.all(3),
                  child: Text(Model),
                ),
                Padding(
                  padding: const EdgeInsets.all(3),
                  child: Text(ISOSpeedRatings),
                ),
                Padding(
                  padding: const EdgeInsets.all(3),
                  child: Text(ExposureTime),
                ),
                Padding(
                  padding: const EdgeInsets.all(3),
                  child: Text(FNumber),
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: ElevatedButton(
                    onPressed: _writeImage,
                    child: const Text("文字入れ保存"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

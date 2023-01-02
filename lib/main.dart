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
import 'package:shared_preferences/shared_preferences.dart';

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
  @override
  void initState() {
    super.initState();

    _loadConfig();
  }

  void _loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      if (prefs.containsKey("insertName")) {
        _nameConfigController.text = prefs.getString("insertName")!;
      }
      if (prefs.containsKey("defaultCheckName")) {
        _out_name = prefs.getBool("defaultCheckName");
      }
      if (prefs.containsKey("defaultCheckStamp")) {
        _out_stamp = prefs.getBool("defaultCheckStamp");
      }
      if (prefs.containsKey("defaultCheckMake")) {
        _out_make = prefs.getBool("defaultCheckMake");
      }
      if (prefs.containsKey("defaultCheckModel")) {
        _out_model = prefs.getBool("defaultCheckModel");
      }
      if (prefs.containsKey("defaultCheckLens")) {
        _out_lens = prefs.getBool("defaultCheckLens");
      }
      if (prefs.containsKey("defaultCheckParam")) {
        _out_param = prefs.getBool("defaultCheckParam");
      }

      // モデル固有の設定を呼び出す
      if (Model != "") {
        if (prefs.containsKey("insertName_$Model")) {
          _nameConfigController.text = prefs.getString("insertName_$Model")!;
        }
        if (prefs.containsKey("defaultCheckName_$Model")) {
          _out_name = prefs.getBool("defaultCheckName_$Model");
        }
        if (prefs.containsKey("defaultCheckStamp_$Model")) {
          _out_stamp = prefs.getBool("defaultCheckStamp_$Model");
        }
        if (prefs.containsKey("defaultCheckMake_$Model")) {
          _out_make = prefs.getBool("defaultCheckMake_$Model");
        }
        if (prefs.containsKey("defaultCheckModel_$Model")) {
          _out_model = prefs.getBool("defaultCheckModel_$Model");
        }
        if (prefs.containsKey("defaultCheckLens_$Model")) {
          _out_lens = prefs.getBool("defaultCheckLens_$Model");
        }
        if (prefs.containsKey("defaultCheckParam_$Model")) {
          _out_param = prefs.getBool("defaultCheckParam_$Model");
        }
      }
    });
  }

  File? pickedImage;

  String Make = "";
  String Model = "";
  String Lens = "";
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
        if (tags.containsKey("EXIF LensModel")) {
          Lens = tags["EXIF LensModel"]!.printable.trimRight();
        } else {
          Lens = "";
        }
        _lensConfigController.text = Lens;
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

      // モデル固有の設定を読み込む
      _loadConfig();
    }
  }

  void _writeImage() async {
    if (pickedImage != null) {
      imgLib.Image? image =
          imgLib.decodeImage(File(MotoPath).readAsBytesSync());

      List<String> kakikomi_list = [];

      if (_out_stamp == true) {
        kakikomi_list.add(TimeStamp);
      }

      if (_out_name == true) {
        kakikomi_list.add(_nameConfigController.text);
      }

      List<String> kakikomi3List = [];
      if (_out_model == true) {
        String bodyHeader = "";
        if (_out_lens == true) {
          bodyHeader = "body:";
        } else {
          bodyHeader = "camera:";
        }
        if (_out_make == true) {
          kakikomi3List.add("$bodyHeader $Make $Model");
        } else {
          kakikomi3List.add("$bodyHeader $Model");
        }
      }
      if (_out_lens == true) {
        kakikomi3List.add("lens: ${_lensConfigController.text}");
      }
      if (_out_param == true) {
        kakikomi3List.add("[ F$FNumber $ExposureTime ISO$ISOSpeedRatings ]");
      }
      if (kakikomi3List.isNotEmpty) {
        kakikomi_list.add(kakikomi3List.join(' '));
      }

      var digitalseven = await rootBundle.load("assets/fonts/digital7.zip");

      var bfDigitalseven =
          imgLib.BitmapFont.fromZip(digitalseven.buffer.asUint8List());

      var y_offset = 75;
      for (var strrow in kakikomi_list.reversed) {
        imgLib.drawString(
          image!,
          bfDigitalseven,
          image.width - 32,
          image.height - y_offset,
          strrow.replaceAll("(", "[").replaceAll(")", "]"),
          color: 0xff00c0ff,
          rightJustify: true,
        );
        y_offset += 70;
      }

      Directory tempDir = await getTemporaryDirectory();
      String tempPath = "${tempDir.path}/${MotoPath.split("/").last}.moji.jpg";
      File outfile_a = File(tempPath);
      await outfile_a.writeAsBytes(imgLib.encodeJpg(image!));
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

  bool? _out_name = true;
  void _handleCheckboxOutName(bool? e) {
    setState(() {
      _out_name = e;
    });
  }

  bool? _out_stamp = true;
  void _handleCheckboxOutStamp(bool? e) {
    setState(() {
      _out_stamp = e;
    });
  }

  bool? _out_make = true;
  void _handleCheckboxOutMake(bool? e) {
    setState(() {
      _out_make = e;
    });
  }

  bool? _out_model = true;
  void _handleCheckboxOutModel(bool? e) {
    setState(() {
      _out_model = e;
    });
  }

  bool? _out_lens = true;
  void _handleCheckboxOutLens(bool? e) {
    setState(() {
      _out_lens = e;
    });
  }

  bool? _out_param = true;
  void _handleCheckboxOutParam(bool? e) {
    setState(() {
      _out_param = e;
    });
  }

  final TextEditingController _nameConfigController = TextEditingController();
  final TextEditingController _lensConfigController = TextEditingController();

  void _writeConfig(bool withModel) async {
    final prefs = await SharedPreferences.getInstance();
    if (withModel) {
      if (Model == "") {
        setState(() {
          FlutterToastr.show("モデル名がExifに入ってる写真を読み込んでくれ", context,
              duration: FlutterToastr.lengthShort,
              position: FlutterToastr.bottom);
        });
        return;
      }

      // モデル固有の設定を保存
      prefs.setString("insertName_$Model", _nameConfigController.text);
      prefs.setBool("defaultCheckName_$Model", _out_name!);
      prefs.setBool("defaultCheckStamp_$Model", _out_stamp!);
      prefs.setBool("defaultCheckMake_$Model", _out_make!);
      prefs.setBool("defaultCheckModel_$Model", _out_model!);
      prefs.setBool("defaultCheckLens_$Model", _out_lens!);
      prefs.setBool("defaultCheckParam_$Model", _out_param!);
    } else {
      prefs.setString("insertName", _nameConfigController.text);
      prefs.setBool("defaultCheckName", _out_name!);
      prefs.setBool("defaultCheckStamp", _out_stamp!);
      prefs.setBool("defaultCheckMake", _out_make!);
      prefs.setBool("defaultCheckModel", _out_model!);
      prefs.setBool("defaultCheckLens", _out_lens!);
      prefs.setBool("defaultCheckParam", _out_param!);
    }

    setState(() {
      FlutterToastr.show("設定は確かに保存したぜ", context,
          duration: FlutterToastr.lengthShort, position: FlutterToastr.bottom);
    });
  }

  void _deleteConfig(bool withModel) async {
    final prefs = await SharedPreferences.getInstance();
    if (withModel) {
      if (Model == "") {
        setState(() {
          FlutterToastr.show("モデル名がExifに入ってる写真を読み込んでくれ", context,
              duration: FlutterToastr.lengthShort,
              position: FlutterToastr.bottom);
        });
        return;
      }

      // モデル固有の設定を削除
      prefs.remove("insertName_$Model");
      prefs.remove("defaultCheckName_$Model");
      prefs.remove("defaultCheckStamp_$Model");
      prefs.remove("defaultCheckMake_$Model");
      prefs.remove("defaultCheckModel_$Model");
      prefs.remove("defaultCheckLens_$Model");
      prefs.remove("defaultCheckParam_$Model");
    } else {
      prefs.remove("insertName");
      prefs.remove("defaultCheckName");
      prefs.remove("defaultCheckStamp");
      prefs.remove("defaultCheckMake");
      prefs.remove("defaultCheckModel");
      prefs.remove("defaultCheckLens");
      prefs.remove("defaultCheckParam");
    }

    setState(() {
      FlutterToastr.show("設定は確かに保存したぜ", context,
          duration: FlutterToastr.lengthShort, position: FlutterToastr.bottom);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Row(
          mainAxisSize: MainAxisSize.max,
          children: [
            _imageViewer(),
            SizedBox(
              width: 400,
              child: ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: ElevatedButton(
                      onPressed: _selectImage,
                      child: const Text("画像選択"),
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  CheckboxListTile(
                    activeColor: Colors.blue,
                    title: const Text("ネームを入れる"),
                    controlAffinity: ListTileControlAffinity.leading,
                    value: _out_name,
                    onChanged: _handleCheckboxOutName,
                  ),
                  CheckboxListTile(
                    activeColor: Colors.blue,
                    title:
                        Row(children: [const Text("撮影日時："), Text(TimeStamp)]),
                    controlAffinity: ListTileControlAffinity.leading,
                    value: _out_stamp,
                    onChanged: _handleCheckboxOutStamp,
                  ),
                  CheckboxListTile(
                    activeColor: Colors.blue,
                    title: Row(children: [const Text("メーカー："), Text(Make)]),
                    controlAffinity: ListTileControlAffinity.leading,
                    value: _out_make,
                    onChanged: _handleCheckboxOutMake,
                  ),
                  CheckboxListTile(
                    activeColor: Colors.blue,
                    title: Row(children: [const Text("カメラ："), Text(Model)]),
                    controlAffinity: ListTileControlAffinity.leading,
                    value: _out_model,
                    onChanged: _handleCheckboxOutModel,
                  ),
                  CheckboxListTile(
                    activeColor: Colors.blue,
                    title: Row(children: [const Text("レンズ："), Text(Lens)]),
                    controlAffinity: ListTileControlAffinity.leading,
                    value: _out_lens,
                    onChanged: _handleCheckboxOutLens,
                  ),
                  CheckboxListTile(
                    activeColor: Colors.blue,
                    title: Row(children: [
                      const Text("撮影条件：[ F"),
                      Text(FNumber),
                      const Text(" "),
                      Text(ExposureTime),
                      const Text(" ISO"),
                      Text(ISOSpeedRatings),
                      const Text(" ]"),
                    ]),
                    controlAffinity: ListTileControlAffinity.leading,
                    value: _out_param,
                    onChanged: _handleCheckboxOutParam,
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  TextField(
                    controller: _lensConfigController,
                    decoration: const InputDecoration(
                      hintText: '使ったレンズ',
                      labelText: 'レンズ情報上書き',
                    ),
                  ),
                  const SizedBox(
                    height: 20,
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
            ),
          ],
        ),
      ),
      drawer: Drawer(
        child: ListView(children: [
          const SizedBox(
            height: 60,
            child: DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.lightBlue,
              ),
              child: Text(
                '設定のたぐい',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
          TextField(
            controller: _nameConfigController,
            decoration: const InputDecoration(
              hintText: '素敵な名前',
              labelText: 'ネーム',
            ),
          ),
          const Text("デフォルトチェック"),
          CheckboxListTile(
            activeColor: Colors.blue,
            title: const Text("ネームを入れる"),
            controlAffinity: ListTileControlAffinity.leading,
            value: _out_name,
            onChanged: _handleCheckboxOutName,
          ),
          CheckboxListTile(
            activeColor: Colors.blue,
            title: const Text("撮影日時"),
            controlAffinity: ListTileControlAffinity.leading,
            value: _out_stamp,
            onChanged: _handleCheckboxOutStamp,
          ),
          CheckboxListTile(
            activeColor: Colors.blue,
            title: const Text("メーカー"),
            controlAffinity: ListTileControlAffinity.leading,
            value: _out_make,
            onChanged: _handleCheckboxOutMake,
          ),
          CheckboxListTile(
            activeColor: Colors.blue,
            title: const Text("カメラ"),
            controlAffinity: ListTileControlAffinity.leading,
            value: _out_model,
            onChanged: _handleCheckboxOutModel,
          ),
          CheckboxListTile(
            activeColor: Colors.blue,
            title: const Text("レンズ"),
            controlAffinity: ListTileControlAffinity.leading,
            value: _out_lens,
            onChanged: _handleCheckboxOutLens,
          ),
          CheckboxListTile(
            activeColor: Colors.blue,
            title: const Text("撮影条件"),
            controlAffinity: ListTileControlAffinity.leading,
            value: _out_param,
            onChanged: _handleCheckboxOutParam,
          ),
          const SizedBox(
            height: 30,
          ),
          ElevatedButton(
            onPressed: () => _writeConfig(false),
            child: const Text("設定のたぐいを保存"),
          ),
          const SizedBox(
            height: 10,
          ),
          ElevatedButton(
            onPressed: () => _deleteConfig(false),
            child: const Text("設定のたぐいを削除"),
          ),
          const SizedBox(
            height: 30,
          ),
          ElevatedButton(
            onPressed: () => _writeConfig(true),
            child: const Text("モデル固有の設定を保存"),
          ),
          const SizedBox(
            height: 10,
          ),
          ElevatedButton(
            onPressed: () => _deleteConfig(true),
            child: const Text("モデル固有の設定を削除"),
          ),
          const SizedBox(
            height: 30,
          ),
        ]),
      ),
    );
  }
}

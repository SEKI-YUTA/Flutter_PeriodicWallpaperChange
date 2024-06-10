import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_wallpaper_manager/flutter_wallpaper_manager.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

const iamgeList = [
  "assets/rainy_night.webp",
  "assets/night.webp",
  "assets/rainy.webp",
  "assets/sunny.webp",
];
const periodicUniqueName = "periodicWallpaperChange";
const periodic1hourTaskName = "periodic1hourTask";

void _changeWallpaper() async {
  print("change wallpaper");
  var randomIndex = Random().nextInt(4);
  // ここに壁紙を変更する処理を書く
  var byteData = await rootBundle.load(iamgeList[randomIndex]);
  var file = File("${(await getTemporaryDirectory()).path}/tmp_image.webp");
  await file.writeAsBytes(byteData.buffer.asUint8List());
  int location = WallpaperManager.BOTH_SCREEN; //can be Home/Lock Screen
  bool result = await WallpaperManager.setWallpaperFromFile(
      file.path, location); //provide image path

  DateTime now = DateTime.now();
  DateFormat formatter = DateFormat('yyyy年MM月dd日 HH時mm分ss秒');
  String formatted = formatter.format(now);
  print("$formatted $result"); // 出力例: 2024年06月10日 15時45分30秒
}

void _test() {
  Workmanager().registerOneOffTask("hogehoge", "fugafuga",
      initialDelay: const Duration(seconds: 5));
}

void _changeWallpaperPeriodically() {
  // ここに定期的に壁紙を変更する処理を書く
  if (Platform.isAndroid) {
    print("scheduled");
    Workmanager().registerPeriodicTask(
      periodicUniqueName,
      periodic1hourTaskName,
      frequency: const Duration(hours: 1),
    );
  } else {
    print(
        "This platform is not android. please run this code on android device or emulator.");
  }
}

void _cancelAllPeriodicTask() {
  Workmanager().cancelAll();
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    int? totalExecutions;
    final _sharedPreference =
        await SharedPreferences.getInstance(); //Initialize dependency
    print("Native called background task: $task");
    _changeWallpaper();
    try {
      //add code execution
      totalExecutions = _sharedPreference.getInt("totalExecutions");
      _sharedPreference.setInt(
          "totalExecutions", totalExecutions == null ? 1 : totalExecutions + 1);
    } catch (err) {
      print("Error: $err");
      throw Exception(err);
    }

    return Future.value(true);
  });
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: true,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
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
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
                onPressed: _changeWallpaper, child: const Text("壁紙をランダムで変える")),
            ElevatedButton(
                onPressed: _changeWallpaperPeriodically,
                child: Text("定期的に壁紙を変更する")),
            ElevatedButton(
                onPressed: _cancelAllPeriodicTask,
                child: Text("全ての定期実行をキャンセル")),
            ElevatedButton(onPressed: _test, child: Text("テスト")),
          ],
        ),
      ),
      floatingActionButton: const FloatingActionButton(
        onPressed: null,
        tooltip: 'Increment',
        child: Icon(Icons.add),
      ),
    );
  }
}

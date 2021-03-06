import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:another_brother/label_info.dart';
import 'package:another_brother/printer_info.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tflite/tflite.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final controller = PageController(initialPage: 1);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Another Brother Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: PageView(children: [
        QlBluetoothPrintPage(title: 'QL-1110NWB Bluetooth Sample'),
      ]),
    );
  }
}

class QlBluetoothPrintPage extends StatefulWidget {
  QlBluetoothPrintPage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _QlBluetoothPrintPageState createState() => _QlBluetoothPrintPageState();
}

class _QlBluetoothPrintPageState extends State<QlBluetoothPrintPage> {
  bool _error = false;
  Uint8List pngBytes;
  GlobalKey _globalKey = GlobalKey();

  void brother_print(BuildContext context) async {
    var printer = new Printer();
    var printInfo = PrinterInfo();
    printInfo.printerModel = Model.QL_1110NWB;
    printInfo.printMode = PrintMode.FIT_TO_PAGE;
    printInfo.isAutoCut = true;
    printInfo.port = Port.BLUETOOTH;
    // Set the label type.
    printInfo.labelNameIndex = QL1100.ordinalFromID(QL1100.W103.getId());

    // Set the printer info so we can use the SDK to get the printers.
    await printer.setPrinterInfo(printInfo);

    // Get a list of printers with my model available in the network.
    List<BluetoothPrinter> printers =
        await printer.getBluetoothPrinters([Model.QL_1110NWB.getName()]);

    if (printers.isEmpty) {
      // Show a message if no printers are found.
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text("No paired printers found on your device."),
        ),
      ));

      return;
    }
    // Get the IP Address from the first printer found.
    printInfo.macAddress = printers.single.macAddress;

    printer.setPrinterInfo(printInfo);
    // printer.printImage(await loadImage('assets/brother_hack.png'));
    // await _capturePng();
    // printer.printImage(await loadImageFromUint8List(pngBytes));
    printer.printImage(await p2pImage('assets/brother_hack.png'));
  }

  /*
  Future<void> _capturePng() async {
    try {
      final RenderRepaintBoundary boundary =
          _globalKey.currentContext.findRenderObject();
      final image = await boundary.toImage(pixelRatio: 2.0); // image quality
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      pngBytes = byteData.buffer.asUint8List();
    } catch (e) {
      print(e);
    }
  }
   */

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                "Don't forget to grant permissions to your app in Settings.",
                textAlign: TextAlign.center,
              ),
            ),
            Image(image: AssetImage('assets/brother_hack.png'))
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => brother_print(context),
        tooltip: 'Print',
        child: Icon(Icons.print),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  Future<ui.Image> loadImage(String assetPath) async {
    final ByteData img = await rootBundle.load(assetPath);
    final Completer<ui.Image> completer = new Completer();
    ui.decodeImageFromList(new Uint8List.view(img.buffer), (ui.Image img) {
      return completer.complete(img);
    });
    return completer.future;
  }

  // Load tflite model file
  loadModel(String modelFile, {String labelsFile}) async {
    Tflite.close();
    try {
      String res;
      res = await Tflite.loadModel(
        model: modelFile,
        labels: labelsFile,
      );
      print(res);
    } on PlatformException {
      print("cant load model");
    }
  }

  Future<ui.Image> p2pImage(String assetPath) async {
    Tflite.close();

    print('Loading model ...');
    String res = await Tflite.loadModel(
        model: "assets/models/whitebox_cartoon_gan_int8.tflite",
        labels: "assets/models/ssd_mobilenet.txt",
        numThreads: 1, // defaults to 1
        isAsset:
            true, // defaults to true, set to false to load resources outside assets
        useGpuDelegate:
            false // defaults to false, set to true to use GPU delegate
        );

    print('Model loaded.');

/*
    var imageBinary = (await rootBundle.load(assetPath)).buffer.asUint8List();

    var result = await Tflite.runPix2PixOnBinary(
        binary: imageBinary,
        asynch: true, // defaults to true
        outputType: "png");
 */

    var result = await Tflite.runPix2PixOnImage(
        path: assetPath,
        asynch: true, // defaults to true
        outputType: "png");

    return await loadImageFromUint8List(result);

    return await loadImage(assetPath);
  }

  Future<ui.Image> loadImageFromUint8List(Uint8List encodedImage) async {
    final Completer<ui.Image> completer = new Completer();
    ui.decodeImageFromList(encodedImage, (ui.Image img) {
      return completer.complete(img);
    });
    return completer.future;
  }
}

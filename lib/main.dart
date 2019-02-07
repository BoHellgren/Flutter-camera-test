import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';

List<CameraDescription> cameras;

void main() async {
  cameras = await availableCameras();
  SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft])
      .then((_) {
    runApp(MaterialApp(home: MyHomePage()));
  });
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key}) : super(key: key);
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  CameraController controller;
  bool showPreview = true;
  CameraImage lastImage;

  @override
  void initState() {
    super.initState();
    controller = CameraController(cameras[0], ResolutionPreset.low);
    controller.initialize().then((_) {
      print('camera initialization complete');
      if (!mounted) {
        return;
      }
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Camera test'),
      ),
      body: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
        showPreview
            ? SizedBox(
                height: 200.0,
                width: 280.0,
                child: RotatedBox(quarterTurns: 3, child: CameraPreview(controller)))
            : Text('Preview stopped'),
        Column(children: [
          RaisedButton(
            child: Text('Start imagestream'),
            onPressed: () async {
              int images = 0;
              await controller.startImageStream((CameraImage availableImage) {
                images++;
                lastImage = availableImage;
                print('Saved CameraImage no $images');
              });
              print('------ Imagestream started --------');
            },
          ),
          RaisedButton(
            child: Text('Stop imagestream'),
            onPressed: () async {
              await controller.stopImageStream();
              print('------ Imagestream stopped -------');
              showPreview = false;
              setState(() {});
            },
          ),
          RaisedButton(
            child: Text('Scan last image'),
            onPressed: () => scanLastImage(),
          ),
        ]),
      ]),
    );
  }

  void scanLastImage() async {
    if (lastImage == null) {
      print('Cannot scan null image');
      return;
    }

    print("--------- Start processing last image -----------");

    int height = lastImage.height;
    int width = lastImage.width;
    int len = lastImage.planes[0].bytes.length;

    // Do a flipHorizontal - may not bee needed on all phone models
    Uint8List flippedImage = Uint8List(len);
    for (int i = 0; i < height; i++) {
      for (int j = 0; j < width; j++) {
        flippedImage[i * width + j] =
            lastImage.planes[0].bytes[i * width + (width - j) - 1];
      }
    }

    final FirebaseVisionImageMetadata metadata = FirebaseVisionImageMetadata(
        rawFormat: lastImage.format.raw,
        size: Size(width.toDouble(), height.toDouble()),
        planeData: lastImage.planes
            .map((currentPlane) => FirebaseVisionImagePlaneMetadata(
                bytesPerRow: currentPlane.bytesPerRow,
                height: currentPlane.height,
                width: currentPlane.width))
            .toList(),
        rotation: ImageRotation.rotation180);

    final FirebaseVisionImage visionImage =
        FirebaseVisionImage.fromBytes(flippedImage, metadata);
     //   FirebaseVisionImage.fromBytes(lastImage.planes[0].bytes, metadata);

    final TextRecognizer textRecognizer =
        FirebaseVision.instance.textRecognizer();

    for (int k = 1; k <= 100; k++) {
      final VisionText visionText =
          await textRecognizer.processImage(visionImage);
      print('------- visionText.text after processImage attempt no $k ---------');
      int lineNum = 1;
      for (TextBlock block in visionText.blocks) {
        for (TextLine line in block.lines) {
          print('Line no $lineNum Text ${line.text} Box ${line.boundingBox.left}, ${line.boundingBox.right}, ${line.boundingBox.top}, ${line.boundingBox.bottom}');
        }
        lineNum++;
      }
    }
  }
}

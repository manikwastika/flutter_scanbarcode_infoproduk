import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:camera/camera.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  runApp(MyApp(cameras));
}

class MyApp extends StatelessWidget {
  final List<CameraDescription> cameras;

  const MyApp(this.cameras, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Barcode Scanner',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(cameras: cameras),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final List<CameraDescription> cameras;

  const MyHomePage({Key? key, required this.cameras}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Selamat datang di\ninfoproduk.id',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 20),
                      Image.asset(
                        'assets/img/barcode-logo.png',
                        width: 200,
                        height: 200,
                        fit: BoxFit.contain,
                      ),
                      SizedBox(height: 20),
                      Text(
                        'Untuk memulai, silahkan tekan tombol Scan Barcode dan pindai Barcode yang terdapat pada produk.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BarcodeScannerPage(
                        cameras: widget.cameras,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.black,
                  backgroundColor: Color.fromARGB(255, 226, 226, 226),
                  padding: EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                  elevation: 0,
                  minimumSize: Size(double.infinity, 50),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.qr_code_scanner, color: Colors.black),
                    SizedBox(width: 10),
                    Text(
                      'Scan Barcode',
                      style: TextStyle(fontSize: 16, color: Colors.black),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BarcodeScannerPage extends StatefulWidget {
  final List<CameraDescription> cameras;

  const BarcodeScannerPage({
    Key? key,
    required this.cameras,
  }) : super(key: key);

  @override
  _BarcodeScannerPageState createState() => _BarcodeScannerPageState();
}

class _BarcodeScannerPageState extends State<BarcodeScannerPage>
    with SingleTickerProviderStateMixin {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  bool _isScanning = false;
  bool _isFlashOn = false;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _animation =
        Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);
  }

  Future<void> _initializeCamera() async {
    final CameraDescription camera = widget.cameras.first;
    _controller = CameraController(camera, ResolutionPreset.medium);
    _initializeControllerFuture = _controller!.initialize();
    await _initializeControllerFuture;
    if (mounted) {
      setState(() {});
      _startScanning();
    }
  }

  void _startScanning() {
    if (_controller != null && _controller!.value.isInitialized) {
      _isScanning = true;
      _scanBarcodes();
    }
  }

  Future<void> _scanBarcodes() async {
    if (!_isScanning) return;

    try {
      final image = await _controller!.takePicture();
      final inputImage = InputImage.fromFilePath(image.path);
      final barcodeScanner = GoogleMlKit.vision.barcodeScanner();

      final barcodes = await barcodeScanner.processImage(inputImage);
      if (barcodes.isNotEmpty) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ProductInfoPage(
              barcode: barcodes[0].displayValue ?? '',
              cameras: widget.cameras,
            ),
          ),
        );
      } else {
        Future.delayed(Duration(milliseconds: 500), _scanBarcodes);
      }

      await barcodeScanner.close();
    } catch (e) {
      print('Error scanning barcode: $e');
      Future.delayed(Duration(milliseconds: 500), _scanBarcodes);
    }
  }

  Future<void> _toggleFlash() async {
    try {
      if (_controller != null) {
        if (_isFlashOn) {
          await _controller!.setFlashMode(FlashMode.off);
        } else {
          await _controller!.setFlashMode(FlashMode.torch);
        }
        setState(() {
          _isFlashOn = !_isFlashOn;
        });
      }
    } catch (e) {
      print('Error toggling flash: $e');
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker _picker = ImagePicker();
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        print('Image Path: ${image.path}');
        _scanBarcodeFromImage(image.path);
      } else {
        print('No image selected.');
      }
    } catch (e) {
      print('Error picking image: $e');
    }
  }

  void _showErrorDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            "Barcode Salah",
            style: TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 60,
              ),
              SizedBox(height: 20),
              Text(
                "Gambar barcode yang anda miliki salah, silahkan upload ulang barcode",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
          actions: [
            Center(
              child: ElevatedButton(
                child: Text(
                  'OK',
                  style: TextStyle(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.red,
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _scanBarcodeFromImage(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final barcodeScanner = GoogleMlKit.vision.barcodeScanner();

    try {
      final List<Barcode> barcodes =
          await barcodeScanner.processImage(inputImage);
      if (barcodes.isNotEmpty) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ProductInfoPage(
              barcode: barcodes[0].displayValue ?? '',
              cameras: widget.cameras,
            ),
          ),
        );
      } else {
        _showErrorDialog();
      }
    } catch (e) {
      print('Error scanning barcode: $e');
      _showErrorDialog();
    } finally {
      barcodeScanner.close();
    }
  }

  @override
  void dispose() {
    _isScanning = false;
    _controller?.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return Center(child: CircularProgressIndicator());
    }
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => MyHomePage(cameras: widget.cameras),
          ),
          (route) => false,
        );
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Scan Barcode'),
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (context) => MyHomePage(cameras: widget.cameras),
                ),
                (route) => false,
              );
            },
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  CameraPreview(_controller!),
                  Positioned(
                    top: MediaQuery.of(context).size.height * 0.2,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.7,
                        height: MediaQuery.of(context).size.width * 0.7,
                        child: CustomPaint(
                          painter: ScannerOverlayPainter(animation: _animation),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 16,
                    right: 16,
                    child: IconButton(
                      icon: Icon(
                        _isFlashOn ? Icons.flash_on : Icons.flash_off,
                        color: Colors.white,
                      ),
                      onPressed: _toggleFlash,
                    ),
                  ),
                  Positioned(
                    bottom: 25,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Container(
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.5),
                              spreadRadius: 2,
                              blurRadius: 5,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 130,
                              height: 50,
                              child: Material(
                                elevation: 8,
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: ElevatedButton(
                                    onPressed: _pickImage,
                                    child: Text('Scan Image'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      foregroundColor: Colors.black,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 15),
                            Container(
                              width: 1,
                              color: Colors.grey,
                              height: 40,
                            ),
                            SizedBox(width: 15),
                            Container(
                              width: 130,
                              height: 50,
                              child: Material(
                                elevation: 8,
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: ElevatedButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              ManualBarcodeInputPage(
                                            cameras: widget.cameras,
                                          ),
                                        ),
                                      );
                                    },
                                    child: Text('Manually'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      foregroundColor: Colors.black,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ScannerOverlayPainter extends CustomPainter {
  final Animation<double> animation;

  ScannerOverlayPainter({required this.animation}) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final double cornerSize = size.width * 0.1;

    // Top-left corner
    canvas.drawLine(Offset(0, 0), Offset(0, cornerSize), paint);
    canvas.drawLine(Offset(0, 0), Offset(cornerSize, 0), paint);

    // Top-right corner
    canvas.drawLine(
        Offset(size.width, 0), Offset(size.width - cornerSize, 0), paint);
    canvas.drawLine(
        Offset(size.width, 0), Offset(size.width, cornerSize), paint);

    // Bottom-left corner
    canvas.drawLine(
        Offset(0, size.height), Offset(cornerSize, size.height), paint);
    canvas.drawLine(
        Offset(0, size.height), Offset(0, size.height - cornerSize), paint);

    // Bottom-right corner
    canvas.drawLine(Offset(size.width, size.height),
        Offset(size.width - cornerSize, size.height), paint);
    canvas.drawLine(Offset(size.width, size.height),
        Offset(size.width, size.height - cornerSize), paint);

    // Scan line animation
    final scanPaint = Paint()
      ..color = Colors.red.withOpacity(0.3) // Reduced opacity here
      ..style = PaintingStyle.fill;

    final scanLineY = size.height * animation.value;
    canvas.drawRect(
        Rect.fromLTRB(0, scanLineY, size.width, scanLineY + 5), scanPaint);
  }

  @override
  bool shouldRepaint(ScannerOverlayPainter oldDelegate) {
    return true;
  }
}

class ProductInfoPage extends StatelessWidget {
  final String barcode;
  final List<CameraDescription> cameras;

  const ProductInfoPage(
      {Key? key, required this.barcode, required this.cameras})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final productData = {
      '1234567890123': {
        'name': 'Indomie Goreng Kriuk Pedas',
        'description':
            'For those who love spicy food, Indomie Mi Goreng Hot & Spicy offers the perfect combination of spices, chili, and crispy fried onion.',
        'price': 'Rp 5.000',
        'image':
            'https://www.indomie.com/uploads/product/indomie-mi-goreng-barbeque-chicken-flavour_thumb_170302372.png',
      },
      '4567890123456': {
        'name': 'Indomie Goreng Rasa Ayam Bawang',
        'description':
            'Indomie Mi Goreng Barbeque Chicken flavour has a distinctive mouthwatering barbeque chicken aroma.',
        'price': 'Rp 5.000',
        'image':
            'https://www.indomie.com/uploads/product/indomie-mi-goreng-satay-flavour_thumb_170407982.png',
      },
      '6001234567899': {
        'name': 'Indomie Cup Mi Goreng',
        'description': 'Enjoy Indomie Mi Goreng flavour in a cup format.',
        'price': 'Rp 5.000',
        'image':
            'https://www.indomie.com/uploads/product/indomie-cup-mi-goreng_detail_143804789.png',
      },
      '4820000849463': {
        'name': 'Indomie Mi Goreng 5S',
        'description': 'Indomie Mi Goreng also comes in 5 in 1 pack.',
        'price': 'Rp 15.000',
        'image':
            'https://www.indomie.com/uploads/product/indomie-mi-goreng-special-5s_detail_165508195.png',
      },
    };

    final product = productData[barcode];

    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => MyHomePage(cameras: cameras),
          ),
          (route) => false,
        );
        return false;
      },
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 50),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: MediaQuery.of(context).size.width - 40,
                            height: 250,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                  color: Color.fromRGBO(0, 0, 0, 0.08),
                                  offset: Offset(0, 4),
                                  blurRadius: 12,
                                ),
                              ],
                            ),
                            child: Center(
                              child: product != null
                                  ? Image.network(
                                      product['image']!,
                                      width: 200,
                                      height: 200,
                                      fit: BoxFit.contain,
                                    )
                                  : Icon(
                                      Icons.error_outline,
                                      color: Colors.red,
                                      size: 80,
                                    ),
                            ),
                          ),
                        ),
                        SizedBox(height: 20),
                        if (product != null) ...[
                          Text(
                            product['name']!,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'RedHatText',
                            ),
                          ),
                          SizedBox(height: 10),
                          Text(
                            product['price']!,
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(height: 20),
                          Text(
                            'Description',
                            style: TextStyle(
                              color: Colors.grey.withOpacity(0.7),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 10),
                          Text(
                            product['description']!,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black,
                            ),
                          ),
                        ] else
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(height: 20),
                                Text(
                                  'Barcode yang anda scan tidak ditemukan, pastikan kondisi barcode bersih dan tidak rusak ataupun tercoret',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.red,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BarcodeScannerPage(
                          cameras: cameras,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.black,
                    backgroundColor: Color.fromARGB(255, 226, 226, 226),
                    padding:
                        EdgeInsets.symmetric(vertical: 14, horizontal: 24.0),
                    textStyle: TextStyle(fontSize: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.qr_code, color: Colors.black),
                      SizedBox(width: 10),
                      Text('Scan Barcode Lagi'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ManualBarcodeInputPage extends StatefulWidget {
  final List<CameraDescription> cameras;

  const ManualBarcodeInputPage({Key? key, required this.cameras})
      : super(key: key);

  @override
  _ManualBarcodeInputPageState createState() => _ManualBarcodeInputPageState();
}

class _ManualBarcodeInputPageState extends State<ManualBarcodeInputPage> {
  final TextEditingController _barcodeController = TextEditingController();

  void _showErrorDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            "Barcode Salah",
            style: TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 60,
              ),
              SizedBox(height: 20),
              Text(
                "Angka Barcode yang anda masukan salah, silahkan coba lagi",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
          actions: [
            Center(
              child: ElevatedButton(
                child: Text(
                  'OK',
                  style: TextStyle(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.red,
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Input Barcode Manually'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _barcodeController,
              decoration: InputDecoration(
                labelText: 'Enter Barcode',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                String barcode = _barcodeController.text.trim();
                if (barcode.isNotEmpty) {
                  // Check if the barcode exists in the product data
                  final productData = {
                    '1234567890123': {},
                    '4567890123456': {},
                    '6001234567899': {},
                    '4820000849463': {},
                  };
                  if (productData.containsKey(barcode)) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProductInfoPage(
                          barcode: barcode,
                          cameras: widget.cameras,
                        ),
                      ),
                    );
                  } else {
                    _showErrorDialog();
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please enter a valid barcode')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.black,
                backgroundColor: Color.fromARGB(255, 226, 226, 226),
                padding: EdgeInsets.symmetric(vertical: 14, horizontal: 24.0),
                textStyle: TextStyle(fontSize: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.qr_code, color: Colors.black),
                  SizedBox(width: 10),
                  Text('Submit'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _barcodeController.dispose();
    super.dispose();
  }
}

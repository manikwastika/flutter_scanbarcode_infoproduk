import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Barcode Scanner',
      home: ScanBarcodePage(),
    );
  }
}

class ScanBarcodePage extends StatefulWidget {
  @override
  _ScanBarcodePageState createState() => _ScanBarcodePageState();
}

class _ScanBarcodePageState extends State<ScanBarcodePage> {
  // Fungsi untuk scan barcode
  @override
  void initState() {
    super.initState();
    // Langsung melakukan scan saat halaman dibuka
    scanBarcodeNormal();
  }

  Future<void> scanBarcodeNormal() async {
    String barcodeScanRes;
    try {
      barcodeScanRes = await FlutterBarcodeScanner.scanBarcode(
          '#ff6666', 'Cancel', true, ScanMode.BARCODE);
      if (!mounted) return;

      // Navigasi ke halaman info produk setelah berhasil scan
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProductInfoPage(barcode: barcodeScanRes),
        ),
      );
    } on PlatformException {
      barcodeScanRes = 'Failed to get platform version.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Barcode'),
        backgroundColor: Colors.lightBlueAccent,
        automaticallyImplyLeading: false, // Menghilangkan tanda panah
      ),
      body: Center(
        // Menghilangkan teks dan hanya menampilkan tampilan kosong
        child: Container(),
      ),
    );
  }
}

class ProductInfoPage extends StatelessWidget {
  final String barcode;

  // Buat map untuk menyimpan data produk dengan barcode sebagai kunci
  final Map<String, Map<String, String>> _productData = {
    '1234567890123': {
      'name': 'Indomie Goreng Kriuk Pedas',
      'description':
          'For those who love spicy food, Indomie Mi Goreng Hot & Spicy offers the perfect combination of spices, chili, and crispy fried onion that will awake all your senses and add sizzle to your palate.',
      'price': 'Rp 5.000',
      'image':
          'https://www.indomie.com/uploads/product/indomie-mi-goreng-barbeque-chicken-flavour_thumb_170302372.png',
    },
    '4567890123456': {
      'name': 'Indomie Goreng Rasa Ayam Bawang',
      'description':
          'Indomie Mi Goreng Barbeque Chicken flavour has a distinctive mouthwatering barbeque chicken aroma. Reenergize your day with this tantalizing delicious flavour.',
      'price': 'Rp 5.000',
      'image':
          'https://www.indomie.com/uploads/product/indomie-mi-goreng-satay-flavour_thumb_170407982.png',
    },
    '6001234567899': {
      'name': 'Indomie Cup Mi Goreng',
      'description':
          'Enjoy Indomie Mi Goreng flavour in a cup format. Comes complete with a fork for your convenience. Perfect to bring when you are traveling.',
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

  ProductInfoPage({required this.barcode});

  @override
  Widget build(BuildContext context) {
    // Cek apakah barcode yang di-scan ada dalam data produk
    final product = _productData[barcode];

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment:
              CrossAxisAlignment.start, // Set alignment ke start
          children: [
            Center(
              child: product != null
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                            height: 50), // Jarak ekstra untuk menurunkan elemen
                        Center(
                          child: Container(
                            width: MediaQuery.of(context).size.width -
                                40, // Lebar kontainer disesuaikan
                            height: 250, // Ukuran kontainer
                            decoration: BoxDecoration(
                              color: Colors
                                  .white, // Warna latar belakang kontainer
                              borderRadius: BorderRadius.circular(
                                  15), // Sudut yang membulat
                              boxShadow: [
                                BoxShadow(
                                  color: Color.fromRGBO(
                                      0, 0, 0, 0.08), // Updated shadow color
                                  offset: Offset(0, 4), // Offset for shadow
                                  blurRadius: 12, // Blur radius for shadow
                                ),
                              ],
                            ),
                            child: Center(
                              child: Image.network(
                                product['image']!,
                                width: 200, // Ukuran gambar
                                height: 200, // Ukuran gambar
                                fit: BoxFit
                                    .contain, // Pastikan gambar sesuai dalam batas
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                            height:
                                20), // Jarak antara kontainer gambar dan nama produk
                        Text(
                          product['name']!,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'RedHatText', // Menggunakan RedHatText
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          product['price']!,
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.black, // Warna teks harga hitam
                          ),
                        ),
                        SizedBox(height: 15),
                        Text(
                          'Description',
                          style: TextStyle(
                            color: Colors.grey.withOpacity(0.7),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          product['description']!,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black, // Warna teks deskripsi hitam
                          ),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        Center(
                          child: Text(
                            'Produk tidak ditemukan',
                            style: TextStyle(fontSize: 20, color: Colors.red),
                          ),
                        ),
                        SizedBox(height: 20),
                      ],
                    ),
            ),
            ElevatedButton(
              onPressed: () {
                // Kembali ke halaman scan barcode
                Navigator.pop(context);
                // Melakukan scan lagi setelah kembali
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ScanBarcodePage(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.black, // Teks jadi hitam
                backgroundColor: Color.fromARGB(
                    255, 226, 226, 226), // Menggunakan warna #bfbfbf
                padding: EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 24.0), // Ukuran tombol lebih besar
                textStyle: TextStyle(fontSize: 16), // Ukuran teks lebih besar
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(15), // BorderRadius jadi 15
                ),
              ),
              // Menambahkan ikon QR dan teks
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.qr_code,
                      color: Colors.black), // Ikon juga hitam biar serasi
                  SizedBox(width: 10), // Spasi antara ikon dan teks
                  Text('Scan Barcode Lagi'), // Teks tombol
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

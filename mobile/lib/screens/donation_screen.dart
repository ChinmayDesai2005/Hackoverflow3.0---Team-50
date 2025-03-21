
import 'package:flutter/material.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/widgets/header.dart';
import 'package:mobile/widgets/footer.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';

class DonationPage extends StatefulWidget {
  const DonationPage({Key? key}) : super(key: key);

  @override
  _DonationPageState createState() => _DonationPageState();
}

class DonationReceiptGenerator {
  static Future<File> generatePDFReceipt({
    required String appName,
    required String username,
    required String paymentId,
    required String fundraiserTitle,
    required double donationAmount,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(pw.Page(
      build: (pw.Context context) {
        return pw.Center(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.Text("Donation Receipt",
                  style: pw.TextStyle(fontSize: 30, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 20),
              pw.Text("Payment ID: $paymentId", style: pw.TextStyle(fontSize: 18)),
              pw.Text("Fundraiser: $fundraiserTitle", style: pw.TextStyle(fontSize: 18)),
              pw.Text("Amount: ₹$donationAmount", style: pw.TextStyle(fontSize: 18)),
              pw.SizedBox(height: 20),
              pw.Text("Thank you for your contribution!", style: pw.TextStyle(fontSize: 18)),
            ],
          ),
        );
      },
    ));

    // Save to Downloads directory
    final directory = Directory('/storage/emulated/0/Download'); // Android Downloads directory
    final filePath = "${directory.path}/DonationReceipt_$paymentId.pdf";
    final file = File(filePath);

    // Ensure the directory exists
    if (!directory.existsSync()) {
      directory.createSync(recursive: true);
    }

    await file.writeAsBytes(await pdf.save());
    return file;
  }
}

class _DonationPageState extends State<DonationPage> {
  int _currentIndex = 0;
  bool _isLoading = true;
  List<Map<String, dynamic>> _fundraisers = [];
  String _errorMessage = '';
  late Razorpay _razorpay;
  final TextEditingController _amountController = TextEditingController();
  String _loggedInUserName = ""; 
  String _selectfundRaiser = "";
  
  String get fundraiserId => _selectfundRaiser;
  String get userId => _loggedInUserName;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    _fetchLoggedInUser();
    _fetchFundraisers();
  }

  @override
  void dispose() {
    _razorpay.clear();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _fetchLoggedInUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _loggedInUserName =
            prefs.getString('userName') ?? 'Guest'; 
      });
    } catch (e) {
      print('Error fetching logged-in user: $e');
      setState(() {
        _errorMessage = 'Failed to load user information.';
      });
    }
  }

  Future<void> _fetchFundraisers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final fundraisers = await ApiService.fetchFundraisers();
      setState(() {
        _fundraisers = fundraisers;
      });
    } catch (e) {
      print('Error fetching fundraisers: $e');
      setState(() {
        _errorMessage = 'Failed to load fundraisers: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _showDonationPopup(String fundraiserId) async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Enter Donation Amount'),
          content: TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(hintText: 'Enter amount'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _createOrder(fundraiserId);
              },
              child: const Text('Donate'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _createOrder(String fundraiserId) async {
    final amount = int.tryParse(_amountController.text.trim()) ?? 0;
    setState(() {
      _selectfundRaiser = fundraiserId;
    });
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid amount.")),
      );
      return;
    }

    final url = Uri.parse("http://192.168.114.113:8000/v1/donation/create-order");
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "amount": amount,
          "fundraiserId": fundraiserId,
          "userName": _loggedInUserName, 
        }),
      );

      if (response.statusCode == 200) {
        final order = jsonDecode(response.body)['order'];
        _openRazorpayCheckout(order['id'], amount);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Failed to create order. Please try again.")),
        );
      }
    } catch (e) {
      print("Error creating order: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error occurred. Please try again.")),
      );
    }
  }

  void _openRazorpayCheckout(String orderId, int amount) {
    var options = {
      'key': 'rzp_live_Gog8bh57PaPKoC',
      'amount': amount * 100,
      'order_id': orderId,
      'name': 'Fund Relief',
      'description': 'Donation Payment',
      'prefill': {
        'contact': '9876543210',
        'email': 'user@example.com',
      },
      'theme': {
        'color': '#F37254',
      },
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      print("Error opening Razorpay: $e");
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    print("Payment Successful: ${response.paymentId}");
    final amount = int.tryParse(_amountController.text.trim()) ?? 0;
    final fundraiser = _fundraisers.firstWhere((f) => f['_id'] == fundraiserId,
        orElse: () => {'title': 'Unknown Fundraiser'});
    final fundraiserTitle = fundraiser['title'] ?? 'Unknown Fundraiser';

    await _verifyPayment(
      response.orderId!,
      response.paymentId!,
      response.signature!,
      userId,
      fundraiserId,
      amount,
    );

    // Generate PDF receipt
    final pdfFile = await DonationReceiptGenerator.generatePDFReceipt(
      appName: 'Aapda Mitra | NDRF',
      username: _loggedInUserName,
      paymentId: response.paymentId!,
      fundraiserTitle: fundraiserTitle,
      donationAmount: amount.toDouble(),
    );

    // Log the saved file path
    print("PDF Receipt saved to: ${pdfFile.path}");

    // Notify the user
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("PDF saved to Downloads: ${pdfFile.path}"),
      ),
    );
  }


  Future<void> _verifyPayment(String orderId, String paymentId,
    String signature,String userId, String fundraiserId, int amount) async {
    final url = Uri.parse("http://192.168.114.113:8000/v1/donation/verify-payment");
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "razorpay_order_id": orderId,
          "razorpay_payment_id": paymentId,
          "razorpay_signature": signature,
          "userId": userId,
          "fundraiserId": fundraiserId,
          "amount": amount,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Donation Successful! Thank you.")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Payment verification failed.")),
        );
      }
    } catch (e) {
      print("Error verifying payment: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error occurred during verification.")),
      );
    }
  }

  Future<String> _generatePDFReceipt(String paymentId, String fundraiserTitle, int amount) async {
    final pdf = pw.Document();
    final directory = await getApplicationDocumentsDirectory();
    final filePath = "${directory.path}/DonationReceipt_$paymentId.pdf";

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text("Donation Receipt", style: pw.TextStyle(fontSize: 30, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 20),
                pw.Text("Payment ID: $paymentId", style: pw.TextStyle(fontSize: 18)),
                pw.Text("Fundraiser: $fundraiserTitle", style: pw.TextStyle(fontSize: 18)),
                pw.Text("Amount: ₹$amount", style: pw.TextStyle(fontSize: 18)),
                pw.SizedBox(height: 20),
                pw.Text("Thank you for your contribution!", style: pw.TextStyle(fontSize: 18)),
              ],
            ),
          );
        },
      ),
    );

    final file = File(filePath);
    await file.writeAsBytes(await pdf.save());
    return filePath;
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    print("Payment Failed: ${response.message}");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Payment Failed: ${response.message}")),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    print("External Wallet: ${response.walletName}");
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    body: SafeArea(
      child: Column(
        children: [
          const Header(), // Fixed header that won't scroll
          Expanded(
            child: SingleChildScrollView( // Make the rest of the content scrollable
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, // Align all child widgets to the left
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 16.0, top: 24.0, bottom: 16.0), // Add extra padding from the top
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start, // Align text to the left
                      children: [
                        // Main Heading: Rebuild Hope and Restore Lives
                        RichText(
                          text: const TextSpan(
                            children: [
                              TextSpan(
                                text: "Rebuild Hope,\n", // First line
                                style: TextStyle(
                                  color: Color(0xFFFC7753), // Orange
                                  fontWeight: FontWeight.bold,
                                  fontSize: 45, // Increased font size
                                ),
                              ),
                              TextSpan(
                                text: "Restore Lives", // Second line
                                style: TextStyle(
                                  color: Color(0xFF2B3674), // Dark Blue
                                  fontWeight: FontWeight.bold,
                                  fontSize: 45, // Increased font size
                                ),
                              ),
                            ],
                          ),
                          textAlign: TextAlign.left, // Align text to the left
                        ),
                        const SizedBox(height: 20.0), // Add padding between heading and subheading
                        // Subheading: Every donation brings us closer to our Goal.
                        const Text(
                          "Every donation brings us closer to our Goal.",
                          style: TextStyle(
                            color: Color(0xFF2B3674), // Dark Blue
                            fontSize: 20, // Increased font size
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.left, // Align text to the left
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24.0), // Add space between the text and the list
                  if (_isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (_errorMessage.isNotEmpty)
                    Center(
                      child: Text(
                        _errorMessage,
                        style: const TextStyle(color: Colors.red, fontSize: 16),
                      ),
                    )
                  else if (_fundraisers.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          'No fundraisers available.',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _fundraisers.length,
                      itemBuilder: (context, index) {
                        final fundraiser = _fundraisers[index];
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(25.0),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.3),
                                spreadRadius: 2,
                                blurRadius: 5,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    // Logo display
                                    // In the DonationPage build method, modify the logo display
                                  if (fundraiser['logo'] != null)
                                    Padding(
                                      padding: const EdgeInsets.only(right: 12.0),
                                      child: Image.memory(
                                        fundraiser['logo'],
                                        width: 60,
                                        height: 60,
                                        fit: BoxFit.contain,
                                        errorBuilder: (context, error, stackTrace) {
                                          // Fallback to a default icon if image fails to load
                                          return Icon(
                                            Icons.image_not_supported,
                                            size: 60,
                                            color: Colors.grey,
                                          );
                                        },
                                      ),
                                    ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            fundraiser['title'] ?? '',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 20,
                                              color: Color(0xFF2B3674),
                                            ),
                                          ),
                                          Text(
                                            fundraiser['fullForm'] ?? '',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18,
                                              color: Color(0xFF2B3674),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8.0),
                                Text(
                                  fundraiser['description'] ?? '',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Color(0xFF2B3674),
                                  ),
                                ),
                                const SizedBox(height: 16.0),
                                ElevatedButton(
                                  onPressed: () => _showDonationPopup(fundraiser['_id']),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF2B3674),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(25.0),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24.0, vertical: 12.0,
                                    ),
                                  ),
                                  child: const Text(
                                    'Donate Now',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    )
                ],
              ),
            ),
          ),
        ],
      ),
    ),
    bottomNavigationBar: Footer(
      currentIndex: _currentIndex,
      onTap: (index) {
        setState(() {
          _currentIndex = index;
        });
      },
    ),
  );
}
}





import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/services/api_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _aadharController = TextEditingController();

  final TextEditingController _adminPhoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  bool _isAdminLoginMode = false;
  bool _isOtpSent = false;


  bool _isRegistrationMode = true;
  bool _isLoading = false;
  String? _fcmToken;

  @override
  void initState() {
    super.initState();
    setupPushNotification();
    Future.delayed(Duration.zero, () async {
      await _checkToken();
    });
  }

  Future<void> setupPushNotification() async {
    final fcm = FirebaseMessaging.instance;
    await fcm.requestPermission();
    _fcmToken = await fcm.getToken();
    if (_fcmToken != null) {
      print('FCM Token: $_fcmToken');
    }
  }

  Future<void> _checkToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('userToken');
    if (token != null) {
      Navigator.of(context).pushReplacementNamed('/home_screen');
    }
  }

  Future<void> _registerWithAadhar() async {
    if (!_validateInputs()) return;
    if (_fcmToken == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('fcm_token_not_found'.tr())),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await ApiService.registerWithAadhar(
        name: _nameController.text,
        email: _emailController.text,
        phoneNumber: _phoneNumberController.text,
        aadharNumber: _aadharController.text,
        fcmToken: _fcmToken!,
      );
      await _saveUserDataAndNavigate(response);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('registration_failed'.tr(args: [e.toString()]))),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loginWithAadhar() async {
    if (!_validateInputs(forLogin: true)) return;
    if (_fcmToken == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('fcm_token_not_found'.tr())),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await ApiService.loginWithAadhar(
        phoneNumber: _phoneNumberController.text,
        fcmToken: _fcmToken!,
      );
      await _saveUserDataAndNavigate(response);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('login_failed'.tr(args: [e.toString()]))),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loginAsAdmin() async {
    if (_adminPhoneController.text.length != 10 ||
        int.tryParse(_adminPhoneController.text) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('invalid_phone_number'.tr())),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Call adminLogin to trigger OTP
      await ApiService.adminLogin(
        phoneNumber: _adminPhoneController.text,
        fcmToken: _fcmToken ?? '',
      );
      setState(() => _isOtpSent = true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('otp_send_failed'.tr(args: [e.toString()]))),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submitAdminOtp() async {
  if (_otpController.text.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('enter_valid_otp'.tr())),
    );
    return;
  }

  setState(() => _isLoading = true);

  try {
    // Call API and log the full response for debugging
    final response = await ApiService.verifyAdminLogin(
      phoneNumber: _adminPhoneController.text,
      otp: _otpController.text,
      fcmToken: _fcmToken ?? '',
    );

    print('Response from server: $response'); // Log the raw response
    print('Response keys: ${response.keys}'); // Log keys for structure debugging

    // Save admin data and navigate
    await _saveAdminDataAndNavigate(response);
  } catch (e) {
    print('Error during OTP verification: $e'); // Log the error for debugging
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('otp_verification_failed'.tr(args: [e.toString()]))),
    );
  } finally {
    setState(() => _isLoading = false);
  }
}

  Future<void> _saveAdminDataAndNavigate(Map<String, dynamic> response) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Save admin data to SharedPreferences
      await prefs.setString('adminMobileNumber', response["loggedInUser"]['mobileNo']);
      await prefs.setString('adminFcmToken', response["loggedInUser"]['fcmToken']);
      await prefs.setString('adminUserId', response["loggedInUser"]['_id']);
      await prefs.setString('adminJwtToken', response['accessToken']);
      await prefs.setString('adminType', response["loggedInUser"]['type']);
      await prefs.setBool('isAdminLoggedIn', true);
      // Navigate to the admin home screen
      Navigator.of(context).pushReplacementNamed('/admin_home_screen');
    } catch (e) {
      // Handle errors gracefully and show a snackbar
      print('Error saving admin data: ${e.toString()}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('save_admin_data_failed'.tr(args: [e.toString()]))),
      );
    }
  }


  Future<void> _saveUserDataAndNavigate(Map<String, dynamic> response) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = response['createdUser'] ?? response['user'];
      if (userData == null || response['accessToken'] == null) {
        throw Exception('invalid_response'.tr());
      }

      await prefs.setString('userToken', response['accessToken']);
      await prefs.setString('userId', userData['_id'] ?? '');
      await prefs.setString('userName', userData['name'] ?? '');
      await prefs.setString('userEmail', userData['email'] ?? '');
      await prefs.setString('userPhoneNumber', userData['mobileNo'] ?? '');
      await prefs.setString('userAadharNumber', userData['aadharNo'] ?? '');
      await prefs.setString('userGender', userData['gender'] ?? '');
      await prefs.setString('userState', userData['state'] ?? '');
      await prefs.setBool('isLoggedIn', true);

      Navigator.of(context).pushReplacementNamed('/home_screen');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('save_user_data_failed'.tr(args: [e.toString()]))),
      );
    }
  }

  bool _validateInputs({bool forLogin = false}) {
    if (_phoneNumberController.text.length != 10 ||
        int.tryParse(_phoneNumberController.text) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('invalid_phone_number'.tr())),
      );
      return false;
    }

    if (!forLogin) {
      if (_aadharController.text.length != 12 ||
          int.tryParse(_aadharController.text) == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('invalid_aadhar_number'.tr())),
        );
        return false;
      }

      if (_nameController.text.isEmpty || _emailController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('all_fields_required'.tr())),
        );
        return false;
      }
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 60),
              Image.asset(
                'assets/images/NewLogo.png',
                height: 120,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 15),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[400]!, width: 1.5),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _isAdminLoginMode
                              ? 'admin'
                              : _isRegistrationMode
                                  ? 'register'
                                  : 'login',
                          items: [
                            DropdownMenuItem(value: 'register', child: Text('register'.tr())),
                            DropdownMenuItem(value: 'login', child: Text('login'.tr())),
                            DropdownMenuItem(value: 'admin', child: Text('Login As Admin'.tr())),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _isRegistrationMode = value == 'register';
                              _isAdminLoginMode = value == 'admin';
                              _isOtpSent = false; // Reset OTP state
                            });
                          },
                          isExpanded: true,
                          icon: const Icon(Icons.arrow_drop_down),
                          iconSize: 30,
                        ),

                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 15),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[400]!, width: 1.5),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: context.locale.languageCode,
                          items: [
                            DropdownMenuItem(value: 'en', child: Text('English')),
                            DropdownMenuItem(value: 'hi', child: Text('हिन्दी')),
                            DropdownMenuItem(value: 'mr', child: Text('मराठी')),
                            DropdownMenuItem(value: 'or', child: Text('ଓଡିଆ')),
                            DropdownMenuItem(value: 'bn', child: Text('বাংলা')),
                          ],
                          onChanged: (languageCode) {
                            if (languageCode != null) {
                              context.setLocale(Locale(languageCode));
                            }
                          },
                          isExpanded: true,
                          icon: const Icon(Icons.arrow_drop_down),
                          iconSize: 30,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (_isRegistrationMode)
                Column(
                  children: [
                    _buildTextField(
                      controller: _nameController,
                      label: 'name'.tr(),
                      icon: Icons.person,
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      controller: _emailController,
                      label: 'email'.tr(),
                      icon: Icons.email,
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(
                      controller: _aadharController,
                      label: 'aadhar_number'.tr(),
                      icon: Icons.credit_card,
                    ),
                  ],
                ),
              const SizedBox(height: 20),
              if (!_isAdminLoginMode)
                _buildTextField(
                  controller: _phoneNumberController,
                  label: 'phone_number'.tr(),
                  icon: Icons.phone,
                ),
              if (!_isAdminLoginMode)
                const SizedBox(height: 20),
              if (!_isAdminLoginMode)
                _buildButton(
                  label: _isRegistrationMode ? 'register'.tr() : 'login'.tr(),
                  onPressed: _isLoading
                      ? null
                      : (_isRegistrationMode ? _registerWithAadhar : _loginWithAadhar),
                ),
              if (_isAdminLoginMode) ...[
                if (!_isOtpSent)
                  Column(
                    children: [
                      _buildTextField(
                        controller: _adminPhoneController,
                        label: 'Mobile Number'.tr(),
                        icon: Icons.phone,
                      ),
                      const SizedBox(height: 20),
                      _buildButton(
                        label: 'Send OTP'.tr(),
                        onPressed: _isLoading ? null : _loginAsAdmin,
                      ),
                    ],
                  ),
                if (_isOtpSent)
                  Column(
                    children: [
                      _buildTextField(
                        controller: _otpController,
                        label: 'Enter OTP'.tr(),
                        icon: Icons.lock,
                      ),
                      const SizedBox(height: 20),
                      _buildButton(
                        label: 'Submit'.tr(),
                        onPressed: _isLoading ? null : _submitAdminOtp,
                      ),
                    ],
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF2B3674)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(25)),
        prefixIcon: Icon(icon, color: const Color(0xFF2B3674)),
      ),
      style: const TextStyle(color: Color(0xFF2B3674)),
    );
  }

  Widget _buildButton({
    required String label,
    required VoidCallback? onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        side: const BorderSide(color: Color(0xFF2B3674), width: 1.5),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF2B3674),
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

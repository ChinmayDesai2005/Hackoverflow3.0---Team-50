import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;


class ApiService {
  // Base API URL
  static const String _baseUrl = 'http://192.168.114.113:8000/v1/mobile';
  static const String _adminBaseUrl = 'http://192.168.114.113:8000/v1/adminmobile';
  static const String _webSocketUrl = 'http://192.168.114.113:8000'; // WebSocket server URL

  static IO.Socket? _socket;

  // Admin Login API
  static Future<Map<String, dynamic>> adminLogin({
    required String phoneNumber,
    required String fcmToken,
  }) async {
    final Uri url = Uri.parse('$_adminBaseUrl/login');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'mobileNo': phoneNumber,
        'fcmToken': fcmToken,
      }),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body); // Return response directly
    } else {
      throw Exception('Error: ${response.body}');
    }
  }

  // Verify Admin Login API
  static Future<Map<String, dynamic>> verifyAdminLogin({
    required String phoneNumber,
    required String otp,
    required String fcmToken,
  }) async {
    final Uri url = Uri.parse('$_adminBaseUrl/login-admin');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'mobileNo': phoneNumber,
        'otp': otp,
        'fcmToken': fcmToken,
      }),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body); // Return response directly
    } else {
      throw Exception('Error: ${response.body}');
    }
  }

  // Register with Aadhar API
  static Future<Map<String, dynamic>> registerWithAadhar({
    required String name,
    required String email,
    required String phoneNumber,
    required String aadharNumber,
    required String fcmToken,
  }) async {
    final Uri url = Uri.parse('$_baseUrl/verify-aadhar');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'name': name,
        'email': email,
        'mobileNo': phoneNumber,
        'aadharNo': aadharNumber,
        'fcmToken': fcmToken,
      }),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Error: ${response.body}');
    }
  }

  // Login with Aadhar API
  static Future<Map<String, dynamic>> loginWithAadhar({
    required String phoneNumber,
    required String fcmToken,
  }) async {
    final Uri url = Uri.parse('$_baseUrl/login-with-aadhar');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'mobileNo': phoneNumber,
        'fcmToken': fcmToken,
      }),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Error: ${response.body}');
    }
  }

  // In ApiService.fetchFundraisers() method
  static Future<List<Map<String, dynamic>>> fetchFundraisers() async {
    final Uri url = Uri.parse('$_baseUrl/get-fundraisers');
    final response = await http.get(
      url,
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true && data['fundraiser'] != null) {
        return List<Map<String, dynamic>>.from(data['fundraiser']).map((item) {
          Uint8List? logoBytes;
          if (item['logo'] != null) {
            try {
              // Check if logo is already a String (base64)
              if (item['logo'] is String) {
                // Remove data:image/*;base64, prefix if exists
                String base64Logo = item['logo'].contains(',') 
                    ? item['logo'].split(',').last 
                    : item['logo'];
                logoBytes = base64Decode(base64Logo);
              } else if (item['logo'] is Uint8List) {
                logoBytes = item['logo'];
              }
            } catch (e) {
              print('Error decoding logo: $e');
              logoBytes = null;
            }
          }

          return {
            'title': item['title'] ?? '',
            'fullForm': item['fullForm'] ?? '',
            'description': item['description'] ?? '',
            'logo': logoBytes,
            'goal': item['goal'] ?? 0,
            'amountCollected': item['amountCollected'] ?? 0,
            '_id': item['_id'] ?? '',
          };
        }).toList();
      } else {
        throw Exception('Invalid response structure: ${response.body}');
      }
    } else {
      throw Exception(
          'Failed to load fundraisers: ${response.statusCode} - ${response.body}');
    }
  }

  // Send SOS API
  static Future<Map<String, dynamic>> sendSos({
    required String name,
    required String email,
    required String location,
    required String emergencyType,
    required String mobileNumber,
  }) async {
    final Uri url = Uri.parse('$_baseUrl/send-sos');
    final prefs = await SharedPreferences.getInstance();
    final mobileNo = prefs.getString('userPhoneNumber') ?? '';

    if (mobileNo.isEmpty) {
      throw Exception('Mobile number not found in local storage');
    }

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'name': name,
        'email': email,
        'location': location,
        'emergencyType': emergencyType,
        'mobileNo': mobileNo,
      }),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to send SOS: ${response.body}');
    }
  }

  // Add Issue API
  static Future<Map<String, dynamic>> addIssue({
    required String photoBase64,
    required String title,
    required String description,
    required String emergencyType,
    required String location,
    required String userId,  // Keep this parameter
  }) async {
    final Uri url = Uri.parse('$_baseUrl/add-issue');
    
    // Remove the redundant userId fetch since it's passed as a parameter
    if (userId.isEmpty) {
      throw Exception('User ID is empty');
    }

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'photo': photoBase64,
        'title': title,
        'description': description,
        'emergencyType': emergencyType,
        'location': location,
        'userId': userId,  // Use the passed userId
      }),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to raise issue: ${response.body}');
    }
  }


//Fetch verified posts
static Future<List<Map<String, dynamic>>> fetchVerifiedPosts() async {
  final Uri url = Uri.parse('$_baseUrl/get-all-post');
  final response = await http.get(
    url,
    headers: {'Content-Type': 'application/json'},
  );

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    if (data['success'] == true && data['verified'] != null) {
      final posts = List<Map<String, dynamic>>.from(data['verified']);
      
      return posts.map((post) {
        Uint8List? imageBytes;
        if (post['imageUrl'] != null) {
          try {
            // Handle base64 image data
            if (post['imageUrl'].toString().startsWith('data:image')) {
              // Remove the data:image/xyz;base64, prefix
              final base64String = post['imageUrl'].toString().split(',').last;
              imageBytes = base64Decode(base64String);
            } else if (post['imageUrl'].toString().startsWith('/9j/')) {
              // Direct base64 string
              imageBytes = base64Decode(post['imageUrl']);
            }
          } catch (e) {
            print("Error decoding image: $e");
          }
        }
        
        return {
          ...post,
          'image': imageBytes,
        };
      }).toList();
    } else {
      throw Exception('Invalid response structure: ${response.body}');
    }
  } else {
    throw Exception(
        'Failed to fetch verified posts: ${response.statusCode} - ${response.body}');
  }
}
    // Fetch Personal Issues
  static Future<List<Map<String, dynamic>>> fetchPersonalIssues() async {
    final Uri url = Uri.parse('$_baseUrl/get-personal-issue');
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId') ?? '';

    if (userId.isEmpty) {
      throw Exception('User ID not found in local storage');
    }

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'userId': userId}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['personalIssues'] != null) {
        return List<Map<String, dynamic>>.from(data['personalIssues']).map((item) {
          Uint8List? photoBytes;
          if (item['photo'] != null) {
            try {
              photoBytes = base64Decode(item['photo']);
            } catch (e) {
              print("Error decoding photo: $e");
            }
          }
          return {
            '_id': item['_id'] ?? '',
            'photo': photoBytes,
            'title': item['title'] ?? '',
            'description': item['description'] ?? '',
            'emergencyType': item['emergencyType'] ?? '',
            'location': item['location'] ?? '',
            'currentStatus': item['currentStatus'] ?? 'unknown',
            'comment': item['comment'] ?? '',
          };
        }).toList();
      } else {
        throw Exception('No issues found for the user');
      }
    } else {
      throw Exception(
          'Failed to fetch personal issues: ${response.statusCode} - ${response.body}');
    }
  }

  // Add Admin Report Issue API
  static Future<Map<String, dynamic>> addAdminReportIssue({
    required String photoBase64,
    required String title,
    required String description,
  }) async {
    final Uri url = Uri.parse('$_adminBaseUrl/admin-add-issue');
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('adminUserId') ?? '';

    if (userId.isEmpty) {
      throw Exception('User ID not found in local storage');
    }

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'photo': photoBase64,
        'title': title,
        'description': description,
        'userId': userId,
      }),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to report issue: ${response.body}');
    }
  }


   /// Initialize WebSocket connection
  static Future<void> initWebSocket() async {
    if (_socket != null && _socket!.connected) {
      print("Socket.io is already connected.");
      return;
    }

    try {
      _socket = IO.io(
          _webSocketUrl,
          IO.OptionBuilder()
              .setTransports(['websocket']) // Use WebSocket transport explicitly
              .setExtraHeaders({'foo': 'bar'}) // Optional headers
              .enableAutoConnect()
              .build(),
        );
      _socket!.onConnect((_) {
        print("Connected to WebSocket server: ${_socket!.id}");
      });

      _socket!.onConnectError((error) {
        print("Socket.io connection error: $error");
      });

      _socket!.onDisconnect((_) {
        print("Disconnected from WebSocket server.");
      });

      // Optional: Listen for location updates from the server
      _socket!.on('locationUpdate', (data) {
        print("Location update received from server: $data");
      });

    } catch (error) {
      print("Failed to initialize Socket.io: $error");
    }
  }

  /// Send live location via WebSocket
  static Future<void> sendLiveLocation({
    required double latitude,
    required double longitude,
  }) async {
    if (_socket == null || !_socket!.connected) {
      print("Socket.io is not connected. Attempting to reconnect...");
      await initWebSocket();
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final adminUserId = prefs.getString('adminUserId') ?? 'unknown_user';

      final locationData = {
        'userId': adminUserId,
        'location': {
          'latitude': latitude,
          'longitude': longitude,
        },
      };

      _socket?.emit('updateLocation', locationData);
      print("Live location sent: $locationData");
    } catch (error) {
      print("Failed to send location via Socket.io: $error");
    }
  }

  /// Close WebSocket connection
  static void closeWebSocket() {
    _socket?.disconnect();
    _socket = null;
    print("Socket.io connection closed.");
  }
}


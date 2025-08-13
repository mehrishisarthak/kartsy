import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerce_shop/pages/admin_login.dart';
import 'package:ecommerce_shop/pages/order_screen.dart';
import 'package:ecommerce_shop/pages/settings.dart';
import 'package:ecommerce_shop/services/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, required this.userId});

  final String? userId;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // --- State Variables ---
  static const Map<String, List<String>> indianStatesAndCities = {
    'Andaman and Nicobar Islands': ['Port Blair', 'Garacharma', 'Bambooflat'],
    'Andhra Pradesh': ['Visakhapatnam', 'Vijayawada', 'Guntur', 'Tirupati', 'Nellore', 'Kurnool', 'Rajahmundry', 'Kakinada', 'Anantapur', 'Eluru', 'Kadapa', 'Chittoor', 'Srikakulam'],
    'Arunachal Pradesh': ['Itanagar', 'Naharlagun', 'Tawang', 'Ziro', 'Bomdila', 'Pasighat'],
    'Assam': ['Guwahati', 'Dibrugarh', 'Silchar', 'Jorhat', 'Tezpur', 'Nagaon', 'Tinsukia', 'Dispur'],
    'Bihar': ['Patna', 'Gaya', 'Bhagalpur', 'Muzaffarpur', 'Darbhanga', 'Purnia', 'Arrah', 'Begusarai'],
    'Chandigarh': ['Chandigarh'],
    'Chhattisgarh': ['Raipur', 'Bhilai', 'Bilaspur', 'Korba', 'Durg', 'Rajnandgaon', 'Jagdalpur'],
    'Dadra and Nagar Haveli and Daman and Diu': ['Daman', 'Diu', 'Silvassa', 'Amli'],
    'Delhi': ['New Delhi', 'Delhi', 'Noida', 'Gurugram', 'Faridabad', 'Ghaziabad'],
    'Goa': ['Panaji', 'Margao', 'Vasco da Gama', 'Mapusa', 'Ponda'],
    'Gujarat': ['Ahmedabad', 'Surat', 'Vadodara', 'Rajkot', 'Gandhinagar', 'Bhavnagar', 'Jamnagar', 'Junagadh'],
    'Haryana': ['Faridabad', 'Gurugram', 'Panipat', 'Ambala', 'Hisar', 'Rohtak', 'Karnal', 'Sonipat'],
    'Himachal Pradesh': ['Shimla', 'Manali', 'Dharamshala', 'Kullu', 'Solan', 'Mandi', 'Palampur'],
    'Jammu and Kashmir': ['Srinagar', 'Jammu', 'Anantnag', 'Baramulla', 'Udhampur', 'Kathua', 'Sopore'],
    'Jharkhand': ['Ranchi', 'Jamshedpur', 'Dhanbad', 'Bokaro Steel City', 'Deoghar', 'Hazaribagh'],
    'Karnataka': ['Bengaluru', 'Mysuru', 'Hubli-Dharwad', 'Mangaluru', 'Belagavi', 'Ballari', 'Shivamogga', 'Udupi'],
    'Kerala': ['Thiruvananthapuram', 'Kochi', 'Kozhikode', 'Thrissur', 'Alappuzha', 'Kollam', 'Kannur', 'Palakkad'],
    'Ladakh': ['Leh', 'Kargil'],
    'Lakshadweep': ['Kavaratti', 'Agatti', 'Minicoy', 'Andrott'],
    'Madhya Pradesh': ['Indore', 'Bhopal', 'Jabalpur', 'Gwalior', 'Ujjain', 'Sagar', 'Rewa', 'Satna'],
    'Maharashtra': ['Mumbai', 'Pune', 'Nagpur', 'Nashik', 'Aurangabad', 'Thane', 'Solapur', 'Kolhapur'],
    'Manipur': ['Imphal', 'Bishnupur', 'Thoubal', 'Churachandpur'],
    'Meghalaya': ['Shillong', 'Cherrapunji', 'Tura', 'Jowai'],
    'Mizoram': ['Aizawl', 'Lunglei', 'Champhai'],
    'Nagaland': ['Kohima', 'Dimapur', 'Mokokchung', 'Wokha'],
    'Odisha': ['Bhubaneswar', 'Cuttack', 'Rourkela', 'Puri', 'Sambalpur', 'Berhampur', 'Balasore'],
    'Puducherry': ['Puducherry', 'Karaikal', 'Mahe', 'Yanam'],
    'Punjab': ['Ludhiana', 'Amritsar', 'Jalandhar', 'Patiala', 'Bathinda', 'Mohali', 'Hoshiarpur'],
    'Rajasthan': ['Jaipur', 'Jodhpur', 'Udaipur', 'Kota', 'Ajmer', 'Bikaner', 'Alwar', 'Bhilwara'],
    'Sikkim': ['Gangtok', 'Pelling', 'Lachung', 'Namchi'],
    'Tamil Nadu': ['Chennai', 'Coimbatore', 'Madurai', 'Tiruchirappalli', 'Salem', 'Tirunelveli', 'Erode', 'Vellore'],
    'Telangana': ['Hyderabad', 'Warangal', 'Nizamabad', 'Karimnagar', 'Ramagundam', 'Khammam', 'Mahbubnagar'],
    'Tripura': ['Agartala', 'Udaipur', 'Dharmanagar', 'Kailasahar'],
    'Uttar Pradesh': ['Lucknow', 'Kanpur', 'Ghaziabad', 'Agra', 'Varanasi', 'Meerut', 'Prayagraj', 'Bareilly', 'Aligarh', 'Moradabad'],
    'Uttarakhand': ['Dehradun', 'Haridwar', 'Roorkee', 'Nainital', 'Rishikesh', 'Haldwani', 'Kashipur'],
    'West Bengal': ['Kolkata', 'Asansol', 'Siliguri', 'Durgapur', 'Howrah', 'Darjeeling', 'Kharagpur', 'Haldia'],
  };

  final SharedPreferenceHelper _prefs = SharedPreferenceHelper();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Map<String, dynamic>? personData;
  File? _imageFile;
  bool _isLoading = false;

  String? _selectedState, _selectedCity;
  List<String> _cities = [];

  final TextEditingController _localAddressController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();

  // OTP and Phone Verification State
  bool _isPhoneVerified = false;
  String? _verificationId;
  String _verifiedPhoneNumber = '';
  String? userID = '';

  @override
  void initState() {
    super.initState();
    userID = widget.userId;
    loadUserData();
    _mobileController.addListener(() {
      if (_isPhoneVerified && '+91${_mobileController.text.trim()}' != _verifiedPhoneNumber) {
        setState(() {
          _isPhoneVerified = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _localAddressController.dispose();
    _pincodeController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  /// Loads user data, prioritizing local cache before fetching from Firestore.
  Future<void> loadUserData() async {
    try {
      // Attempt to load from SharedPreferences first for a faster UI response
      final cachedAddress = await _prefs.getUserAddress();
      if (cachedAddress != null && mounted) {
        _updateAddressFields(cachedAddress);
      }

      final doc = await FirebaseFirestore.instance.collection('users').doc(userID).get();
      if (doc.exists && mounted) {
        final firestoreData = doc.data()!;
        setState(() {
          personData = firestoreData;
        });
        final address = firestoreData['Address'];
        if (address is Map<String, dynamic>) {
          _updateAddressFields(address);
        }
      }
    } catch (e) {
      // ignore: avoid_print
      print("Error loading user data: $e");
      if (mounted) _showErrorSnackBar("Failed to load user data");
    }
  }

  /// Helper to update state and controllers from an address map.
  void _updateAddressFields(Map<String, dynamic> address) {
    setState(() {
      _selectedState = address['state'];
      if (_selectedState != null) {
        _cities = indianStatesAndCities[_selectedState] ?? [];
      }
      _selectedCity = address['city'];
      _localAddressController.text = address['local'] ?? '';
      _pincodeController.text = address['pincode'] ?? '';
      final mobile = address['mobile'] ?? '';
      _mobileController.text = mobile.replaceFirst('+91', '');

      // Check if the stored number is verified
      final currentUser = _auth.currentUser;
      if (currentUser != null && currentUser.phoneNumber == mobile && mobile.isNotEmpty) {
        _isPhoneVerified = true;
        _verifiedPhoneNumber = mobile;
      }
    });
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked != null) {
      setState(() {
        _imageFile = File(picked.path);
      });
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Theme.of(context).colorScheme.error),
      );
    }
  }

  /// Checks if a phone number is already in use before sending an OTP.
  Future<void> _verifyPhoneNumber() async {
    if (_mobileController.text.trim().length != 10) {
      _showErrorSnackBar("Please enter a valid 10-digit mobile number.");
      return;
    }
    
    setState(() => _isLoading = true);

    try {
      final phoneNumber = '+91${_mobileController.text.trim()}';
      final currentUser = _auth.currentUser;

      // --- Check if phone number already exists ---
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('Address.mobile', isEqualTo: phoneNumber)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty && querySnapshot.docs.first.id != currentUser?.uid) {
        _showErrorSnackBar("Phone number is already in use by another account.");
        return;
      }
      // --- End of check ---

      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          try {
            await _auth.currentUser?.linkWithCredential(credential);
            if (mounted) {
              setState(() {
                _isPhoneVerified = true;
                _verifiedPhoneNumber = phoneNumber;
              });
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Phone number verified automatically!"), backgroundColor: Colors.green));
            }
          } catch (e) {
            if (mounted) {
              _showErrorSnackBar("Failed to link credential: ${e.toString()}");
            }
          } finally {
              if (mounted) setState(() => _isLoading = false);
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          if (mounted) {
            _showErrorSnackBar("Failed to verify phone number: ${e.message}");
          }
        },
        codeSent: (String verificationId, int? resendToken) {
          if (mounted) {
            setState(() {
              _verificationId = verificationId;
            });
            _showOTPEntryDialog();
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          if (mounted) {
            setState(() {
              _verificationId = verificationId;
            });
          }
        },
      );
    } catch (e) {
      if (mounted) _showErrorSnackBar("An error occurred. Please try again.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showOTPEntryDialog() {
    final otpController = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Enter OTP"),
        content: TextField(
          controller: otpController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          decoration: const InputDecoration(hintText: "******"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              if (_verificationId == null) return;
              try {
                PhoneAuthCredential credential = PhoneAuthProvider.credential(
                  verificationId: _verificationId!,
                  smsCode: otpController.text.trim(),
                );
                await _auth.currentUser?.linkWithCredential(credential);
                if (mounted) {
                  setState(() {
                    _isPhoneVerified = true;
                    _verifiedPhoneNumber = '+91${_mobileController.text.trim()}';
                  });
                  // ignore: use_build_context_synchronously
                  Navigator.pop(context);
                  // ignore: use_build_context_synchronously
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Phone number verified successfully!"), backgroundColor: Colors.green));
                }
              } catch (e) {
                _showErrorSnackBar("Invalid OTP. Please try again.");
              }
            },
            child: const Text("Submit"),
          ),
        ],
      ),
    );
  }

  /// Saves the profile to Firestore and caches the address locally.
  Future<void> _saveProfile() async {
    if (!_isPhoneVerified) {
      _showErrorSnackBar("Please verify your phone number before saving.");
      return;
    }
    if (_selectedState == null || _selectedCity == null || _localAddressController.text.trim().isEmpty || _pincodeController.text.trim().length != 6) {
      _showErrorSnackBar("Please fill all address fields correctly.");
      return;
    }
    
    setState(() => _isLoading = true);
    final userID = await _prefs.getUserID();
    if (userID == null) {
      setState(() => _isLoading = false);
      return;
    }

    String? imageUrl = personData?['Image'];

    try {
      if (_imageFile != null) {
        final storageRef = FirebaseStorage.instance.ref().child('profile_images').child('$userID.jpg');
        await storageRef.putFile(_imageFile!);
        imageUrl = await storageRef.getDownloadURL();
      }

      final structuredAddress = {
        'state': _selectedState,
        'city': _selectedCity,
        'local': _localAddressController.text.trim(),
        'pincode': _pincodeController.text.trim(),
        'mobile': _verifiedPhoneNumber,
      };

      // Perform saves concurrently
      await Future.wait([
        FirebaseFirestore.instance.collection('users').doc(userID).update({'Address': structuredAddress, 'Image': imageUrl}),
        _prefs.saveUserAddress(structuredAddress), // Save address to SharedPreferences
      ]);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated successfully!'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) _showErrorSnackBar('Failed to save profile.');
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; _imageFile = null; });
      }
      loadUserData();
    }
  }

  Widget _buildDropdown({required String hint, required String? value, required List<String> items, required void Function(String?)? onChanged}) {
    return DropdownButtonFormField<String>(
      value: value,
      hint: Text(hint, style: TextStyle(color: Colors.grey[600])),
      isExpanded: true,
      items: items.map((String item) => DropdownMenuItem<String>(value: item, child: Text(item, overflow: TextOverflow.ellipsis))).toList(),
      onChanged: onChanged,
      decoration: const InputDecoration(),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String hintText, required IconData icon, TextInputType keyboardType = TextInputType.text, List<TextInputFormatter>? inputFormatters, String? prefixText}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: Icon(icon, color: Theme.of(context).colorScheme.primary),
        prefixText: prefixText,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    ImageProvider imageProvider;
    if (_imageFile != null) {
      imageProvider = FileImage(_imageFile!);
    } else if (personData?['Image'] != null && personData!['Image'].toString().isNotEmpty) {
      imageProvider = NetworkImage(personData!['Image']);
    } else {
      imageProvider = const AssetImage('lib/assets/images/white.png');
    }

    return Scaffold(
      appBar: AppBar(
        actions: [
          // New orders button
          IconButton(
            icon: const Icon(Icons.shopping_bag_outlined),
            onPressed: () {
              if (widget.userId != null) {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => UserOrdersPage(userId: widget.userId!)),
                );
              } else {
                _showErrorSnackBar("User ID not found. Please log in.");
              }
            },
          ),
          IconButton(icon: const Icon(Icons.settings), onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const SettingsPage()))),
        ],
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
        title: const Text("Edit Profile"),
      ),
      body: personData == null
          ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(border: Border.all(color: colorScheme.primary, width: 3), shape: BoxShape.circle),
                          child: CircleAvatar(radius: 60, backgroundColor: colorScheme.surface, backgroundImage: imageProvider),
                        ),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(color: colorScheme.primary, shape: BoxShape.circle),
                          child: Icon(Icons.edit, color: colorScheme.onPrimary, size: 20),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(personData!['Name'] ?? 'No Name', style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text("Email: ${personData!['Email'] ?? 'Not Provided'}", style: textTheme.titleMedium?.copyWith(color: Colors.grey[700])),
                  const SizedBox(height: 30),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Contact & Address Info", style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 20),
                          TextFormField(
                            controller: _mobileController,
                            keyboardType: TextInputType.phone,
                            readOnly: _isPhoneVerified,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
                            decoration: InputDecoration(
                              hintText: "98765 43210",
                              prefixIcon: Icon(Icons.phone_android, color: colorScheme.primary),
                              prefixText: "+91 ",
                              fillColor: _isPhoneVerified ? Colors.grey.shade200.withAlpha(128) : null,
                              suffixIcon: TextButton(
                                onPressed: _isPhoneVerified ? null : _verifyPhoneNumber,
                                child: _isLoading
                                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                    : _isPhoneVerified 
                                        ? Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.check_circle, color: Colors.green), const SizedBox(width: 4), Text("Verified", style: TextStyle(color: colorScheme.onSurface))])
                                        : Text("Verify", style: TextStyle(color: colorScheme.primary)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildDropdown(
                            hint: "Select State",
                            value: _selectedState,
                            items: indianStatesAndCities.keys.toList(),
                            onChanged: (newValue) {
                              setState(() {
                                _selectedState = newValue;
                                _selectedCity = null;
                                _cities = indianStatesAndCities[newValue] ?? [];
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildDropdown(
                            hint: "Select City",
                            value: _selectedCity,
                            items: _cities,
                            onChanged: _selectedState == null ? null : (newValue) => setState(() => _selectedCity = newValue),
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(controller: _localAddressController, hintText: "House No, Street, Landmark", icon: Icons.location_on_outlined),
                          const SizedBox(height: 16),
                          _buildTextField(controller: _pincodeController, hintText: "Pincode", icon: Icons.pin_drop_outlined, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)]),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(25), blurRadius: 10, offset: const Offset(0, -4))],
        ),
        child: SizedBox(
          height: 55,
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminLoginPage())),
            child: const Text("Are you an admin? Tap here"),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isLoading ? null : _saveProfile,
        label: Text(_isLoading ? "Saving..." : "Save Profile"),
        icon: _isLoading
            ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: colorScheme.onPrimary, strokeWidth: 2))
            : const Icon(Icons.save),
      ),
    );
  }
}
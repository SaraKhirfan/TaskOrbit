import 'package:flutter/material.dart';
import 'package:task_orbit/screens/Product_Owner/my_projects_screen.dart';
import '../../widgets/TMBottomNav.dart';
import '../../widgets/drawer_header.dart';
import 'package:provider/provider.dart';
import '../../services/AuthService.dart';
import 'package:task_orbit/widgets/sm_app_bar.dart';
import 'package:task_orbit/widgets/sm_drawer.dart';

import '../../widgets/team_member_drawer.dart';

class TMProfileScreen extends StatefulWidget {
  const TMProfileScreen({Key? key}) : super(key: key);

  @override
  State<TMProfileScreen> createState() => _TMProfileScreenState();
}

class _TMProfileScreenState extends State<TMProfileScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 3;
  bool _isLoading = true;

  void _onItemTapped(int index) {
    if (index == 0) Navigator.pushNamed(context, '/teamMemberHome');
    if (index == 1) Navigator.pushNamed(context, '/teamMemberProjects');
    if (index == 2) Navigator.pushNamed(context, '/teamMemberWorkload');
    if (index == 3) Navigator.pushNamed(context, '/tmMyProfile');
  }

  static const Color primaryColor = Color(0xFF004AAD);

  // User data
  String _name = "";
  String _role = "";
  String _email = "";
  String _phoneNumber = "";
  String _birthDate = "";
  String _location = "";

  // Initialize controllers directly to avoid late initialization errors
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _birthDateController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  // Format date for display
  String _formatDateForDisplay(String dateString) {
    if (dateString.isEmpty) return 'Not set';

    try {
      // Parse the date string - handle both ISO format and simple date format
      DateTime dateTime;
      if (dateString.contains('T')) {
        // Format like "2003-01-12T00:00:00.000"
        dateTime = DateTime.parse(dateString);
      } else {
        // Format like "2003-01-12"
        List<String> parts = dateString.split('-');
        if (parts.length == 3) {
          dateTime = DateTime(
              int.parse(parts[0]),
              int.parse(parts[1]),
              int.parse(parts[2])
          );
        } else {
          return 'Invalid date';
        }
      }
      return "${dateTime.day} ${_getMonthName(dateTime.month)} ${dateTime.year}";
    } catch (e) {
      print('Error parsing date: $e');
      return 'Invalid date';
    }
  }
  // Get month name from month number
  String _getMonthName(int month) {
    const monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return monthNames[month - 1]; // month is 1-based, array is 0-based
  }


  // Load user profile data from Firebase
  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final userData = await authService.getUserProfile();

      if (userData != null && mounted) {
        setState(() {
          _name = userData['name'] ?? '';
          _role = userData['role'] ?? '';
          _email = userData['email'] ?? '';
          _phoneNumber = userData['phoneNumber'] ?? '';
          _birthDate = userData['birthDate'] ?? '';
          _location = userData['location'] ?? '';

          // Set initial values for controllers
          _emailController.text = _email;
          _phoneController.text = _phoneNumber;
          _birthDateController.text = _birthDate;
          _locationController.text = _location;

          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading user profile: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    _birthDateController.dispose();
    _locationController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Method to open the edit profile dialog
  void _showEditProfileDialog() {
    print("Dialog method called");
    // Reset controllers to current values to ensure they match profile data
    _emailController.text = _email;
    _phoneController.text = _phoneNumber;
    _birthDateController.text = _birthDate;
    _locationController.text = _location;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFFFDFDFD),
          title: Text(
            "Edit Profile Information",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF313131),
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Email field (disabled)
                _buildEditField(
                  controller: _emailController,
                  label: "Email",
                  icon: Icons.email,
                  enabled: false, // Make email field non-editable
                ),
                SizedBox(height: 16),
                _buildEditField(
                  controller: _phoneController,
                  label: "Phone Number",
                  icon: Icons.phone,
                  keyboardType: TextInputType.phone,
                ),
                SizedBox(height: 16),
                GestureDetector(
                  onTap: () => _selectDate(context),
                  child: AbsorbPointer(
                    child: _buildEditField(
                      controller: _birthDateController,
                      label: "Birth Date",
                      icon: Icons.calendar_today,
                    ),
                  ),
                ),
                SizedBox(height: 16),
                _buildEditField(
                  controller: _locationController,
                  label: "City/Country",
                  icon: Icons.location_on,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                "Cancel",
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                _updateUserProfile();
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF004AAD),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text("Save"),
            ),
          ],
        );
      },
    );
  }

  // Update user profile in Firebase
  Future<void> _updateUserProfile() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.updateUserProfile({
        'phoneNumber': _phoneController.text,
        'birthDate': _birthDateController.text,
        'location': _locationController.text,
      });

      // Update local state
      setState(() {
        _phoneNumber = _phoneController.text;
        _birthDate = _birthDateController.text;
        _location = _locationController.text;
        _isLoading = false;
      });

      // Show confirmation
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Profile updated successfully"),
          backgroundColor: Color(0xFF004AAD),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to update profile: ${e.toString()}"),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  // Helper method to build edit field
  Widget _buildEditField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool enabled = true,
  }) {
    return TextField(
      controller: controller,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Color(0xFF004AAD)), // Set label color here
        prefixIcon: Icon(icon, color: Color(0xFF004AAD)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Color(0xFF004AAD)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Color(0xFF004AAD), width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.5)),
        ),
        // This ensures the label stays blue when the field is focused
        floatingLabelStyle: TextStyle(color: Color(0xFF004AAD)),
      ),
      keyboardType: keyboardType,
      // This ensures the cursor and selection are also blue
      cursorColor: Color(0xFF004AAD),
    );
  }
  // Method to show date picker
  Future<void> _selectDate(BuildContext context) async {
    DateTime initialDate;
    try {
      // Try to parse existing date if available
      initialDate = _birthDate.isNotEmpty ? DateTime.parse(_birthDate) : DateTime.now();
    } catch (e) {
      // Fallback to current date if parsing fails
      initialDate = DateTime.now();
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF004AAD),
              onPrimary: Color(0xFFFDFDFD),
              surface: Color(0xFFFDFDFD),
              onSurface: Color(0xFF313131),
            ),
            dialogTheme: DialogTheme(backgroundColor: Color(0xFFFDFDFD)),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _birthDateController.text =
        "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  // Change password method
  Future<void> _changePassword() async {
    // Validate fields
    if (_currentPasswordController.text.isEmpty ||
        _newPasswordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("All password fields are required"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("New passwords don't match"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.changePassword(
        _currentPasswordController.text,
        _newPasswordController.text,
      );

      // Clear password fields
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();

      setState(() {
        _isLoading = false;
      });

      Navigator.of(context).pop(); // Close the dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Password changed successfully"),
          backgroundColor: Color(0xFF004AAD),
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to change password: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showChangePasswordDialog() {
    // Clear previous password entries
    _currentPasswordController.clear();
    _newPasswordController.clear();
    _confirmPasswordController.clear();

    // Reset visibility
    _obscureCurrentPassword = true;
    _obscureNewPassword = true;
    _obscureConfirmPassword = true;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFFFDFDFD),
              title: Text(
                "Change Password",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF313131),
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Current Password
                    TextField(
                      controller: _currentPasswordController,
                      obscureText: _obscureCurrentPassword,
                      decoration: InputDecoration(
                        labelText: "Current Password",
                        labelStyle: TextStyle(color: Color(0xFF004AAD)), // Add label color
                        floatingLabelStyle: TextStyle(color: Color(0xFF004AAD)), // Add floating label color
                        prefixIcon: Icon(Icons.lock, color: Color(0xFF004AAD)),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureCurrentPassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Color(0xFF004AAD),
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureCurrentPassword = !_obscureCurrentPassword;
                            });
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Color(0xFF004AAD)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: Color(0xFF004AAD),
                            width: 2,
                          ),
                        ),
                      ),
                      cursorColor: Color(0xFF004AAD), // Add cursor color
                    ),
                    SizedBox(height: 16),

                    // New Password with Strength Indicator
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: _newPasswordController,
                          obscureText: _obscureNewPassword,
                          onChanged: (value) {
                            // Trigger rebuild to update password strength indicator
                            setState(() {});
                          },
                          decoration: InputDecoration(
                            labelText: "New Password",
                            labelStyle: TextStyle(color: Color(0xFF004AAD)), // Add label color
                            floatingLabelStyle: TextStyle(color: Color(0xFF004AAD)), // Add floating label color
                            prefixIcon: Icon(
                              Icons.lock_outline,
                              color: Color(0xFF004AAD),
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureNewPassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: Color(0xFF004AAD),
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureNewPassword = !_obscureNewPassword;
                                });
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Color(0xFF004AAD)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: Color(0xFF004AAD),
                                width: 2,
                              ),
                            ),
                          ),
                          cursorColor: Color(0xFF004AAD), // Add cursor color
                        ),
                        if (_newPasswordController.text.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Row(
                              children: [
                                Container(
                                  width: 60,
                                  height: 4,
                                  color: _getPasswordStrengthColor(),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  _getPasswordStrength(),
                                  style: TextStyle(
                                    color: _getPasswordStrengthColor(),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 16),

                    // Confirm Password
                    TextField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      decoration: InputDecoration(
                        labelText: "Confirm Password",
                        labelStyle: TextStyle(color: Color(0xFF004AAD)), // Add label color
                        floatingLabelStyle: TextStyle(color: Color(0xFF004AAD)), // Add floating label color
                        prefixIcon: Icon(
                          Icons.lock_outline,
                          color: Color(0xFF004AAD),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Color(0xFF004AAD),
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword = !_obscureConfirmPassword;
                            });
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Color(0xFF004AAD)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: Color(0xFF004AAD),
                            width: 2,
                          ),
                        ),
                      ),
                      cursorColor: Color(0xFF004AAD), // Add cursor color
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    "Cancel",
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: _changePassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF004AAD),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text("Change Password"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _getPasswordStrength() {
    String password = _newPasswordController.text;
    if (password.isEmpty) return '';
    if (password.length < 6) return 'Weak';
    if (password.length < 8) return 'Medium';
    bool hasUppercase = password.contains(RegExp(r'[A-Z]'));
    bool hasDigits = password.contains(RegExp(r'[0-9]'));
    bool hasSpecialCharacters = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    if (hasUppercase && hasDigits && hasSpecialCharacters) return 'Strong';
    return 'Medium';
  }

  Color _getPasswordStrengthColor() {
    switch (_getPasswordStrength()) {
      case 'Weak':
        return Colors.red;
      case 'Medium':
        return Colors.orange;
      case 'Strong':
        return Colors.green;
      default:
        return Colors.transparent;
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFEDF1F3),
      appBar: SMAppBar(scaffoldKey: _scaffoldKey, title: "My Profile"),
      drawer: TeamMemberDrawer(selectedItem: 'My Profile'),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: MyProjectsScreen.primaryColor))
          : Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/MyProfile.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'My Profile',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF313131),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildProfileCard(),
                  const SizedBox(height: 24),
                  _buildInformationCard(),
                  const SizedBox(height: 24),
                  _buildPasswordCard(),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: TMBottomNav(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }

  Widget _buildProfileCard() {
    return Card(
      color: Color(0xFFFDFDFD),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Avatar and Name Section
            Row(
              children: [
                CircleAvatar(
                  radius: 35,
                  backgroundColor: MyProjectsScreen.primaryColor,
                  child: Text(
                    _name.isNotEmpty ? _name[0].toUpperCase() : "U",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF313131),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        _role,
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF666666),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        _email,
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF666666),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInformationCard() {
    return Card(
      elevation: 2,
      color: Color(0xFFFDFDFD),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Profile Information",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF313131),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.edit, color: MyProjectsScreen.primaryColor),
                  onPressed: _showEditProfileDialog,
                ),
              ],
            ),
            Divider(),
            SizedBox(height: 8),
            _buildInfoRow(Icons.email, "Email", _email),
            SizedBox(height: 16),
            _buildInfoRow(
              Icons.phone,
              "Phone Number",
              _phoneNumber.isNotEmpty ? _phoneNumber : "Not set",
            ),
            SizedBox(height: 16),
            _buildInfoRow(
              Icons.calendar_today,
              "Birth Date",
              _formatDateForDisplay(_birthDate).isNotEmpty ? _formatDateForDisplay(_birthDate) : "Not set",
            ),
            SizedBox(height: 16),
            _buildInfoRow(
              Icons.location_on,
              "Location",
              _location.isNotEmpty ? _location : "Not set",
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordCard() {
    return Card(
      color: Color(0xFFFDFDFD),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Security",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF313131),
              ),
            ),
            Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.lock, color: MyProjectsScreen.primaryColor),
              title: Text("Change Password"),
              trailing: Icon(Icons.arrow_forward_ios, size: 16),
              onTap: _showChangePasswordDialog,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: MyProjectsScreen.primaryColor, size: 20),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF666666),
                ),
              ),
              SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF313131),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
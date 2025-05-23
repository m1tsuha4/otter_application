import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// For image picking (optional, if you add avatar functionality)
// import 'package:image_picker/image_picker.dart';
// import 'dart:io';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final SupabaseClient supabase = Supabase.instance.client;
  final TextEditingController _nameController = TextEditingController();
  bool _isLoading = false;

  // Define colors for consistent styling
  final Color brownColor = const Color(0xFF5C2E00);
  final Color creamColor = const Color(0xFFF9F5E3); // For button text or light backgrounds
  final Color lightFillColor = Colors.white;
  final Color iconAndBorderColor = const Color(0xFF5C2E00);
  final Color hintTextColor = Colors.black54;
  final Color inputTextColor = Colors.black87;
  final Color appBarBackgroundColor = const Color(0xFFFAF5E4);
  final Color scaffoldBackgroundColor = Colors.white;

  // For avatar (optional)
  // String? _avatarUrl;
  // bool _isUploadingAvatar = false;

  User? get user => supabase.auth.currentUser;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final userMetadata = user?.userMetadata;
    if (userMetadata != null) {
      _nameController.text = userMetadata['display_name'] ?? '';
      // if (userMetadata['avatar_url'] != null) {
      //   _avatarUrl = userMetadata['avatar_url'] as String;
      // }
    }
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> updateProfile() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Display name cannot be empty.'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);
    final displayName = _nameController.text.trim();

    try {
      final response = await supabase.auth.updateUser(
        UserAttributes(
          data: {
            'display_name': displayName,
            // If you add avatar_url, update it here as well
            // 'avatar_url': _avatarUrl,
          },
        ),
      );

      if (mounted) {
        if (response.user != null) {
          // Refresh user data locally if needed, or rely on Supabase's currentUser update
          // _loadUserData(); // Call this to refresh display name immediately on screen
          setState(() {}); // Rebuild to show updated name at the top
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: const Text('Profile updated successfully'), backgroundColor: Colors.green[600]),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update profile: ${response.user == null ? "No user object returned" : "Unknown error"}'), backgroundColor: Colors.red),
          );
        }
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile: ${e.message}'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An unexpected error occurred: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // --- Optional Avatar Upload Functionality ---
  // Future<void> _uploadAvatar() async {
  //   final picker = ImagePicker();
  //   final imageFile = await picker.pickImage(
  //     source: ImageSource.gallery,
  //     imageQuality: 50, // Adjust quality as needed
  //     maxWidth: 500,    // Adjust size as needed
  //     maxHeight: 500,
  //   );

  //   if (imageFile == null || !mounted) {
  //     return;
  //   }

  //   setState(() => _isUploadingAvatar = true);

  //   try {
  //     final bytes = await File(imageFile.path).readAsBytes();
  //     final fileExt = imageFile.path.split('.').last;
  //     final fileName = '${user!.id}/profile.${DateTime.now().millisecondsSinceEpoch}.$fileExt';
  //     final filePath = fileName; // For public bucket, path is the name

  //     await supabase.storage.from('avatars').uploadBinary( // Ensure 'avatars' bucket exists and is public
  //       filePath,
  //       bytes,
  //       fileOptions: FileOptions(contentType: 'image/$fileExt', upsert: true),
  //     );

  //     // Get public URL
  //     final imageUrlResponse = supabase.storage.from('avatars').getPublicUrl(filePath);
  //     _avatarUrl = imageUrlResponse;

  //     // Update user metadata with the new avatar URL
  //     await supabase.auth.updateUser(
  //       UserAttributes(data: {'avatar_url': _avatarUrl})
  //     );

  //     if (mounted) {
  //       setState(() {});
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(content: Text('Avatar updated!'), backgroundColor: Colors.green[600]),
  //       );
  //     }
  //   } catch (e) {
  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(content: Text('Error uploading avatar: $e'), backgroundColor: Colors.red),
  //       );
  //     }
  //   } finally {
  //     if (mounted) {
  //       setState(() => _isUploadingAvatar = false);
  //     }
  //   }
  // }


  void logout(BuildContext context) async {
    try {
      await supabase.auth.signOut();
      if (mounted) { // Check if the widget is still in the tree
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error logging out: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _onTabTapped(int index) {
    if (!mounted) return;
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/home');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/history');
        break;
      case 2:
      // Already on Profile page
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = user?.email ?? 'No email';
    // Get display name from controller for immediate reflection after typing,
    // or fallback to user metadata if controller is empty (e.g., initial load before typing)
    final currentDisplayName = user?.userMetadata?['display_name'] ?? 'No name';
    final String avatarInitial = currentDisplayName.isNotEmpty ? currentDisplayName[0].toUpperCase() : (email.isNotEmpty ? email[0].toUpperCase() : '?');


    return Scaffold(
      backgroundColor: scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: appBarBackgroundColor,
        elevation: 0,
        title: const Text(
          'Profile',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch, // Make children stretch horizontally
          children: [
            Center(
              child: Column(
                children: [
                  // --- AVATAR SECTION ---
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      // _isUploadingAvatar
                      //   ? CircleAvatar(radius: 50, backgroundColor: Colors.grey[300], child: CircularProgressIndicator(color: brownColor))
                      //   : (_avatarUrl != null && _avatarUrl!.isNotEmpty)
                      //     ? CircleAvatar(
                      //         radius: 50,
                      //         backgroundColor: Colors.grey[300],
                      //         backgroundImage: NetworkImage(_avatarUrl!),
                      //       )
                      //     :
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: brownColor.withOpacity(0.15), // Lighter brown
                        child: Text(
                          avatarInitial,
                          style: TextStyle(fontSize: 40, color: brownColor, fontWeight: FontWeight.w500),
                        ),
                      ),
                      // IconButton( // Optional: Edit avatar button
                      //   icon: Icon(Icons.camera_alt, color: brownColor, size: 28),
                      //   style: IconButton.styleFrom(backgroundColor: Colors.white70, shape: CircleBorder()),
                      //   onPressed: _uploadAvatar,
                      //   tooltip: 'Change Avatar',
                      // ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    currentDisplayName, // Use currentDisplayName for immediate reflection
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: inputTextColor),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: TextStyle(color: hintTextColor, fontSize: 15),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 35),

            // --- UPDATE DISPLAY NAME SECTION ---
            Text(
              'Update Your Profile',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: brownColor),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: lightFillColor, // Use light fill color
                borderRadius: BorderRadius.circular(12.0), // Consistent with cards
                border: Border.all(color: iconAndBorderColor.withOpacity(0.5), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Display Name', // Label above TextField
                    style: TextStyle(fontWeight: FontWeight.w600, color: inputTextColor, fontSize: 15),
                  ),
                  const SizedBox(height: 8),
                  SizedBox( // Ensure consistent height for TextField
                    height: 58,
                    child: TextField(
                      controller: _nameController,
                      style: TextStyle(color: inputTextColor),
                      decoration: InputDecoration(
                        hintText: 'Enter your display name',
                        hintStyle: TextStyle(color: hintTextColor),
                        // prefixIcon: Icon(Icons.person_outline, color: iconAndBorderColor),
                        filled: true,
                        fillColor: scaffoldBackgroundColor, // Slightly different fill for textfield itself
                        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0), // Slightly less rounded than search
                          borderSide: BorderSide(color: iconAndBorderColor.withOpacity(0.7), width: 1.5),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide: BorderSide(color: iconAndBorderColor.withOpacity(0.7), width: 1.5),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide: BorderSide(color: iconAndBorderColor, width: 2.0),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50, // Consistent button height
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : updateProfile,
                      icon: _isLoading ? Container() : const Icon(Icons.save_outlined, size: 20),
                      label: _isLoading
                          ? SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 3, color: creamColor))
                          : const Text('Save Changes'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: brownColor,
                        foregroundColor: creamColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0), // Consistent radius
                        ),
                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // --- LOGOUT SECTION ---
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                icon: Icon(Icons.logout, color: Colors.red[700]),
                label: Text(
                  'Logout',
                  style: TextStyle(color: Colors.red[700], fontWeight: FontWeight.bold, fontSize: 16),
                ),
                onPressed: () => logout(context),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.red[300]!, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  backgroundColor: Colors.red.withOpacity(0.05),
                ),
              ),
            ),
            const SizedBox(height: 20), // Added some padding at the bottom
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2, // Current index for Profile
        backgroundColor: appBarBackgroundColor,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.black54,
        onTap: _onTabTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.history_outlined), activeIcon: Icon(Icons.history), label: 'History'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
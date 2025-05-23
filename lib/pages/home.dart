import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart'; // Not used in the provided snippet for Supabase
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

// ImageDetailPage class should be defined here or imported
// (Definition of ImageDetailPage from above)

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAF5E4),
        elevation: 0,
        title: const Text(
          'Home',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: const HomePageBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        backgroundColor: const Color(0xFFFAF5E4),
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.black54,
        onTap: (index) {
          switch (index) {
            case 0:
            // Already on Home
              break;
            case 1:
              Navigator.pushReplacementNamed(context, '/history');
              break;
            case 2:
              Navigator.pushReplacementNamed(context, '/profile');
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class HomePageBody extends StatefulWidget {
  const HomePageBody({super.key});

  @override
  State<HomePageBody> createState() => _HomePageBodyState();
}

class _HomePageBodyState extends State<HomePageBody> {
  String searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  // Define colors for consistent styling
  final Color brownColor = const Color(0xFF5C2C06);
  final Color cardBackgroundColor = Colors.white; // Or use const Color(0xFFFAF5E4) for cream
  final Color textOnCardColor = Colors.black87; // Main text color on the card
  final Color subTextOnCardColor = Colors.black54; // Subtitle text color on the card

  Future<List<Map<String, dynamic>>> fetchDetections() async {
    final response = await Supabase.instance.client
        .from('detections')
        .select()
        .order('timestamp', ascending: false)
        .limit(6); // Fetching only 6 for "Recent"

    // Error handling for response (Supabase specific, original code had a `response == null` check which is good)
    // if (response.error != null) { // Supabase newer SDKs might use response.error
    //   print('Error fetching detections: ${response.error!.message}');
    //   return [];
    // }
    // if (response.data == null) { // Or check data directly
    //    return [];
    // }
    // List<Map<String, dynamic>> detections = List<Map<String, dynamic>>.from(response.data as List);

    // Adapting to the original code's response handling:
    if (response == null) { // This check might depend on the Supabase client version and specific call
      print('Error fetching detections: Response was null');
      return [];
    }
    // Assuming response directly contains the list or has a property that does.
    // The original code implies `response` itself is the list after a successful call.
    List<Map<String, dynamic>> detections = List<Map<String, dynamic>>.from(response as List);


    if (searchQuery.isNotEmpty) {
      detections = detections.where((item) {
        final className = (item['class_name'] ?? '').toString().toLowerCase();
        return className.contains(searchQuery.toLowerCase());
      }).toList();
    }
    return detections;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) { // Check if widget is still in the tree
        setState(() {
          searchQuery = query;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final Color searchFillColor = Colors.white; // Or const Color(0xFFFAF5E4) if you prefer cream
    final Color searchBorderColor = brownColor;
    final Color searchIconColor = brownColor;
    final Color searchTextColor = Colors.black87;
    final Color searchHintColor = Colors.black54;

    return Column(
      children: [
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.asset(
              'assets/images/otter.jpeg', // Make sure this path is correct
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          // The Container that was previously brown is now removed.
          // We style the TextField directly.
          child: TextField(
            controller: _searchController,
            onChanged: onSearchChanged,
            style: TextStyle(color: searchTextColor), // Dark text color for input
            decoration: InputDecoration(
              hintText: 'Search recent detections...', // More descriptive hint
              hintStyle: TextStyle(color: searchHintColor), // Dark hint text color
              prefixIcon: Icon(Icons.search, color: searchIconColor), // Dark search icon
              filled: true, // Important: To make fillColor work
              fillColor: searchFillColor, // Light background color for the TextField
              contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20), // Adjust padding as needed
              border: OutlineInputBorder( // Default border
                borderRadius: BorderRadius.circular(20.0), // Matching image border radius
                borderSide: BorderSide(color: searchBorderColor, width: 1.5),
              ),
              enabledBorder: OutlineInputBorder( // Border when TextField is enabled but not focused
                borderRadius: BorderRadius.circular(20.0),
                borderSide: BorderSide(color: searchBorderColor, width: 1.5),
              ),
              focusedBorder: OutlineInputBorder( // Border when TextField is focused
                borderRadius: BorderRadius.circular(20.0),
                borderSide: BorderSide(color: searchBorderColor, width: 2.0), // Thicker or different color on focus
              ),
              // Optional: Add errorBorder, disabledBorder if needed
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Recent',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: fetchDetections(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator(color: brownColor));
              }

              if (snapshot.hasError) { // Added error handling for FutureBuilder
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                // If search is active, show "No results for..."
                if (searchQuery.isNotEmpty) {
                  return Center(child: Text("No results found for '$searchQuery'"));
                }
                return const Center(child: Text('No recent detections found.'));
              }

              final detections = snapshot.data!;

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // Added vertical padding
                itemCount: detections.length,
                itemBuilder: (context, index) {
                  final data = detections[index];
                  String date = 'Unknown date';

                  if (data['timestamp'] != null) {
                    try {
                      // Ensure timestamp is a string before parsing
                      final String timestampStr = data['timestamp'].toString();
                      final parsedDate = DateTime.parse(timestampStr).toLocal();
                      date = DateFormat('yyyy-MM-dd HH:mm').format(parsedDate);
                    } catch (e) {
                      // If parsing fails, use the original timestamp string
                      date = data['timestamp'].toString();
                      print("Error parsing date: $e, original value: ${data['timestamp']}");
                    }
                  }

                  return InkWell(
                    onTap: () {
                      final imageUrl = data['image_url'] as String?;
                      if (imageUrl != null && imageUrl.isNotEmpty) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ImageDetailPage(imageUrl: imageUrl),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Image not available for this item.')),
                        );
                      }
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(2), // Small padding for visual separation of border
                      decoration: BoxDecoration(
                        color: cardBackgroundColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: brownColor,
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            spreadRadius: 1,
                            blurRadius: 3,
                            offset: const Offset(0, 2), // changes position of shadow
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8), // Slightly smaller radius for leading image
                          child: Image.network(
                            data['image_url'] ?? '',
                            width: 70, // Adjusted size
                            height: 70, // Adjusted size
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              width: 70,
                              height: 70,
                              color: Colors.grey[200],
                              child: Icon(Icons.broken_image_outlined, color: Colors.grey[500]),
                            ),
                            loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                              if (loadingProgress == null) return child;
                              return SizedBox(
                                width: 70,
                                height: 70,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.0,
                                    valueColor: AlwaysStoppedAnimation<Color>(brownColor),
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                        : null,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        title: Text(
                          data['class_name'] ?? 'Unknown Class',
                          style: TextStyle(
                              color: textOnCardColor,
                              fontSize: 16,
                              fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'Date: $date',
                          style: TextStyle(color: subTextOnCardColor, fontSize: 13),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

// Definition of ImageDetailPage (as provided before)
// Ensure this class is defined in this file or imported from another file.
class ImageDetailPage extends StatelessWidget {
  final String imageUrl;

  const ImageDetailPage({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final Color appBarBackgroundColor = const Color(0xFFFAF5E4);
    final Color iconColor = const Color(0xFF5C2C06);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: appBarBackgroundColor,
        elevation: 0,
        title: const Text(
          'Image View',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        iconTheme: IconThemeData(color: iconColor),
        centerTitle: true,
      ),
      body: Center(
        child: InteractiveViewer(
          panEnabled: true,
          boundaryMargin: const EdgeInsets.all(20),
          minScale: 0.5,
          maxScale: 4,
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
            loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(iconColor),
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                      : null,
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, color: Colors.red, size: 50),
                    SizedBox(height: 10),
                    Text('Could not load image.', style: TextStyle(color: Colors.white)),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
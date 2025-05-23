import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

// Assuming ImageDetailPage is in a separate file or defined in home_page.dart and imported if needed
// For this example, I'll assume ImageDetailPage is accessible.
// If not, you'll need to copy its definition or import it.
// import 'path_to_image_detail_page.dart'; // Example import

// Re-defining ImageDetailPage here for completeness if it's not imported
// (Ideally, this would be in its own file or a shared utility file)
class ImageDetailPage extends StatelessWidget {
  final String imageUrl;

  const ImageDetailPage({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final Color appBarBackgroundColor = const Color(0xFFFAF5E4);
    final Color iconColor = const Color(0xFF5C2C06); // brownColor

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


class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  _HistoryPageState createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  void _onTabTapped(BuildContext context, int index) {
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/home');
        break;
      case 1:
      // Already on History page
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAF5E4),
        elevation: 0,
        title: const Text(
          'History',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: const HistoryPageBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1, // Set to 1 for History page
        backgroundColor: const Color(0xFFFAF5E4),
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.black54,
        onTap: (index) => _onTabTapped(context, index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class HistoryPageBody extends StatefulWidget {
  const HistoryPageBody({super.key});

  @override
  State<HistoryPageBody> createState() => _HistoryPageBodyState();
}

class _HistoryPageBodyState extends State<HistoryPageBody> {
  String searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  DateTime? _startDate;
  DateTime? _endDate;

  // Define colors for consistent styling (same as HomePage)
  final Color brownColor = const Color(0xFF5C2C06);
  final Color lightFillColor = Colors.white; // For search bar and date pickers
  final Color cardBackgroundColor = Colors.white; // Or const Color(0xFFFAF5E4) for cream cards
  final Color textOnCardColor = Colors.black87;
  final Color subTextOnCardColor = Colors.black54;
  final Color iconAndBorderColor = const Color(0xFF5C2C06);
  final Color hintTextColor = Colors.black54;
  final Color inputTextColor = Colors.black87;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if(mounted){
        setState(() {
          searchQuery = query;
        });
      }
    });
  }

  Future<List<Map<String, dynamic>>> fetchDetections() async {
    final supabase = Supabase.instance.client;

    // Base query
    var queryBuilder = supabase
        .from('detections')
        .select()
        .order('timestamp', ascending: false);
    // .limit(50); // Consider pagination if dataset is large

    // Apply date filters directly in Supabase query if possible for efficiency
    // This example filters after fetching, which is less efficient for large datasets.
    // For server-side filtering:
    // if (_startDate != null) {
    //   queryBuilder = queryBuilder.gte('timestamp', _startDate!.toIso8601String());
    // }
    // if (_endDate != null) {
    //   // Ensure endDate includes the whole day
    //   DateTime endOfDay = DateTime(_endDate!.year, _endDate!.month, _endDate!.day, 23, 59, 59);
    //   queryBuilder = queryBuilder.lte('timestamp', endOfDay.toIso8601String());
    // }


    final response = await queryBuilder;

    // Assuming response is List<Map<String, dynamic>> directly on success
    // Or handle response.data and response.error for newer Supabase client versions
    List<Map<String, dynamic>> detections = List<Map<String, dynamic>>.from(response as List? ?? []);


    // Client-side filtering (as per original logic, but server-side is better for performance)
    List<Map<String, dynamic>> filtered = detections.where((data) {
      final className = (data['class_name'] ?? '').toString().toLowerCase();
      final matchesSearch = searchQuery.isEmpty || className.contains(searchQuery.toLowerCase());

      bool matchesDate = true;
      if (data['timestamp'] != null) {
        try {
          final ts = DateTime.parse(data['timestamp'].toString());
          if (_startDate != null && ts.isBefore(_startDate!)) {
            matchesDate = false;
          }
          // Adjust endDate to be inclusive of the selected day up to its end
          if (_endDate != null && ts.isAfter(DateTime(_endDate!.year, _endDate!.month, _endDate!.day, 23, 59, 59))) {
            matchesDate = false;
          }
        } catch (e) {
          // Handle potential parsing error if timestamp is not a valid date string
          matchesDate = true; // Or false, depending on desired behavior for unparseable dates
        }
      } else if (_startDate != null || _endDate != null) {
        // If date filters are set but item has no timestamp, exclude it
        matchesDate = false;
      }
      return matchesSearch && matchesDate;
    }).toList();

    return filtered;
  }

  Future<void> _pickDate(BuildContext context, bool isStartDate) async {
    final DateTime initial = isStartDate
        ? (_startDate ?? DateTime.now())
        : (_endDate ?? _startDate ?? DateTime.now());
    final DateTime first = DateTime(2000);
    final DateTime last = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
      builder: (context, child) { // Optional: Theme the date picker
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: brownColor, // Header background color
              onPrimary: Colors.white, // Header text color
              onSurface: Colors.black, // Body text color
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      if (mounted) {
        setState(() {
          if (isStartDate) {
            _startDate = picked;
            // Optional: if end date is before new start date, clear or adjust end date
            if (_endDate != null && _endDate!.isBefore(_startDate!)) {
              _endDate = null;
            }
          } else {
            // Store end date as the end of that day for inclusive filtering
            _endDate = DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
            // Optional: if start date is after new end date, clear or adjust start date
            if (_startDate != null && _startDate!.isAfter(_endDate!)) {
              _startDate = null;
            }
          }
        });
      }
    }
  }


  Widget _buildDatePickerField(String hintText, DateTime? date, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 58, // Consistent height like other fields
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: lightFillColor,
            borderRadius: BorderRadius.circular(20.0), // Consistent radius
            border: Border.all(color: iconAndBorderColor, width: 1.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                date != null ? DateFormat('yyyy-MM-dd').format(date) : hintText,
                style: TextStyle(color: date != null ? inputTextColor : hintTextColor, fontSize: 16),
              ),
              Icon(Icons.calendar_today_outlined, color: iconAndBorderColor, size: 20),
            ],
          ),
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 16),
        // Date Pickers - Styled
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _buildDatePickerField('Start Date', _startDate, () => _pickDate(context, true)),
              const SizedBox(width: 12), // Spacing between date pickers
              _buildDatePickerField('End Date', _endDate, () => _pickDate(context, false)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Search Bar - Styled (same as HomePage)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SizedBox( // Ensure consistent height for searchbar
            height: 58,
            child: TextField(
              controller: _searchController,
              onChanged: onSearchChanged,
              style: TextStyle(color: inputTextColor),
              decoration: InputDecoration(
                hintText: 'Search by class name...',
                hintStyle: TextStyle(color: hintTextColor),
                prefixIcon: Icon(Icons.search, color: iconAndBorderColor),
                filled: true,
                fillColor: lightFillColor,
                contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20.0),
                  borderSide: BorderSide(color: iconAndBorderColor, width: 1.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20.0),
                  borderSide: BorderSide(color: iconAndBorderColor, width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20.0),
                  borderSide: BorderSide(color: iconAndBorderColor, width: 2.0),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // History List
        Expanded(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: fetchDetections(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator(color: brownColor));
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                String message = "No history found.";
                if (searchQuery.isNotEmpty || _startDate != null || _endDate != null) {
                  message = "No results for the applied filters.";
                }
                return Center(child: Text(message));
              }

              final detections = snapshot.data!;

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: detections.length,
                itemBuilder: (context, index) {
                  final data = detections[index];
                  final className = data['class_name'] ?? 'Unknown Class';
                  final timestampStr = data['timestamp']?.toString();
                  String date = 'Unknown Date';
                  if (timestampStr != null) {
                    try {
                      final parsedDate = DateTime.parse(timestampStr).toLocal();
                      date = DateFormat('yyyy-MM-dd HH:mm').format(parsedDate);
                    } catch (e) {
                      date = timestampStr; // Fallback to original string if parsing fails
                    }
                  }
                  final imageUrl = data['image_url'] as String?;

                  // Card Style (same as HomePage)
                  return InkWell(
                    onTap: () {
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
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: cardBackgroundColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: iconAndBorderColor,
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            spreadRadius: 1,
                            blurRadius: 3,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        leading: (imageUrl != null && imageUrl.isNotEmpty)
                            ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            imageUrl,
                            width: 70,
                            height: 70,
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
                        )
                            : Container( // Placeholder if no image URL
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.image_not_supported, color: Colors.grey[500], size: 30),
                        ),
                        title: Text(
                          className,
                          style: TextStyle(
                              color: textOnCardColor,
                              fontSize: 16,
                              fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          date,
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
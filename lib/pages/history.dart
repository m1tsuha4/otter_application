import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async'; // For Timer for debounce
import 'package:video_player/video_player.dart'; // For video playback
import 'package:chewie/chewie.dart'; // For video player UI


// =============================================================================
// VideoDetailPage: Widget to display the video event
// =============================================================================
class VideoDetailPage extends StatefulWidget {
  final String videoUrl;
  final String eventType;
  final String eventTime;
  final String trackId;
  final String duration;

  const VideoDetailPage({
    super.key,
    required this.videoUrl,
    required this.eventType,
    required this.eventTime,
    required this.trackId,
    required this.duration,
  });

  @override
  _VideoDetailPageState createState() => _VideoDetailPageState();
}

class _VideoDetailPageState extends State<VideoDetailPage> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _initializeVideoPlayer();
  }

  Future<void> _initializeVideoPlayer() async {
    try {
      _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
      await _videoPlayerController.initialize();
      print("DEBUG: Video initialized successfully: ${widget.videoUrl}");

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController,
        autoPlay: true,
        looping: false,
        errorBuilder: (context, errorMessage) {
          print("DEBUG: Chewie Error: $errorMessage");
          return Center(
            child: Text(
              errorMessage,
              style: const TextStyle(color: Colors.white),
            ),
          );
        },
      );
      print("DEBUG: Chewie controller initialized.");

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print("DEBUG ERROR: Error initializing video: $e");
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load video: $e';
      });
    }
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

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
          'Video Event',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        iconTheme: IconThemeData(color: iconColor),
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(iconColor)))
          : _errorMessage.isNotEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 50),
            const SizedBox(height: 10),
            Text(_errorMessage, style: const TextStyle(color: Colors.white)),
            const SizedBox(height: 10),
            Text('Video URL: ${widget.videoUrl}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
      )
          : Column(
        children: [
          Expanded(
            child: Center(
              child: _chewieController != null && _chewieController!.videoPlayerController.value.isInitialized
                  ? AspectRatio(
                aspectRatio: _chewieController!.aspectRatio ?? _videoPlayerController.value.aspectRatio,
                child: Chewie(controller: _chewieController!),
              )
                  : const CircularProgressIndicator(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Event Type: ${widget.eventType}', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Time: ${widget.eventTime}', style: const TextStyle(color: Colors.white70, fontSize: 16)),
                Text('Track ID: ${widget.trackId}', style: const TextStyle(color: Colors.white70, fontSize: 16)),
                Text('Duration: ${widget.duration} seconds', style: const TextStyle(color: Colors.white70, fontSize: 16)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// HistoryPage: Main page for history
// =============================================================================
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

// =============================================================================
// HistoryPageBody: Fetches and displays the list of video events with filters
// =============================================================================
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

  final Color brownColor = const Color(0xFF5C2C06);
  final Color lightFillColor = Colors.white;
  final Color cardBackgroundColor = Colors.white;
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
          // No GlobalKey needed, setState will rebuild FutureBuilder
        });
      }
    });
  }

  Future<List<Map<String, dynamic>>> fetchVideoEvents() async {
    final supabase = Supabase.instance.client;

    // Start with the base query as PostgrestFilterBuilder
    // This type supports gte, lte, ilike, and order.
    PostgrestFilterBuilder<List<Map<String, dynamic>>> query = supabase
        .from('otter_video_events')
        .select(); // .select() returns a builder that supports filters and order

    // Apply date filters
    if (_startDate != null) {
      query = query.gte('created_at', _startDate!.toIso8601String());
    }
    if (_endDate != null) {
      DateTime endOfDay = DateTime(_endDate!.year, _endDate!.month, _endDate!.day, 23, 59, 59);
      query = query.lte('created_at', endOfDay.toIso8601String());
    }

    // Apply search filter
    if (searchQuery.isNotEmpty) {
      query = query.ilike('event_type', '%${searchQuery.toLowerCase()}%');
    }

    // Now apply ordering and execute the query
    final response = await query.order('created_at', ascending: false);

    // Handle the response: newer Supabase client versions return List<Map<String, dynamic>> directly on success
    if (response is List) {
      return List<Map<String, dynamic>>.from(response);
    } else {
      // This case should ideally not happen for successful queries in newer clients,
      // but might catch errors or unexpected formats.
      print("Supabase fetchVideoEvents: Unexpected non-list response format: $response");
      return [];
    }
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
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: brownColor,
              onPrimary: Colors.white,
              onSurface: Colors.black,
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
            if (_endDate != null && _endDate!.isBefore(_startDate!)) {
              _endDate = null;
            }
          } else {
            _endDate = DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
            if (_startDate != null && _startDate!.isAfter(_endDate!)) {
              _startDate = null;
            }
          }
          // No GlobalKey needed, setState will rebuild FutureBuilder
        });
      }
    }
  }


  Widget _buildDatePickerField(String hintText, DateTime? date, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 58,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: lightFillColor,
            borderRadius: BorderRadius.circular(20.0),
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
        // Date Pickers - Restored
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _buildDatePickerField('Start Date', _startDate, () => _pickDate(context, true)),
              const SizedBox(width: 12),
              _buildDatePickerField('End Date', _endDate, () => _pickDate(context, false)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Search Bar - Restored
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SizedBox(
            height: 58,
            child: TextField(
              controller: _searchController,
              onChanged: onSearchChanged,
              style: TextStyle(color: inputTextColor),
              decoration: InputDecoration(
                hintText: 'Search by event type...',
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
        Expanded(
          // Removed GlobalKey, setState will rebuild FutureBuilder
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: fetchVideoEvents(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator(color: brownColor));
              }
              if (snapshot.hasError) {
                print("Error in FutureBuilder: ${snapshot.error}");
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                String message = "No video events found.";
                if (searchQuery.isNotEmpty || _startDate != null || _endDate != null) {
                  message = "No results for the applied filters.";
                }
                return Center(child: Text(message));
              }

              final videoEvents = snapshot.data!;

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: videoEvents.length,
                itemBuilder: (context, index) {
                  final data = videoEvents[index];
                  final eventType = data['event_type'] ?? 'Unknown Event';
                  final timestampStr = data['created_at']?.toString();
                  String date = 'Unknown Date';
                  if (timestampStr != null) {
                    try {
                      final parsedDate = DateTime.parse(timestampStr).toLocal();
                      date = DateFormat('yyyy-MM-dd HH:mm').format(parsedDate);
                    } catch (e) {
                      date = timestampStr;
                    }
                  }
                  final videoUrl = data['video_url'] as String?;
                  final trackId = data['track_id']?.toString() ?? 'N/A';
                  final duration = data['duration_sec']?.toStringAsFixed(1) ?? 'N/A';

                  final bboxX = data['bbox_snapshot_x'] as double?;
                  final bboxY = data['bbox_snapshot_y'] as double?;
                  final bboxW = data['bbox_snapshot_w'] as double?;
                  final bboxH = data['bbox_snapshot_h'] as double?;

                  return InkWell(
                    onTap: () {
                      if (videoUrl != null && videoUrl.isNotEmpty) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => VideoDetailPage(
                              videoUrl: videoUrl,
                              eventType: eventType,
                              eventTime: date,
                              trackId: trackId,
                              duration: duration,
                            ),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Video not available for this event.')),
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
                        leading: (videoUrl != null && videoUrl.isNotEmpty)
                            ? SizedBox(
                          width: 70,
                          height: 70,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              color: Colors.grey[200],
                              child: const Icon(Icons.videocam, color: Colors.blueGrey, size: 40),
                            ),
                          ),
                        )
                            : Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.video_camera_back_outlined, color: Colors.grey[500], size: 30),
                        ),
                        title: Text(
                          eventType,
                          style: TextStyle(
                              color: textOnCardColor,
                              fontSize: 16,
                              fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              date,
                              style: TextStyle(color: subTextOnCardColor, fontSize: 13),
                            ),
                            Text(
                              'ID: $trackId, Duration: $duration sec',
                              style: TextStyle(color: subTextOnCardColor, fontSize: 12),
                            ),
                          ],
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
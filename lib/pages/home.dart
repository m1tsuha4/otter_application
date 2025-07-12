import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async'; // Still needed for Timer for debounce
import 'package:supabase_flutter/supabase_flutter.dart';

// Video Player related imports (now directly in home.dart as VideoDetailPage is here)
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';


// =============================================================================
// VideoDetailPage: Widget to display the video event (DEFINED HERE IN HOME.DART)
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
        autoPlay: true, // Auto-play the video
        looping: false, // Don't loop the video
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
// HomePage: Main page for Home screen
// =============================================================================
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
        currentIndex: 0, // Set to 0 for Home page
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

// =============================================================================
// HomePageBody: Fetches and displays recent video events (NO FILTERS/SEARCH)
// =============================================================================
class HomePageBody extends StatefulWidget {
  const HomePageBody({super.key});

  @override
  State<HomePageBody> createState() => _HomePageBodyState();
}

class _HomePageBodyState extends State<HomePageBody> {
  String searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce; // Still keep Timer for debounce if onSearchChanged is present.

  final Color brownColor = const Color(0xFF5C2C06);
  final Color cardBackgroundColor = Colors.white;
  final Color textOnCardColor = Colors.black87;
  final Color subTextOnCardColor = Colors.black54;
  final Color searchFillColor = Colors.white;
  final Color searchBorderColor = const Color(0xFF5C2C06);
  final Color searchIconColor = const Color(0xFF5C2C06);
  final Color searchTextColor = Colors.black87;
  final Color searchHintColor = Colors.black54;


  // fetchRecentVideoEvents: Fetches only the 6 most recent video events
  Future<List<Map<String, dynamic>>> fetchRecentVideoEvents() async {
    final supabase = Supabase.instance.client;

    // Fetch directly, no filters applied here.
    // Order by 'created_at' descending and limit to 6.
    final response = await supabase
        .from('otter_video_events') // Fetch from your video events table
        .select()
        .order('created_at', ascending: false) // Order by most recent
        .limit(6); // Limit to 6 recent items

    if (response is List) {
      return List<Map<String, dynamic>>.from(response);
    } else {
      print("Supabase fetchRecentVideoEvents: Unexpected non-list response format: $response");
      return [];
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel(); // Dispose debounce if it was used.
    super.dispose();
  }

  void onSearchChanged(String query) {
    // This method is still defined but the TextField calling it is removed from UI.
    // It's benign to keep it or you can remove it if you're sure.
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          searchQuery = query;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
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
        // Removed: Search Bar UI entirely from this build method.
        // The TextField and its styling are gone.
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Recent Events',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: fetchRecentVideoEvents(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator(color: brownColor));
              }

              if (snapshot.hasError) {
                print("Error in FutureBuilder (HomePage): ${snapshot.error}");
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                // Simplified message as search is not active on this page.
                return const Center(child: Text('No recent video events found.'));
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

                  // Other video details are available in data, but only passed to VideoDetailPage
                  final trackId = data['track_id']?.toString() ?? 'N/A';
                  final duration = data['duration_sec']?.toStringAsFixed(1) ?? 'N/A';


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
                          color: brownColor,
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
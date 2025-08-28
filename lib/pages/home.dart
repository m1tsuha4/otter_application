import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../services/notification_service.dart';

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
      _videoPlayerController =
          VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
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
    final Color iconColor = const Color(0xFF5C2C06);

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
          ? Center(
          child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(iconColor)))
          : _errorMessage.isNotEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline,
                color: Colors.red, size: 50),
            const SizedBox(height: 10),
            Text(_errorMessage,
                style: const TextStyle(color: Colors.white)),
            const SizedBox(height: 10),
            Text('Video URL: ${widget.videoUrl}',
                style: const TextStyle(
                    color: Colors.white70, fontSize: 12)),
          ],
        ),
      )
          : Column(
        children: [
          Expanded(
            child: Center(
              child: _chewieController != null &&
                  _chewieController!
                      .videoPlayerController.value.isInitialized
                  ? AspectRatio(
                aspectRatio: _chewieController!.aspectRatio ??
                    _videoPlayerController.value.aspectRatio,
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
                Text('Event Type: ${widget.eventType}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Time: ${widget.eventTime}',
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 16)),
                Text('Track ID: ${widget.trackId}',
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 16)),
                Text('Duration: ${widget.duration} seconds',
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 16)),
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
        currentIndex: 0,
        backgroundColor: const Color(0xFFFAF5E4),
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.black54,
        onTap: (index) {
          switch (index) {
            case 0:
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
// HomePageBody: Fetches and displays recent video events
// =============================================================================
class HomePageBody extends StatefulWidget {
  const HomePageBody({super.key});

  @override
  State<HomePageBody> createState() => _HomePageBodyState();
}

class _HomePageBodyState extends State<HomePageBody> {
  final Stream<List<Map<String, dynamic>>> _eventsStream;
  int _lastKnownEventCount = -1;

  _HomePageBodyState()
      : _eventsStream = Supabase.instance.client
      .from('otter_video_events')
      .stream(primaryKey: ['id'])
      .order('created_at', ascending: false)
      .limit(6);

  @override
  void initState() {
    super.initState();
    _listenForInserts();
  }

  void _listenForInserts() {
    _eventsStream.listen((List<Map<String, dynamic>> data) {
      if (_lastKnownEventCount == -1) {
        _lastKnownEventCount = data.length;
        return;
      }
      if (data.length > _lastKnownEventCount) {
        print('New insert detected by stream.');
        final newEvent = data.first;
        final eventType = newEvent['event_type'] ?? 'Unknown Event';

        NotificationService().showNotification(
          DateTime.now().millisecondsSinceEpoch.remainder(100000),
          'New Event Detected!',
          'A new event has occurred: $eventType',
        );
      }
      _lastKnownEventCount = data.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final Color brownColor = const Color(0xFF5C2C06);
    final Color cardBackgroundColor = Colors.white;
    final Color textOnCardColor = Colors.black87;
    final Color subTextOnCardColor = Colors.black54;

    return Column(
      children: [
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.asset(
              'assets/images/otter.jpeg',
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 20),
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
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _eventsStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                    child: CircularProgressIndicator(color: brownColor));
              }

              if (snapshot.hasError) {
                print("Error in StreamBuilder (HomePage): ${snapshot.error}");
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(
                    child: Text('No recent video events found.'));
              }

              final videoEvents = snapshot.data!;

              return ListView.builder(
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: videoEvents.length,
                itemBuilder: (context, index) {
                  final data = videoEvents[index];
                  final eventType = data['event_type'] ?? 'Unknown Event';
                  final timestampStr = data['created_at']?.toString();
                  String date = 'Unknown Date';
                  if (timestampStr != null) {
                    try {
                      final parsedDate =
                      DateTime.parse(timestampStr).toLocal();
                      date = DateFormat('yyyy-MM-dd HH:mm').format(parsedDate);
                    } catch (e) {
                      date = timestampStr;
                    }
                  }
                  final videoUrl = data['video_url'] as String?;
                  final trackId = data['track_id']?.toString() ?? 'N/A';
                  final duration =
                      data['duration_sec']?.toStringAsFixed(1) ?? 'N/A';

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
                          const SnackBar(
                              content: Text('Video not available for this event.')),
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
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        leading: (videoUrl != null && videoUrl.isNotEmpty)
                            ? SizedBox(
                          width: 70,
                          height: 70,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              color: Colors.grey[200],
                              child: const Icon(Icons.videocam,
                                  color: Colors.blueGrey, size: 40),
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
                          child: Icon(Icons.video_camera_back_outlined,
                              color: Colors.grey[500], size: 30),
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
                          style: TextStyle(
                              color: subTextOnCardColor, fontSize: 13),
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
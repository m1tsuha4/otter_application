import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';

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
        // Already on history page, do nothing
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
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
          ),
          centerTitle: true,
          automaticallyImplyLeading: false,
        ),
        body: const HistoryPageBody(),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: 1,
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

    void _pickStartDate() async {
      final picked = await showDatePicker(
        context: context,
        initialDate: _startDate ?? DateTime.now(),
        firstDate: DateTime(2000),
        lastDate: DateTime.now(),
      );
      if (picked != null) {
        setState(() {
          _startDate = picked;
        });
      }
    }

    void _pickEndDate() async {
      final picked = await showDatePicker(
        context: context,
        initialDate: _endDate ?? DateTime.now(),
        firstDate: DateTime(2000),
        lastDate: DateTime.now(),
      );
      if (picked != null) {
        setState(() {
          _endDate = picked.add(const Duration(hours: 23, minutes: 59)); // include full day
        });
      }
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
        setState(() {
          searchQuery = query;
        });
      });
    }

    @override
    Widget build(BuildContext context) {
      return Column(
        children: [
          // Filter date
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _pickStartDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.brown),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _startDate != null
                            ? DateFormat('yyyy-MM-dd').format(_startDate!)
                            : 'Start Date',
                        style: const TextStyle(color: Colors.black),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: _pickEndDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.brown),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _endDate != null
                            ? DateFormat('yyyy-MM-dd').format(_endDate!)
                            : 'End Date',
                        style: const TextStyle(color: Colors.black),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF5C2C06),
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: TextField(
                controller: _searchController,
                onChanged: onSearchChanged,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Search',
                  hintStyle: TextStyle(color: Colors.white70),
                  contentPadding: EdgeInsets.symmetric(vertical: 14),
                  prefixIcon: Icon(Icons.search, color: Colors.white),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Stream section
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('detections')
                  .orderBy('timestamp', descending: true)
                  .limit(50)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData) {
                  return const Center(child: Text("No data found."));
                }

                List<DocumentSnapshot> detections = snapshot.data!.docs;

                detections = detections.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final className = (data['class_name'] ?? '').toString().toLowerCase();

                  // Filter by search
                  final matchesSearch = className.contains(searchQuery.toLowerCase());

                  // Filter by date
                  bool matchesDate = true;
                  if (_startDate != null || _endDate != null) {
                    if (data['timestamp'] is Timestamp) {
                      final ts = (data['timestamp'] as Timestamp).toDate();
                      if (_startDate != null && ts.isBefore(_startDate!)) matchesDate = false;
                      if (_endDate != null && ts.isAfter(_endDate!)) matchesDate = false;
                    } else {
                      matchesDate = false;
                    }
                  }

                  return matchesSearch && matchesDate;
                }).toList();


                if (searchQuery.isNotEmpty) {
                  detections = detections.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final className = (data['class_name'] ?? '').toString().toLowerCase();
                    return className.contains(searchQuery.toLowerCase());
                  }).toList();
                }

                if (detections.isEmpty) {
                  return const Center(child: Text('No results found'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: detections.length,
                  itemBuilder: (context, index) {
                    final data = detections[index].data() as Map<String, dynamic>;
                    String date = 'Unknown';
                    if (data['timestamp'] is Timestamp) {
                      DateTime dateTime = data['timestamp'].toDate();
                      date = DateFormat('yyyy-MM-dd HH:mm').format(dateTime);
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF5C2C06),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            data['image_url'] ?? '',
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              width: 80,
                              height: 80,
                              color: Colors.grey,
                              child: const Icon(Icons.image_not_supported),
                            ),
                          ),
                        ),
                        title: Text(
                          data['class_name'] ?? 'Unknown',
                          style: const TextStyle(color: Colors.white, fontSize: 16),
                        ),
                        subtitle: Text(
                          'Date : $date',
                          style: const TextStyle(color: Colors.white70),
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


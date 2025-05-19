import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'pages/login.dart';
import 'pages/register.dart';
import 'pages/home.dart';
import 'pages/profile.dart';
import 'pages/history.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://knplpprdnkqgbgfqpcoh.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtucGxwcHJkbmtxZ2JnZnFwY29oIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDc1NjAxNjMsImV4cCI6MjA2MzEzNjE2M30.M8D7it9pthcAUFp_8q0FdcekCUz1OyzIdMrNcyOy7f8',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Supabase Auth App',
      initialRoute: Supabase.instance.client.auth.currentUser == null ? '/login' : '/home',
      routes: {
        '/login': (context) => LoginPage(),
        '/register': (context) => RegisterPage(),
        '/home': (context) => HomePage(),
        '/profile': (context) => ProfilePage(),
        '/history': (context) => HistoryPage(),
      },
    );
  }
}

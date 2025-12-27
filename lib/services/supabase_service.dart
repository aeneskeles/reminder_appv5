import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final SupabaseService instance = SupabaseService._init();
  
  SupabaseService._init();

  Future<void> initialize() async {
    // TODO: Supabase URL ve anon key'inizi buraya ekleyin
    // Supabase projenizden alacağınız değerler:
    // URL: https://your-project.supabase.co
    // Anon Key: your-anon-key
    
    await Supabase.initialize(
      url: 'https://zehstwlqnwrhadteskdh.supabase.co', // Buraya Supabase URL'inizi ekleyin
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InplaHN0d2xxbndyaGFkdGVza2RoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjY4NTk4MDEsImV4cCI6MjA4MjQzNTgwMX0.B3Tp4GGKOvDPn_SBQ9iiVjYK61yp56zw-qCMs6xxykc', // Buraya Supabase anon key'inizi ekleyin
    );
  }

  SupabaseClient get client => Supabase.instance.client;

  User? get currentUser => client.auth.currentUser;

  bool get isLoggedIn => currentUser != null;

  Future<void> signOut() async {
    await client.auth.signOut();
  }
}


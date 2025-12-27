import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show OAuthProvider;
import '../models/user_profile.dart';
import 'supabase_service.dart';

class AuthService {
  static final AuthService instance = AuthService._init();
  final SupabaseService _supabase = SupabaseService.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  AuthService._init();

  User? get currentUser => _supabase.currentUser;

  bool get isLoggedIn => _supabase.isLoggedIn;

  Stream<AuthState> get authStateChanges => _supabase.client.auth.onAuthStateChange;

  // Google ile giriş
  Future<UserProfile?> signInWithGoogle() async {
    try {
      // Google Sign-In başlat
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        // Kullanıcı iptal etti
        return null;
      }

      // Google'dan authentication bilgilerini al
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Supabase'e Google token'ı ile giriş yap
      final response = await _supabase.client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: googleAuth.idToken!,
        accessToken: googleAuth.accessToken,
      );

      if (response.user == null) {
        throw Exception('Giriş başarısız');
      }

      // Kullanıcı profilini kaydet/güncelle
      final profile = await _saveUserProfile(
        response.user!,
        firstName: googleUser.displayName?.split(' ').first,
        lastName: googleUser.displayName?.split(' ').last,
        avatarUrl: googleUser.photoUrl,
      );

      return profile;
    } catch (e) {
      throw Exception('Google ile giriş başarısız: $e');
    }
  }

  // Email ve şifre ile kayıt
  Future<UserProfile?> signUpWithEmail({
    required String email,
    required String password,
    String? firstName,
    String? lastName,
  }) async {
    try {
      final response = await _supabase.client.auth.signUp(
        email: email,
        password: password,
        data: {
          'first_name': firstName,
          'last_name': lastName,
        },
      );

      if (response.user == null) {
        throw Exception('Kayıt başarısız');
      }

      // Kullanıcı profilini kaydet
      final profile = await _saveUserProfile(
        response.user!,
        firstName: firstName,
        lastName: lastName,
      );

      return profile;
    } catch (e) {
      throw Exception('Kayıt başarısız: $e');
    }
  }

  // Email ve şifre ile giriş
  Future<UserProfile?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw Exception('Giriş başarısız');
      }

      // Kullanıcı profilini getir
      return await _getUserProfile(response.user!.id);
    } catch (e) {
      throw Exception('Giriş başarısız: $e');
    }
  }

  // Çıkış yap
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _supabase.signOut();
  }

  // Kullanıcı profilini kaydet/güncelle
  Future<UserProfile> _saveUserProfile(
    User user, {
    String? firstName,
    String? lastName,
    String? avatarUrl,
  }) async {
    final profileData = {
      'id': user.id,
      'email': user.email ?? '',
      'first_name': firstName,
      'last_name': lastName,
      'avatar_url': avatarUrl,
      'updated_at': DateTime.now().toIso8601String(),
    };

    // Kullanıcı profilini veritabanına kaydet (upsert)
    await _supabase.client
        .from('user_profiles')
        .upsert(profileData, onConflict: 'id')
        .select()
        .single();

    return UserProfile(
      id: user.id,
      email: user.email ?? '',
      firstName: firstName,
      lastName: lastName,
      avatarUrl: avatarUrl,
      createdAt: DateTime.tryParse(user.createdAt ?? ''),
    );
  }

  // Kullanıcı profilini getir
  Future<UserProfile?> _getUserProfile(String userId) async {
    try {
      final response = await _supabase.client
          .from('user_profiles')
          .select()
          .eq('id', userId)
          .single();

      return UserProfile.fromMap(response as Map<String, dynamic>);
    } catch (e) {
      // Profil bulunamadıysa, kullanıcı bilgilerinden oluştur
      final user = currentUser;
      if (user != null) {
        return UserProfile(
          id: user.id,
          email: user.email ?? '',
          createdAt: DateTime.tryParse(user.createdAt ?? ''),
        );
      }
      return null;
    }
  }

  // Mevcut kullanıcı profilini getir
  Future<UserProfile?> getCurrentUserProfile() async {
    final user = currentUser;
    if (user == null) return null;
    return await _getUserProfile(user.id);
  }
}


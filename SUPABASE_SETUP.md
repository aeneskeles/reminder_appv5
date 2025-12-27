# Supabase Kurulum Rehberi

## 1. Supabase Projesi Oluşturma

1. [Supabase](https://supabase.com/) sitesine gidin ve hesap oluşturun
2. Yeni bir proje oluşturun
3. Proje oluşturulduktan sonra:
   - **Settings** > **API** bölümünden **Project URL** ve **anon public key** bilgilerini kopyalayın
   - Bu bilgileri `lib/services/supabase_service.dart` dosyasına ekleyin

## 2. Supabase Service Yapılandırması

`lib/services/supabase_service.dart` dosyasını açın ve şu satırları güncelleyin:

```dart
await Supabase.initialize(
  url: 'YOUR_SUPABASE_URL', // Buraya Supabase URL'inizi ekleyin
  anonKey: 'YOUR_SUPABASE_ANON_KEY', // Buraya Supabase anon key'inizi ekleyin
);
```

## 3. Supabase'de Kullanıcı Profili Tablosu Oluşturma

Supabase Dashboard'da SQL Editor'ü açın ve şu SQL'i çalıştırın:

```sql
-- Kullanıcı profilleri tablosu oluştur
CREATE TABLE IF NOT EXISTS user_profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL,
  first_name TEXT,
  last_name TEXT,
  avatar_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- RLS (Row Level Security) politikalarını etkinleştir
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;

-- Kullanıcılar sadece kendi profillerini görebilir/düzenleyebilir
CREATE POLICY "Users can view own profile"
  ON user_profiles FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Users can update own profile"
  ON user_profiles FOR UPDATE
  USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile"
  ON user_profiles FOR INSERT
  WITH CHECK (auth.uid() = id);

-- updated_at için trigger oluştur
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_user_profiles_updated_at 
  BEFORE UPDATE ON user_profiles
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();
```

## 4. Google OAuth Yapılandırması (Opsiyonel)

Google Sign-In kullanmak için:

### Android:
1. [Google Cloud Console](https://console.cloud.google.com/)'da bir proje oluşturun
2. OAuth 2.0 Client ID oluşturun
3. Android için SHA-1 fingerprint ekleyin:
   ```bash
   keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
   ```
4. Supabase Dashboard > Authentication > Providers > Google:
   - Client ID ve Client Secret ekleyin
   - Redirect URL'leri yapılandırın

### iOS:
1. Google Cloud Console'da iOS Client ID oluşturun
2. Bundle ID'yi ekleyin
3. Supabase Dashboard'da iOS redirect URL'lerini yapılandırın

## 5. Paketleri Yükleme

Terminal'de şu komutu çalıştırın:

```bash
flutter pub get
```

## 6. Test Etme

Uygulamayı çalıştırın ve login ekranında:
- Email/Password ile kayıt olmayı deneyin
- Google ile giriş yapmayı deneyin (Google OAuth yapılandırıldıysa)

## Notlar

- Supabase URL ve Key bilgilerini **ASLA** version control'e commit etmeyin (git ignore'a ekleyin)
- Production için environment variables kullanın
- Google Sign-In için `google_sign_in` paketi kullanılmıştır, ancak Supabase'in kendi OAuth flow'u da kullanılabilir


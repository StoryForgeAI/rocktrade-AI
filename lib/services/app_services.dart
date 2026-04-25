import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as path;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/app_config.dart';
import '../models/app_models.dart';

final _random = Random();

class AuthService {
  AuthService(this._client);

  final SupabaseClient _client;

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signUp({
    required String email,
    required String password,
  }) async {
    await _client.auth.signUp(email: email, password: password);
  }

  Future<void> signInWithGoogle() async {
    await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: AppConfig.oauthRedirectTo,
    );
  }

  Future<void> signOut() => _client.auth.signOut();
}

class DashboardService {
  DashboardService(this._client);

  final SupabaseClient _client;

  Future<DashboardState> loadDashboard() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const AuthException('No active user session.');
    }

    final profileResponse = await _client
        .from('users')
        .select()
        .eq('id', user.id)
        .single();

    final subscriptionResponse = await _client
        .from('subscriptions')
        .select()
        .eq('user_id', user.id)
        .maybeSingle();

    final analysesResponse = await _client
        .from('analyses')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false)
        .limit(8);

    return DashboardState(
      profile: UserProfile.fromMap(profileResponse),
      subscription: subscriptionResponse == null
          ? null
          : SubscriptionInfo.fromMap(subscriptionResponse),
      analyses: (analysesResponse as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(AnalysisRecord.fromMap)
          .toList(),
    );
  }
}

class AnalysisService {
  AnalysisService(this._client);

  final SupabaseClient _client;

  Future<TradeAnalysis> uploadAndAnalyze({
    required Uint8List bytes,
    required String fileName,
    String? mimeType,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const AuthException('No active user session.');
    }

    final extension = path.extension(fileName).isEmpty
        ? '.png'
        : path.extension(fileName).toLowerCase();
    final generatedName =
        '${DateTime.now().millisecondsSinceEpoch}_${_random.nextInt(99999)}$extension';
    final storagePath = '${user.id}/$generatedName';

    await _client.storage.from('uploads').uploadBinary(
          storagePath,
          bytes,
          fileOptions: FileOptions(
            upsert: false,
            contentType: mimeType ?? lookupMimeType(fileName) ?? 'image/png',
          ),
        );

    final response = await _client.functions.invoke(
      'analyze-trade-image',
      body: {
        'storagePath': storagePath,
      },
    );

    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Invalid function response.');
    }

    final analysisMap = (data['analysis'] ?? data) as Map<String, dynamic>;
    return TradeAnalysis.fromMap(analysisMap);
  }
}

class BillingService {
  BillingService(this._client);

  final SupabaseClient _client;

  Future<void> launchCheckout(CheckoutProduct product) async {
    final response = await _client.functions.invoke(
      'create-checkout-session',
      body: {
        'mode': product.mode,
        'productId': product.metadataValue,
      },
    );

    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Invalid checkout response.');
    }

    final checkoutUrl = data['url'] as String?;
    if (checkoutUrl == null || checkoutUrl.isEmpty) {
      throw const FormatException('Checkout URL is missing.');
    }

    final launched = await launchUrl(
      Uri.parse(checkoutUrl),
      mode: LaunchMode.platformDefault,
    );

    if (!launched) {
      throw Exception('Could not open Stripe Checkout.');
    }
  }
}

class ImageSelection {
  const ImageSelection({
    required this.bytes,
    required this.fileName,
    required this.mimeType,
  });

  final Uint8List bytes;
  final String fileName;
  final String mimeType;
}

class PickerService {
  final ImagePicker _picker = ImagePicker();

  Future<ImageSelection?> pickImage() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 92,
      maxWidth: 2400,
      maxHeight: 2400,
    );

    if (file == null) {
      return null;
    }

    final bytes = await file.readAsBytes();
    return ImageSelection(
      bytes: bytes,
      fileName: file.name,
      mimeType: lookupMimeType(file.name) ?? 'image/png',
    );
  }
}

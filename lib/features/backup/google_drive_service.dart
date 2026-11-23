import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

/// ┌─────────────────────────────────────────────────────────────────┐
/// │  SETUP INSTRUCTIONS — Google Drive Backup                       │
/// │                                                                 │
/// │  1. Go to https://console.cloud.google.com                     │
/// │  2. Create a project (or select an existing one)                │
/// │  3. Enable the "Google Drive API" under APIs & Services         │
/// │  4. Under Credentials → Create OAuth 2.0 Client ID:            │
/// │     • Application type: Android                                 │
/// │     • Package name: com.example.sakuwashi (match your app)      │
/// │     • SHA-1 certificate fingerprint:                            │
/// │       Run: keytool -list -v -keystore ~/.android/debug.keystore │
/// │                   -alias androiddebugkey -storepass android      │
/// │  5. No API key or client secret is needed for Android OAuth     │
/// │  6. The google_sign_in plugin handles the OAuth flow natively   │
/// │                                                                 │
/// │  Scopes used: drive.file (access only files created by this app)│
/// └─────────────────────────────────────────────────────────────────┘

class GoogleDriveService {
  static const _folderName = 'Sakuwashi_Backup';

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [drive.DriveApi.driveFileScope],
  );

  /// Sign in and return the account, or null if cancelled.
  Future<GoogleSignInAccount?> signIn() async {
    try {
      var account = _googleSignIn.currentUser;
      account ??= await _googleSignIn.signInSilently();
      account ??= await _googleSignIn.signIn();
      return account;
    } catch (e) {
      rethrow;
    }
  }

  /// Sign out the current Google account.
  Future<void> signOut() async {
    await _googleSignIn.signOut();
  }

  /// Get an authenticated HTTP client for Drive API calls.
  Future<http.Client> _getClient() async {
    final account = _googleSignIn.currentUser;
    if (account == null) throw Exception('Not signed in');
    final headers = await account.authHeaders;
    return _GoogleAuthClient(headers);
  }

  /// Find or create the Sakuwashi_Backup folder and return its ID.
  Future<String> _getOrCreateFolder(drive.DriveApi driveApi) async {
    // Search for existing folder
    final query =
        "name = '$_folderName' and mimeType = 'application/vnd.google-apps.folder' and trashed = false";
    final result = await driveApi.files.list(q: query, spaces: 'drive');

    if (result.files != null && result.files!.isNotEmpty) {
      return result.files!.first.id!;
    }

    // Create folder
    final folder = drive.File()
      ..name = _folderName
      ..mimeType = 'application/vnd.google-apps.folder';
    final created = await driveApi.files.create(folder);
    return created.id!;
  }

  /// Upload a CSV backup to Google Drive.
  Future<void> backup(String csvContent) async {
    final client = await _getClient();
    final driveApi = drive.DriveApi(client);
    final folderId = await _getOrCreateFolder(driveApi);

    final timestamp = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
    final fileName = 'sakuwashi_backup_$timestamp.csv';

    final file = drive.File()
      ..name = fileName
      ..parents = [folderId];

    final media = drive.Media(
      Stream.value(utf8.encode(csvContent)),
      utf8.encode(csvContent).length,
    );

    await driveApi.files.create(file, uploadMedia: media);
  }

  /// List available backup files in the Sakuwashi_Backup folder.
  /// Returns a list of maps with 'id' and 'name' keys.
  Future<List<Map<String, String>>> listBackups() async {
    final client = await _getClient();
    final driveApi = drive.DriveApi(client);

    try {
      final folderId = await _getOrCreateFolder(driveApi);
      final query =
          "'$folderId' in parents and name contains 'sakuwashi_backup' and trashed = false";
      final result = await driveApi.files.list(
        q: query,
        spaces: 'drive',
        orderBy: 'createdTime desc',
      );

      return (result.files ?? [])
          .where((f) => f.id != null && f.name != null)
          .map((f) => {'id': f.id!, 'name': f.name!})
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Download a backup file by ID and return its content as a string.
  Future<String> downloadBackup(String fileId) async {
    final client = await _getClient();
    final driveApi = drive.DriveApi(client);

    final media = await driveApi.files.get(
      fileId,
      downloadOptions: drive.DownloadOptions.fullMedia,
    ) as drive.Media;

    final bytes = <int>[];
    await for (final chunk in media.stream) {
      bytes.addAll(chunk);
    }
    return utf8.decode(bytes);
  }
}

/// A simple authenticated HTTP client that injects Google auth headers.
class _GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _inner = http.Client();

  _GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _inner.send(request);
  }
}

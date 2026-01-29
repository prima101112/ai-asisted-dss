import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/decision_session.dart';

class FirebaseService {
  FirebaseFirestore? _cachedDb;
  String? _userId;

  FirebaseFirestore? get _db {
    try {
      _cachedDb ??= FirebaseFirestore.instance;
      return _cachedDb;
    } catch (_) {
      return null;
    }
  }

  /// Set the current user ID for data isolation
  void setUserId(String? userId) {
    _userId = userId;
  }

  /// Get the sessions collection path for the current user
  CollectionReference<Map<String, dynamic>>? _sessionsCollection() {
    final db = _db;
    if (db == null || _userId == null || _userId!.isEmpty) return null;
    return db.collection('users').doc(_userId).collection('sessions');
  }

  Future<void> saveSession(DecisionSession session) async {
    final sessions = _sessionsCollection();
    if (sessions == null) return;
    await sessions.doc(session.id).set(session.toJson());
  }

  Future<DecisionSession?> getSession(String id) async {
    final sessions = _sessionsCollection();
    if (sessions == null) return null;
    final doc = await sessions.doc(id).get();
    if (doc.exists) {
      return DecisionSession.fromJson(doc.data()!);
    }
    return null;
  }

  Stream<List<DecisionSession>> getSessions() {
    final sessions = _sessionsCollection();
    if (sessions == null) return Stream.value([]);
    return sessions
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => DecisionSession.fromJson(doc.data()))
              .toList(),
        );
  }

  /// Fetches the DeepSeek API key from Firestore.
  /// Suggested path: secrets/deepseek
  Future<String?> getDeepSeekApiKey() async {
    final db = _db;
    if (db == null) return null;
    final doc = await db.collection('config').doc('secrets').get();
    if (doc.exists) {
      return doc.data()?['deepseek_api_key'];
    }
    return null;
  }
}

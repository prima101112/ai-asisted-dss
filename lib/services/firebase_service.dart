import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/decision_session.dart';

class FirebaseService {
  FirebaseFirestore? _cachedDb;

  FirebaseFirestore? get _db {
    try {
      _cachedDb ??= FirebaseFirestore.instance;
      return _cachedDb;
    } catch (_) {
      return null;
    }
  }

  Future<void> saveSession(DecisionSession session) async {
    final db = _db;
    if (db == null) return;
    await db.collection('sessions').doc(session.id).set(session.toJson());
  }

  Future<DecisionSession?> getSession(String id) async {
    final db = _db;
    if (db == null) return null;
    final doc = await db.collection('sessions').doc(id).get();
    if (doc.exists) {
      return DecisionSession.fromJson(doc.data()!);
    }
    return null;
  }

  Stream<List<DecisionSession>> getSessions() {
    final db = _db;
    if (db == null) return Stream.value([]);
    return db
        .collection('sessions')
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

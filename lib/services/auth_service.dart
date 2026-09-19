import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();

  factory AuthService() {
    return _instance;
  }

  AuthService._internal();

  /// Test-only seam: builds a standalone (non-singleton) AuthService backed
  /// by a caller-provided FirebaseAuth (e.g. a mock), so tests can exercise
  /// real logic without touching the production Firebase singleton.
  AuthService.forFirebaseAuth(FirebaseAuth firebaseAuth)
      : _firebaseAuthOverride = firebaseAuth;

  FirebaseAuth? _firebaseAuthOverride;

  /// Resolves the real Firebase-backed singleton lazily, on first actual
  /// use, rather than eagerly in the constructor. This means simply
  /// constructing an `AuthService()` (e.g. via its own singleton factory, or
  /// as a default parameter deep in some other service's constructor) never
  /// requires Firebase to already be initialized.
  FirebaseAuth get _firebaseAuth => _firebaseAuthOverride ??= FirebaseAuth.instance;

  // Get current user
  User? get currentUser => _firebaseAuth.currentUser;

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  // Sign up with email and password
  Future<User?> signUpWithEmail(
    String email,
    String password,
    String name,
  ) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name
      await credential.user?.updateDisplayName(name);

      return credential.user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign in with email and password
  Future<User?> signInWithEmail(String email, String password) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign in anonymously
  Future<User?> signInAnonymously() async {
    try {
      final credential = await _firebaseAuth.signInAnonymously();
      return credential.user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Get ID token
  Future<String?> getIdToken() async {
    try {
      return await currentUser?.getIdToken();
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Handle auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'パスワードが弱すぎます';
      case 'email-already-in-use':
        return 'このメールアドレスは既に使用されています';
      case 'invalid-email':
        return 'メールアドレスが無効です';
      case 'user-not-found':
        return 'ユーザーが見つかりません';
      case 'wrong-password':
        return 'パスワードが間違っています';
      default:
        return 'エラーが発生しました: ${e.message}';
    }
  }
}

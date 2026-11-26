import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

enum UserRole { staff, student }

@immutable
class AuthUser {
  const AuthUser({
    required this.uid,
    required this.email,
    this.displayName,
    this.role = UserRole.staff,
  });

  final String uid;
  final String email;
  final String? displayName;
  final UserRole role;

  bool get isStaff => role == UserRole.staff;
  bool get isStudent => role == UserRole.student;
}

@immutable
class AllowedStaffEmail {
  const AllowedStaffEmail({
    required this.email,
    this.addedBy = '',
    this.addedAt,
  });

  final String email;
  final String addedBy;
  final DateTime? addedAt;
}

class AuthFailureException implements Exception {
  const AuthFailureException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Authentication abstraction:
/// - In Cloud Mode: Google Sign-In checks `allowed_users/{email}`.
///   Whitelisted emails enter the Staff Workspace; any other Google user enters
///   the Student Portal cleanly with scoped read/homework permissions.
/// - In Demo Mode: instant local staff access without login.
abstract class AuthRepository {
  bool get isSignInRequired;
  Stream<AuthUser?> watchAuthState();
  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  });
  Future<void> signInWithGoogle({bool requireStaff = false});
  Future<void> signOut();

  Stream<List<AllowedStaffEmail>> watchAllowedEmails();
  Future<void> addAllowedEmail(String email);
  Future<void> removeAllowedEmail(String email);
}

class DemoAuthRepository implements AuthRepository {
  final _emailsCtrl = StreamController<List<AllowedStaffEmail>>.broadcast();
  final List<AllowedStaffEmail> _emails = [
    AllowedStaffEmail(
      email: 'staff@theword.center',
      addedBy: 'system',
      addedAt: DateTime(2026, 1, 1),
    ),
  ];

  @override
  bool get isSignInRequired => false;

  @override
  Stream<AuthUser?> watchAuthState() => Stream.value(
        const AuthUser(
          uid: 'demo-staff',
          email: 'staff@theword.center',
          displayName: 'Demo Staff',
          role: UserRole.staff,
        ),
      );

  @override
  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {}

  @override
  Future<void> signInWithGoogle({bool requireStaff = false}) async {}

  @override
  Future<void> signOut() async {}

  @override
  Stream<List<AllowedStaffEmail>> watchAllowedEmails() {
    return Stream<List<AllowedStaffEmail>>.multi((controller) {
      controller.add(List.unmodifiable(_emails));
      final sub = _emailsCtrl.stream.listen(
        controller.add,
        onError: controller.addError,
        onDone: controller.close,
      );
      controller.onCancel = sub.cancel;
    });
  }

  @override
  Future<void> addAllowedEmail(String email) async {
    final normalized = email.trim().toLowerCase();
    if (normalized.isEmpty || _emails.any((e) => e.email == normalized)) return;
    _emails.add(
      AllowedStaffEmail(
        email: normalized,
        addedBy: 'staff@theword.center',
        addedAt: DateTime.now(),
      ),
    );
    _emailsCtrl.add(List.unmodifiable(_emails));
  }

  @override
  Future<void> removeAllowedEmail(String email) async {
    final normalized = email.trim().toLowerCase();
    _emails.removeWhere((e) => e.email == normalized);
    _emailsCtrl.add(List.unmodifiable(_emails));
  }
}

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  @override
  bool get isSignInRequired => true;

  @override
  Stream<AuthUser?> watchAuthState() {
    return _auth.authStateChanges().asyncMap((user) async {
      if (user == null) return null;
      final email = (user.email ?? '').trim().toLowerCase();
      if (email.isEmpty) {
        await _auth.signOut();
        return null;
      }
      final isStaff = await _isEmailAllowed(email);
      return AuthUser(
        uid: user.uid,
        email: email,
        displayName: user.displayName,
        role: isStaff ? UserRole.staff : UserRole.student,
      );
    });
  }

  Future<bool> _isEmailAllowed(String email) async {
    try {
      final doc =
          await _firestore.collection('allowed_users').doc(email).get();
      return doc.exists;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final signedEmail = (cred.user?.email ?? '').trim().toLowerCase();
      if (signedEmail.isEmpty || !await _isEmailAllowed(signedEmail)) {
        await _auth.signOut();
        throw const AuthFailureException(
          'Access denied: this email is not on the authorized staff list.',
        );
      }
    } on AuthFailureException {
      rethrow;
    } on FirebaseAuthException catch (e) {
      throw AuthFailureException(_mapFirebaseAuthError(e));
    } catch (_) {
      throw const AuthFailureException(
        'Unable to sign in right now. Please try again.',
      );
    }
  }

  @override
  Future<void> signInWithGoogle({bool requireStaff = false}) async {
    try {
      final provider = GoogleAuthProvider()
        ..setCustomParameters({'prompt': 'select_account'});
      final cred = kIsWeb
          ? await _auth.signInWithPopup(provider)
          : await _auth.signInWithProvider(provider);
      final signedEmail = (cred.user?.email ?? '').trim().toLowerCase();
      if (signedEmail.isEmpty) {
        await _auth.signOut();
        throw const AuthFailureException(
          'Your Google account does not provide an email address.',
        );
      }
      final isStaff = await _isEmailAllowed(signedEmail);
      if (requireStaff && !isStaff) {
        await _auth.signOut();
        throw const AuthFailureException(
          'This account is not in the staff list. Use "Student Portal" below or ask an administrator to invite your email.',
        );
      }
    } on AuthFailureException {
      rethrow;
    } on FirebaseAuthException catch (e) {
      throw AuthFailureException(_mapFirebaseAuthError(e));
    } catch (_) {
      throw const AuthFailureException(
        'Google sign-in was canceled or failed. Please try again.',
      );
    }
  }

  @override
  Future<void> signOut() => _auth.signOut();

  @override
  Stream<List<AllowedStaffEmail>> watchAllowedEmails() {
    return _firestore.collection('allowed_users').snapshots().map((snap) {
      final list = snap.docs.map((doc) {
        final data = doc.data();
        final rawAddedAt = data['addedAt'];
        DateTime? addedAt;
        if (rawAddedAt is Timestamp) {
          addedAt = rawAddedAt.toDate();
        }
        return AllowedStaffEmail(
          email: doc.id,
          addedBy: data['addedBy'] as String? ?? '',
          addedAt: addedAt,
        );
      }).toList()
        ..sort((a, b) => a.email.compareTo(b.email));
      return List.unmodifiable(list);
    });
  }

  @override
  Future<void> addAllowedEmail(String email) async {
    final normalized = email.trim().toLowerCase();
    if (normalized.isEmpty) return;
    final currentEmail = (_auth.currentUser?.email ?? '').trim().toLowerCase();
    await _firestore.collection('allowed_users').doc(normalized).set({
      'email': normalized,
      'addedBy': currentEmail,
      'addedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Future<void> removeAllowedEmail(String email) async {
    final normalized = email.trim().toLowerCase();
    if (normalized.isEmpty) return;
    await _firestore.collection('allowed_users').doc(normalized).delete();
  }

  String _mapFirebaseAuthError(FirebaseAuthException e) {
    return switch (e.code) {
      'invalid-email' => 'Please enter a valid email address.',
      'user-disabled' => 'This account has been disabled.',
      'user-not-found' ||
      'wrong-password' ||
      'invalid-credential' =>
        'Invalid email or password.',
      'too-many-requests' =>
        'Too many attempts. Please wait a moment and try again.',
      'network-request-failed' =>
        'Network error. Check your internet connection.',
      _ => e.message ?? 'Sign-in failed (${e.code}).',
    };
  }
}

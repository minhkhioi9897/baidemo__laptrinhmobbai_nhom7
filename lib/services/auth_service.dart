import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notes_service.dart';
import 'journal_service.dart';

class UserAccount {
  final String name;
  final String email;
  final String password;
  final bool isPro;
  final String? avatarPath;

  UserAccount({
    required this.name,
    required this.email,
    required this.password,
    this.isPro = false,
    this.avatarPath,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'email': email,
        'password': password,
        'isPro': isPro,
        'avatarPath': avatarPath,
        'updatedAt': DateTime.now().toIso8601String(),
      };

  factory UserAccount.fromJson(Map<String, dynamic> json) => UserAccount(
        name: json['name'] ?? '',
        email: json['email'] ?? '',
        password: json['password'] ?? '',
        isPro: json['isPro'] ?? false,
        avatarPath: json['avatarPath'],
      );
}

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  static const String _usersKey = 'registered_users';
  static const String _isLoggedInKey = 'is_logged_in';
  static const String _currentUserNameKey = 'current_user_name';
  static const String _currentUserEmailKey = 'current_user_email';
  static const String _isProUserKey = 'is_pro_user';
  static const String _userAvatarKey = 'user_avatar_path';

  final fb.FirebaseAuth _fbAuth = fb.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseDatabase _rtdb = FirebaseDatabase.instance;
  SharedPreferences? _prefs;
  final List<UserAccount> _users = [];
  bool _isLoggedIn = false;
  bool _isProUser = false;
  String? _currentUserName;
  String? _currentUserEmail;
  String? _avatarPath;

  StreamSubscription? _rtdbProSubscription;
  StreamSubscription? _firestoreProSubscription;

  List<UserAccount> get users => _users;
  bool get isLoggedIn => _isLoggedIn;
  bool get isProUser => _isProUser;
  String get currentUserName => _currentUserName ?? 'khoi';
  String? get currentUserEmail => _currentUserEmail;
  String? get avatarPath => _avatarPath;

  /// Update and persist user avatar image path linked STRICTLY to current user's email
  Future<void> updateAvatar(String path) async {
    _avatarPath = path;
    if (_currentUserEmail != null && _currentUserEmail!.isNotEmpty) {
      final normalizedEmail = _currentUserEmail!.toLowerCase().trim();
      await _prefs?.setString('${_userAvatarKey}_$normalizedEmail', path);

      // Update local memory list
      final index = _users.indexWhere((u) => u.email == normalizedEmail);
      if (index != -1) {
        _users[index] = UserAccount(
          name: _users[index].name,
          email: _users[index].email,
          password: _users[index].password,
          isPro: _users[index].isPro,
          avatarPath: path,
        );
        await _saveUsers();
      }

      // Sync avatar path string to Firebase RTDB and Firestore
      final sanitizedEmailKey = normalizedEmail.replaceAll('.', '_').replaceAll('@', '_at_');
      try {
        unawaited(_rtdb.ref('users/$sanitizedEmailKey/avatarPath').set(path).timeout(const Duration(seconds: 3), onTimeout: () {}));
        unawaited(_firestore.collection('users').doc(normalizedEmail).set({'avatarPath': path}, SetOptions(merge: true)).timeout(const Duration(seconds: 3), onTimeout: () {}));
      } catch (e) {
        debugPrint('Lỗi lưu Avatar lên Firebase: $e');
      }
    }
  }

  /// Initialize SharedPreferences and sync persistent session
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();

    // Load local registered users
    final String? usersJson = _prefs?.getString(_usersKey);
    if (usersJson != null && usersJson.isNotEmpty) {
      try {
        final List<dynamic> decoded = jsonDecode(usersJson);
        _users.clear();
        for (final item in decoded) {
          _users.add(UserAccount.fromJson(Map<String, dynamic>.from(item)));
        }
      } catch (_) {}
    }

    _currentUserEmail = _prefs?.getString(_currentUserEmailKey);

    // Check Firebase current user session
    final currentUser = _fbAuth.currentUser;
    if (currentUser != null) {
      _isLoggedIn = true;
      _currentUserName = currentUser.displayName ?? _prefs?.getString(_currentUserNameKey) ?? 'khoi';
      _currentUserEmail = currentUser.email;
    } else {
      _isLoggedIn = _prefs?.getBool(_isLoggedInKey) ?? false;
      _currentUserName = _prefs?.getString(_currentUserNameKey) ?? 'khoi';
    }

    // Load Avatar associated STRICTLY with current user email
    if (_currentUserEmail != null && _currentUserEmail!.isNotEmpty) {
      final normalizedEmail = _currentUserEmail!.toLowerCase().trim();
      _avatarPath = _prefs?.getString('${_userAvatarKey}_$normalizedEmail');
    } else {
      _avatarPath = null;
    }

    // Load Pro status associated with current user
    _isProUser = _prefs?.getBool('${_isProUserKey}_$_currentUserEmail') ??
        _prefs?.getBool(_isProUserKey) ??
        false;

    // Listen to Firebase Realtime updates for live PRO status changes
    if (_currentUserEmail != null) {
      _listenToFirebaseProChanges(_currentUserEmail!);
    }
  }

  /// Listen to real-time changes on Firebase Realtime Database & Firestore for `isPro` flag
  void _listenToFirebaseProChanges(String email) {
    final normalizedEmail = email.toLowerCase().trim();
    final sanitizedEmailKey = normalizedEmail.replaceAll('.', '_').replaceAll('@', '_at_');

    // 1. Realtime Database Listener
    _rtdbProSubscription?.cancel();
    try {
      _rtdbProSubscription = _rtdb.ref('users/$sanitizedEmailKey/isPro').onValue.listen((event) {
        if (event.snapshot.exists && event.snapshot.value != null) {
          final bool newIsPro = event.snapshot.value == true;
          if (_isProUser != newIsPro) {
            _isProUser = newIsPro;
            _prefs?.setBool(_isProUserKey, newIsPro);
            _prefs?.setBool('${_isProUserKey}_$normalizedEmail', newIsPro);
            debugPrint('Đã cập nhật trạng thái isPro từ Firebase RTDB: $newIsPro');
          }
        }
      });
    } catch (e) {
      debugPrint('Lỗi lắng nghe Firebase RTDB isPro: $e');
    }

    // 2. Firestore Listener
    _firestoreProSubscription?.cancel();
    try {
      _firestoreProSubscription = _firestore.collection('users').doc(normalizedEmail).snapshots().listen((doc) {
        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          if (data.containsKey('isPro')) {
            final bool newIsPro = data['isPro'] == true;
            if (_isProUser != newIsPro) {
              _isProUser = newIsPro;
              _prefs?.setBool(_isProUserKey, newIsPro);
              _prefs?.setBool('${_isProUserKey}_$normalizedEmail', newIsPro);
              debugPrint('Đã cập nhật trạng thái isPro từ Firestore: $newIsPro');
            }
          }
        }
      });
    } catch (e) {
      debugPrint('Lỗi lắng nghe Firestore isPro: $e');
    }
  }

  /// Sync user account details (Name, Email, Password, Pro status) to BOTH Firebase Realtime Database & Firestore
  Future<void> _saveUserToFirebase({
    required String name,
    required String email,
    required String password,
    bool isPro = false,
  }) async {
    final normalizedEmail = email.toLowerCase().trim();
    final sanitizedEmailKey = normalizedEmail.replaceAll('.', '_').replaceAll('@', '_at_');

    // 1. Sync to Firebase Realtime Database
    try {
      final dbRef = _rtdb.ref('users/$sanitizedEmailKey');
      unawaited(dbRef.set({
        'name': name.trim(),
        'email': normalizedEmail,
        'password': password,
        'isPro': isPro,
        'avatarPath': _avatarPath,
        'lastUpdated': DateTime.now().toIso8601String(),
      }).timeout(const Duration(seconds: 4), onTimeout: () {}));
    } catch (e) {
      debugPrint('Firebase Realtime Database save error: $e');
    }

    // 2. Sync to Firebase Firestore Database
    try {
      final docRef = _firestore.collection('users').doc(normalizedEmail);
      unawaited(docRef.set({
        'name': name.trim(),
        'email': normalizedEmail,
        'password': password,
        'isPro': isPro,
        'avatarPath': _avatarPath,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLoginAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)).timeout(const Duration(seconds: 4), onTimeout: () {}));
    } catch (e) {
      debugPrint('Firestore save user error: $e');
    }
  }

  /// Upgrade account to PRO upon successful payment
  Future<void> upgradeToPro() async {
    _isProUser = true;
    await _prefs?.setBool(_isProUserKey, true);

    if (_currentUserEmail != null) {
      final normalizedEmail = _currentUserEmail!.toLowerCase().trim();
      final sanitizedEmailKey = normalizedEmail.replaceAll('.', '_').replaceAll('@', '_at_');
      await _prefs?.setBool('${_isProUserKey}_$normalizedEmail', true);

      // Update in local user list
      final index = _users.indexWhere((u) => u.email == normalizedEmail);
      if (index != -1) {
        _users[index] = UserAccount(
          name: _users[index].name,
          email: _users[index].email,
          password: _users[index].password,
          isPro: true,
          avatarPath: _users[index].avatarPath,
        );
        await _saveUsers();
      }

      // Sync PRO status update to Realtime Database & Firestore
      try {
        unawaited(_rtdb.ref('users/$sanitizedEmailKey').update({'isPro': true}).timeout(const Duration(seconds: 3), onTimeout: () {}));
        unawaited(_firestore.collection('users').doc(normalizedEmail).update({'isPro': true}).timeout(const Duration(seconds: 3), onTimeout: () {}));
      } catch (e) {
        debugPrint('Firebase update PRO error: $e');
      }
    }
  }

  /// Register new user with password constraint validation
  Future<String?> register({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    final trimmedEmail = email.trim();

    if (name.trim().isEmpty) {
      return 'Vui lòng nhập họ và tên';
    }
    if (trimmedEmail.isEmpty) {
      return 'Vui lòng nhập email';
    }

    if (!trimmedEmail.contains('@') || !trimmedEmail.toLowerCase().endsWith('.com')) {
      return 'Email phải chứa @ và có đuôi .com';
    }

    if (password.isEmpty) {
      return 'Vui lòng nhập mật khẩu';
    }

    // --- KIỂM TRA RÀNG BUỘC MẬT KHẨU BẮT BUỘC ---
    if (password.length < 6) {
      return 'Mật khẩu phải có ít nhất 6 ký tự!';
    }
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return 'Mật khẩu phải chứa ít nhất 1 chữ cái in hoa (A-Z)!';
    }
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      return 'Mật khẩu phải chứa ít nhất 1 chữ số (0-9)!';
    }
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) {
      return 'Mật khẩu phải chứa ít nhất 1 ký tự đặc biệt (!@#\$%^&*...)!';
    }

    if (password != confirmPassword) {
      return 'Mật khẩu nhập lại không khớp!';
    }

    final normalizedEmail = trimmedEmail.toLowerCase();

    // 1. Strict Duplicate Check on Local Accounts First
    final isLocallyRegistered = _users.any((u) => u.email == normalizedEmail);
    if (isLocallyRegistered) {
      return 'Tài khoản email này đã được đăng ký! Mỗi email chỉ được đăng ký 1 lần duy nhất.';
    }

    // 2. Register with Firebase Authentication (Timeout 5s)
    try {
      final userCred = await _fbAuth
          .createUserWithEmailAndPassword(
            email: normalizedEmail,
            password: password,
          )
          .timeout(const Duration(seconds: 5));
      if (userCred.user != null) {
        unawaited(userCred.user!.updateDisplayName(name.trim()));
      }
    } on fb.FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        return 'Tài khoản email này đã được đăng ký! Mỗi email chỉ được đăng ký 1 lần duy nhất.';
      } else if (e.code == 'weak-password') {
        return 'Mật khẩu quá yếu!';
      } else if (e.code == 'invalid-email') {
        return 'Định dạng email không hợp lệ!';
      }
    } catch (_) {}

    // 3. Save User Account Credentials (Name, Email, Password) to Firebase (Non-blocking)
    _saveUserToFirebase(
      name: name,
      email: normalizedEmail,
      password: password,
      isPro: false,
    );

    // 4. Save new account to local storage
    final newUser = UserAccount(
      name: name.trim(),
      email: normalizedEmail,
      password: password,
      isPro: false,
    );
    _users.add(newUser);
    await _saveUsers();

    await _prefs?.setBool('${_isProUserKey}_$normalizedEmail', false);
    _listenToFirebaseProChanges(normalizedEmail);

    return null;
  }

  /// Fast Instant Login (Firebase with Timeout 3s ➔ Fallback Local Account ➔ Instant Transition)
  Future<UserAccount?> login({
    required String email,
    required String password,
  }) async {
    if (email.trim().isEmpty || password.isEmpty) {
      return null;
    }
    final normalizedEmail = email.trim().toLowerCase();
    _currentUserEmail = normalizedEmail;

    // Load strict avatar associated ONLY with this email
    _avatarPath = _prefs?.getString('${_userAvatarKey}_$normalizedEmail');
    _listenToFirebaseProChanges(normalizedEmail);

    // Reload Notes and Journals associated specifically with this email
    unawaited(NotesService().loadUserNotes());
    unawaited(JournalService().loadUserJournals());

    // 1. Try Fast Firebase Authentication with a 3-second strict timeout
    try {
      final userCred = await _fbAuth
          .signInWithEmailAndPassword(
            email: normalizedEmail,
            password: password,
          )
          .timeout(const Duration(seconds: 3));

      if (userCred.user != null) {
        final fbUser = userCred.user!;
        final name = (fbUser.displayName != null && fbUser.displayName!.isNotEmpty)
            ? fbUser.displayName!
            : 'khoi';
        _isLoggedIn = true;
        _currentUserName = name;
        _currentUserEmail = normalizedEmail;

        _isProUser = _prefs?.getBool('${_isProUserKey}_$normalizedEmail') ?? false;

        // Background non-blocking sync
        _saveUserToFirebase(
          name: name,
          email: normalizedEmail,
          password: password,
          isPro: _isProUser,
        );

        await _prefs?.setBool(_isLoggedInKey, true);
        await _prefs?.setString(_currentUserNameKey, name);
        await _prefs?.setString(_currentUserEmailKey, normalizedEmail);
        await _prefs?.setBool(_isProUserKey, _isProUser);

        return UserAccount(
          name: name,
          email: normalizedEmail,
          password: password,
          isPro: _isProUser,
          avatarPath: _avatarPath,
        );
      }
    } catch (e) {
      debugPrint('Firebase login timeout/error, using instant fallback: $e');
    }

    // 2. Instant Local Account Check
    for (final user in _users) {
      if (user.email == normalizedEmail && user.password == password) {
        _isLoggedIn = true;
        _currentUserName = user.name.isNotEmpty ? user.name : 'khoi';
        _currentUserEmail = user.email;

        _isProUser = user.isPro || (_prefs?.getBool('${_isProUserKey}_$normalizedEmail') ?? false);
        _avatarPath = _prefs?.getString('${_userAvatarKey}_$normalizedEmail') ?? user.avatarPath;

        await _prefs?.setBool(_isLoggedInKey, true);
        await _prefs?.setString(_currentUserNameKey, _currentUserName!);
        await _prefs?.setString(_currentUserEmailKey, user.email);
        await _prefs?.setBool(_isProUserKey, _isProUser);

        return UserAccount(
          name: _currentUserName!,
          email: user.email,
          password: user.password,
          isPro: _isProUser,
          avatarPath: _avatarPath,
        );
      }
    }

    // 3. Fallback: Check Firebase Realtime Database directly with 3s Timeout
    try {
      final sanitizedEmailKey = normalizedEmail.replaceAll('.', '_').replaceAll('@', '_at_');
      final event = await _rtdb.ref('users/$sanitizedEmailKey').once().timeout(const Duration(seconds: 3));
      if (event.snapshot.exists && event.snapshot.value != null) {
        final Map<dynamic, dynamic> data = event.snapshot.value as Map<dynamic, dynamic>;
        final storedPassword = data['password'] ?? '';
        if (storedPassword == password) {
          final name = data['name'] ?? 'khoi';
          _isLoggedIn = true;
          _currentUserName = name;
          _currentUserEmail = normalizedEmail;
          _isProUser = data['isPro'] ?? false;
          _avatarPath = _prefs?.getString('${_userAvatarKey}_$normalizedEmail') ?? data['avatarPath'];

          await _prefs?.setBool(_isLoggedInKey, true);
          await _prefs?.setString(_currentUserNameKey, name);
          await _prefs?.setString(_currentUserEmailKey, normalizedEmail);
          await _prefs?.setBool(_isProUserKey, _isProUser);

          return UserAccount(
            name: name,
            email: normalizedEmail,
            password: password,
            isPro: _isProUser,
            avatarPath: _avatarPath,
          );
        }
      }
    } catch (_) {}

    return null;
  }

  /// Send password reset email directly via Firebase Auth
  Future<String?> sendPasswordResetEmail(String email) async {
    final trimmedEmail = email.trim();

    if (trimmedEmail.isEmpty) {
      return 'Vui lòng nhập địa chỉ email của bạn';
    }

    if (!trimmedEmail.contains('@') || !trimmedEmail.toLowerCase().endsWith('.com')) {
      return 'Email không hợp lệ! Vui lòng kiểm tra lại email';
    }

    try {
      await _fbAuth.sendPasswordResetEmail(email: trimmedEmail.toLowerCase()).timeout(const Duration(seconds: 4));
    } catch (_) {}

    return null;
  }

  /// Log out user from Firebase Auth & local session
  Future<void> logout() async {
    _rtdbProSubscription?.cancel();
    _firestoreProSubscription?.cancel();

    try {
      await _fbAuth.signOut();
    } catch (_) {}

    _isLoggedIn = false;
    _isProUser = false;
    _currentUserName = null;
    _currentUserEmail = null;
    _avatarPath = null;
    await _prefs?.setBool(_isLoggedInKey, false);
    await _prefs?.setBool(_isProUserKey, false);
    await _prefs?.remove(_currentUserNameKey);
    await _prefs?.remove(_currentUserEmailKey);
  }

  Future<void> _saveUsers() async {
    final List<Map<String, dynamic>> jsonList =
        _users.map((u) => u.toJson()).toList();
    await _prefs?.setString(_usersKey, jsonEncode(jsonList));
  }
}

import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
// import 'package:google_sign_in/google_sign_in.dart';
import 'package:model/model/user.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'login_user.g.dart';

/// ログインしているユーザーを取得する
///
/// Firebase authentication の匿名ログインを行い、ログインしているユーザーを取得します。
/// ログインしていない場合は匿名ログインを行います。
@Riverpod(keepAlive: true)
class LoginUser extends _$LoginUser {
  @override
  Future<User> build() async {
    final currentUser = auth.FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      return User(
        id: currentUser.uid,
        isAnonymous: currentUser.isAnonymous,
      );
    }

    try {
      final userCredential =
          await auth.FirebaseAuth.instance.signInAnonymously();
      return User(
        id: userCredential.user!.uid,
        isAnonymous: true,
      );
    } on auth.FirebaseAuthException catch (e, s) {
      await FirebaseCrashlytics.instance.recordError(e, s);
      rethrow;
    }
  }

  /// Google アカウントでログインする。
  // Future<void> signInWithGoogle() async {
  //   const clientId = String.fromEnvironment('google_client_id');
  //   if (clientId.isEmpty) {
  //     throw Exception('Google client id is not set.');
  //   }

  //   final googleUser = await GoogleSignIn(clientId: clientId).signIn();

  //   // Obtain the auth details from the request
  //   final googleAuth = await googleUser?.authentication;

  //   // googleAuthがない場合はキャンセルとみなして処理を終了する
  //   if (googleAuth == null) {
  //     return;
  //   }

  //   // Create a new credential
  //   final credential = auth.GoogleAuthProvider.credential(
  //     accessToken: googleAuth.accessToken,
  //     idToken: googleAuth.idToken,
  //   );

  //   try {
  //     await auth.FirebaseAuth.instance.currentUser
  //         ?.linkWithCredential(credential);
  //   } on auth.FirebaseAuthException catch (e) {
  //     // すでにログイン済みのユーザーの場合、`linkWithCredential`でエラーになる。
  //     // その場合は、`signInWithCredential`でログインする。
  //     await auth.FirebaseAuth.instance.signInWithCredential(credential);
  //     switch (e.code) {
  //       case "provider-already-linked":
  //         Exception("The provider has already been linked to the user.");
  //         break;
  //       case "invalid-credential":
  //         Exception("The provider's credential is not valid.");
  //         break;
  //       case "credential-already-in-use":
  //         Exception(
  //             "The account corresponding to the credential already exists, "
  //             "or is already linked to a Firebase User.");
  //         break;
  //       // See the API reference for the full list of error codes.
  //       default:
  //         Exception("Unknown error.");
  //     }
  //   } finally {
  //     ref.invalidateSelf();
  //   }
  // }

  /// Apple sign in でログインする。
  // Future<void> signInWithApple() async {
  //   try {
  //     await auth.FirebaseAuth.instance.currentUser
  //         ?.linkWithProvider(auth.AppleAuthProvider());
  //   } on auth.FirebaseAuthException catch (e) {
  //     switch (e.code) {
  //       case "credential-already-in-use":
  //       case "provider-already-linked":
  //         // すでにlink済みの場合、`linkWithProvider`でエラーになる。
  //         // その場合には、`signInWithCredential`でログインするとエラーになるため、
  //         // `signInWithProvider`を使うが、ログインダイアログが2回出てしまうため、いずれ改善したい。
  //         await auth.FirebaseAuth.instance
  //             .signInWithProvider(auth.AppleAuthProvider());
  //         Exception("The provider has already been linked to the user.");
  //         break;
  //       case "invalid-credential":
  //         Exception("The provider's credential is not valid.");
  //         break;
  //       // See the API reference for the full list of error codes.
  //       default:
  //         Exception("Unknown error.");
  //     }
  //   } finally {
  //     ref.invalidateSelf();
  //   }
  // }

  /// サインアウトする。
  Future<void> signOut() async {
    await auth.FirebaseAuth.instance.signOut();
    ref.invalidateSelf();
  }
}

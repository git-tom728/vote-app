/// 🔧 開発環境用のFirebase設定
/// テスト用のFirebaseプロジェクトの設定
/// 
/// 注意: このファイルは開発環境専用です。
/// 本番環境では firebase_options.dart を使用してください。

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DevelopmentFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DevelopmentFirebaseOptions have not been configured for linux',
        );
      default:
        throw UnsupportedError(
          'DevelopmentFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // 🔧 開発環境用の設定
  // TODO: 開発用のFirebaseプロジェクトを作成後、以下の値を更新してください
  // 現在は本番環境と同じ設定になっています（テスト用）
  
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBfnMmHhtqSXFKe37RQaa1TIpvGvrZ6Rjc',
    appId: '1:340312073242:web:b62d5fcc6e425f72661da3',
    messagingSenderId: '340312073242',
    projectId: 'vote-app1', // TODO: 開発用プロジェクトIDに変更
    authDomain: 'vote-app1.firebaseapp.com',
    storageBucket: 'vote-app1.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAg7m1Ws2NdhihG4G4S-gnE5dNBtYt_2Lc',
    appId: '1:340312073242:android:1f98d42cd150b3fa661da3',
    messagingSenderId: '340312073242',
    projectId: 'vote-app1', // TODO: 開発用プロジェクトIDに変更
    storageBucket: 'vote-app1.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBXyC9_sO8rKa4rPC97U6hnfV2Ski4vdN0',
    appId: '1:340312073242:ios:8f445b9a6da92305661da3',
    messagingSenderId: '340312073242',
    projectId: 'vote-app1', // TODO: 開発用プロジェクトIDに変更
    storageBucket: 'vote-app1.firebasestorage.app',
    iosBundleId: 'com.example.vote',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBXyC9_sO8rKa4rPC97U6hnfV2Ski4vdN0',
    appId: '1:340312073242:ios:8f445b9a6da92305661da3',
    messagingSenderId: '340312073242',
    projectId: 'vote-app1', // TODO: 開発用プロジェクトIDに変更
    storageBucket: 'vote-app1.firebasestorage.app',
    iosBundleId: 'com.example.vote',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBfnMmHhtqSXFKe37RQaa1TIpvGvrZ6Rjc',
    appId: '1:340312073242:web:6b8f5feb3ef1035d661da3',
    messagingSenderId: '340312073242',
    projectId: 'vote-app1', // TODO: 開発用プロジェクトIDに変更
    authDomain: 'vote-app1.firebaseapp.com',
    storageBucket: 'vote-app1.firebasestorage.app',
  );
}


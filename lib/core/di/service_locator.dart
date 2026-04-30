import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:get_it/get_it.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../features/auth/data/auth_repository.dart';
import '../../features/categories/data/category_repository.dart';
import '../../features/goals/data/goal_repository.dart';
import '../../features/insights/domain/insight_engine.dart';
import '../../features/transactions/data/transaction_repository.dart';

final getIt = GetIt.instance;

Future<void> setupServiceLocator() async {
  // External
  getIt.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
  getIt.registerLazySingleton<FirebaseFirestore>(() => FirebaseFirestore.instance);
  getIt.registerLazySingleton<GoogleSignIn>(() => GoogleSignIn(
    clientId: kIsWeb
        ? 'YOUR_GOOGLE_OAUTH_CLIENT_ID.apps.googleusercontent.com'
        : null,
  ));

  // Repositories
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepository(getIt(), getIt(), getIt()),
  );
  getIt.registerLazySingleton<TransactionRepository>(
    () => TransactionRepository(getIt(), getIt()),
  );
  getIt.registerLazySingleton<CategoryRepository>(
    () => CategoryRepository(getIt(), getIt()),
  );
  getIt.registerLazySingleton<GoalRepository>(
    () => GoalRepository(getIt(), getIt()),
  );

  // Domain services
  getIt.registerLazySingleton<InsightEngine>(() => InsightEngine());
}

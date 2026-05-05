import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mocktail/mocktail.dart';

import 'package:spendsnap/features/auth/data/auth_repository.dart';
import 'package:spendsnap/features/auth/domain/user_model.dart';
import 'package:spendsnap/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:spendsnap/features/auth/presentation/bloc/auth_event.dart';
import 'package:spendsnap/features/auth/presentation/bloc/auth_state.dart';

class _MockAuthRepo extends Mock implements AuthRepository {}
class _FakeUser extends Fake implements User {
  @override
  String get uid => 'user1';
}

// Fixed reference date — never call DateTime.now() in tests.
final _now = DateTime(2024, 1, 15);

// Factory helper for UserModel.
UserModel _user({
  String uid = 'user1',
  String email = 'test@example.com',
  String displayName = 'Test User',
  String currency = 'INR',
}) =>
    UserModel(
      uid: uid,
      email: email,
      displayName: displayName,
      currency: currency,
      createdAt: _now,
    );

void main() {
  late _MockAuthRepo repo;

  setUp(() {
    repo = _MockAuthRepo();
  });

  group('AuthBloc — initial state', () {
    test('initial state is AuthInitial', () {
      final bloc = AuthBloc(repo);
      expect(bloc.state, isA<AuthInitial>());
      bloc.close();
    });
  });

  // ── AuthCheckRequested ──────────────────────────────────────────────────────

  group('AuthBloc — AuthCheckRequested', () {
    blocTest<AuthBloc, AuthState>(
      'emits Authenticated when currentUser is non-null and fetchCurrentUser succeeds',
      setUp: () {
        when(() => repo.currentUser).thenReturn(_FakeUser());
        when(() => repo.fetchCurrentUser()).thenAnswer(
          (_) async => _user(),
        );
      },
      build: () => AuthBloc(repo),
      act: (bloc) => bloc.add(const AuthCheckRequested()),
      expect: () => [
        isA<Authenticated>().having((s) => s.user.uid, 'uid', 'user1'),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits Unauthenticated when currentUser is null',
      setUp: () {
        when(() => repo.currentUser).thenReturn(null);
      },
      build: () => AuthBloc(repo),
      act: (bloc) => bloc.add(const AuthCheckRequested()),
      expect: () => [isA<Unauthenticated>()],
    );

    blocTest<AuthBloc, AuthState>(
      'emits Unauthenticated when fetchCurrentUser throws',
      setUp: () {
        when(() => repo.currentUser).thenReturn(_FakeUser());
        when(() => repo.fetchCurrentUser())
            .thenAnswer((_) async => throw Exception('Firestore unavailable'));
      },
      build: () => AuthBloc(repo),
      act: (bloc) => bloc.add(const AuthCheckRequested()),
      expect: () => [isA<Unauthenticated>()],
    );
  });

  // ── LoginRequested ──────────────────────────────────────────────────────────

  group('AuthBloc — LoginRequested', () {
    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, Authenticated] on successful email sign-in',
      setUp: () {
        when(() => repo.signInWithEmail(
              email: any(named: 'email'),
              password: any(named: 'password'),
            )).thenAnswer((_) async => _user());
      },
      build: () => AuthBloc(repo),
      act: (bloc) => bloc.add(const LoginRequested(
        email: 'test@example.com',
        password: 'password123',
      )),
      expect: () => [
        isA<AuthLoading>(),
        isA<Authenticated>().having((s) => s.user.email, 'email', 'test@example.com'),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthError] when signInWithEmail throws',
      setUp: () {
        when(() => repo.signInWithEmail(
              email: any(named: 'email'),
              password: any(named: 'password'),
            )).thenAnswer((_) async => throw Exception('wrong-password'));
      },
      build: () => AuthBloc(repo),
      act: (bloc) => bloc.add(const LoginRequested(
        email: 'test@example.com',
        password: 'wrongpass',
      )),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthError>(),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'authenticated user has correct displayName from repo',
      setUp: () {
        when(() => repo.signInWithEmail(
              email: any(named: 'email'),
              password: any(named: 'password'),
            )).thenAnswer((_) async => _user(displayName: 'Alice'));
      },
      build: () => AuthBloc(repo),
      act: (bloc) => bloc.add(const LoginRequested(
        email: 'alice@example.com',
        password: 'secret',
      )),
      skip: 1, // skip AuthLoading
      expect: () => [
        isA<Authenticated>().having(
          (s) => s.user.displayName,
          'displayName',
          'Alice',
        ),
      ],
    );
  });

  // ── SignupRequested ─────────────────────────────────────────────────────────

  group('AuthBloc — SignupRequested', () {
    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, Authenticated] on successful sign-up',
      setUp: () {
        when(() => repo.signUpWithEmail(
              email: any(named: 'email'),
              password: any(named: 'password'),
              displayName: any(named: 'displayName'),
            )).thenAnswer((_) async => _user(displayName: 'New User'));
      },
      build: () => AuthBloc(repo),
      act: (bloc) => bloc.add(const SignupRequested(
        email: 'new@example.com',
        password: 'secure123',
        displayName: 'New User',
      )),
      expect: () => [
        isA<AuthLoading>(),
        isA<Authenticated>().having(
          (s) => s.user.displayName,
          'displayName',
          'New User',
        ),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthError] when signUpWithEmail throws',
      setUp: () {
        when(() => repo.signUpWithEmail(
              email: any(named: 'email'),
              password: any(named: 'password'),
              displayName: any(named: 'displayName'),
            )).thenAnswer((_) async => throw Exception('email-already-in-use'));
      },
      build: () => AuthBloc(repo),
      act: (bloc) => bloc.add(const SignupRequested(
        email: 'existing@example.com',
        password: 'password',
        displayName: 'User',
      )),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthError>(),
      ],
    );
  });

  // ── GoogleSignInRequested ───────────────────────────────────────────────────

  group('AuthBloc — GoogleSignInRequested', () {
    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, Authenticated] on successful Google sign-in',
      setUp: () {
        when(() => repo.signInWithGoogle())
            .thenAnswer((_) async => _user(uid: 'google-user1'));
      },
      build: () => AuthBloc(repo),
      act: (bloc) => bloc.add(const GoogleSignInRequested()),
      expect: () => [
        isA<AuthLoading>(),
        isA<Authenticated>().having((s) => s.user.uid, 'uid', 'google-user1'),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthError] when Google sign-in is cancelled',
      setUp: () {
        when(() => repo.signInWithGoogle())
            .thenAnswer((_) async => throw Exception('Google sign-in cancelled'));
      },
      build: () => AuthBloc(repo),
      act: (bloc) => bloc.add(const GoogleSignInRequested()),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthError>(),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthError] when Google sign-in throws a network error',
      setUp: () {
        when(() => repo.signInWithGoogle())
            .thenAnswer((_) async => throw Exception('network-request-failed'));
      },
      build: () => AuthBloc(repo),
      act: (bloc) => bloc.add(const GoogleSignInRequested()),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthError>(),
      ],
    );
  });

  // ── LogoutRequested ─────────────────────────────────────────────────────────

  group('AuthBloc — LogoutRequested', () {
    blocTest<AuthBloc, AuthState>(
      'emits Unauthenticated after successful sign-out',
      setUp: () {
        when(() => repo.signOut()).thenAnswer((_) async {});
      },
      build: () => AuthBloc(repo),
      act: (bloc) => bloc.add(const LogoutRequested()),
      expect: () => [isA<Unauthenticated>()],
    );

    blocTest<AuthBloc, AuthState>(
      'calls repo.signOut exactly once on LogoutRequested',
      setUp: () {
        when(() => repo.signOut()).thenAnswer((_) async {});
      },
      build: () => AuthBloc(repo),
      act: (bloc) => bloc.add(const LogoutRequested()),
      verify: (_) {
        verify(() => repo.signOut()).called(1);
      },
    );
  });
}

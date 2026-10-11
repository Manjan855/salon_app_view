import 'package:flutter_test/flutter_test.dart';
import 'package:salon_app_view/repositories/payment_repository.dart';
import 'package:salon_app_view/shared/providers/payment_provider.dart';

/// Stub repository whose [isDeployed] answer is scripted per test. Because
/// `PaymentRepository._supabase` is a lazy getter (never touched unless a
/// method calls it), a subclass can be constructed without a live client.
class _StubPaymentRepository extends PaymentRepository {
  _StubPaymentRepository(this._deployedAnswer) : super();

  /// Throw inside [isDeployed] when non-null (simulates a network error),
  /// otherwise return this value.
  Object Function()? _deployedError;
  bool _deployedAnswer;

  set deployedAnswer(bool value) => _deployedAnswer = value;
  set deployedError(Object Function()? throwable) =>
      _deployedError = throwable;

  @override
  Future<bool> isDeployed() async {
    final throwable = _deployedError;
    if (throwable != null) throw throwable();
    return _deployedAnswer;
  }
}

void main() {
  group('PaymentProvider.checkDeployment', () {
    test('marks notDeployed when the function answers isDeployed() == false',
        () async {
      final repo = _StubPaymentRepository(false);
      final provider = PaymentProvider(repository: repo);

      await provider.checkDeployment();

      expect(provider.notDeployed, isTrue);
      expect(provider.checkingDeployment, isFalse);
    });

    test('keeps notDeployed false when the function is live', () async {
      final repo = _StubPaymentRepository(true);
      final provider = PaymentProvider(repository: repo);

      await provider.checkDeployment();

      expect(provider.notDeployed, isFalse);
      expect(provider.checkingDeployment, isFalse);
    });

    test('network errors leave the previous state (unknown, not blocked)',
        () async {
      final repo = _StubPaymentRepository(true)
        ..deployedError = () => Exception('offline');
      final provider = PaymentProvider(repository: repo);

      await provider.checkDeployment();

      expect(provider.notDeployed, isFalse,
          reason: 'an unknown outcome must not pre-emptively block payments');
      expect(provider.checkingDeployment, isFalse);
    });

    test('a failed probe keeps a previously-observed failure state', () async {
      final repo = _StubPaymentRepository(false);
      final provider = PaymentProvider(repository: repo);

      await provider.checkDeployment();
      expect(provider.notDeployed, isTrue);

      // Now the network dies; the previous "not deployed" observation sticks
      // instead of being silently cleared.
      repo
        ..deployedAnswer = true
        ..deployedError = () => Exception('offline');
      await provider.checkDeployment();
      expect(provider.notDeployed, isTrue);
    });

    test('notifies listeners while the probe starts and when it finishes',
        () async {
      final repo = _StubPaymentRepository(false);
      final provider = PaymentProvider(repository: repo);
      final states = <(bool checking, bool notDeployed)>[];
      provider.addListener(() {
        states.add((provider.checkingDeployment, provider.notDeployed));
      });

      await provider.checkDeployment();

      // First notification: checking starts (notDeployed still false).
      // Second notification: checking finishes (notDeployed resolved).
      expect(states, [
        (true, false),
        (false, true),
      ]);
    });
  });
}
import 'dart:async';
import 'package:fake_async/fake_async.dart';

// Plan 29 — SpeechToTextService locale resolution + transcript / cancel /
// level behavior, exercised through the SttPlugin seam (no device).

import 'package:app/data/voice/speech_service.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeSttPlugin implements SttPlugin {
  bool initializeResult = true;
  bool permission = true;
  List<String> localeList = ['en_US', 'pt_BR'];

  void Function()? afterStop;
  Completer<void>? listenGate;
  final resultCallbacks = <SttResultCallback>[];
  final calls = <String>[];
  int stopCalls = 0;
  int cancelCalls = 0;
  String? listenedLocale;
  Duration? listenedFor;

  SttResultCallback? _onResult;
  SttLevelCallback? _onLevel;

  @override
  Future<bool> initialize({
    void Function(String status)? onStatus,
    void Function()? onError,
  }) async {
    status = onStatus;
    error = onError;
    return initializeResult;
  }

  void Function(String)? status;
  void Function()? error;

  @override
  Future<bool> hasPermission() async => permission;

  @override
  Future<List<String>> locales() async => localeList;

  @override
  Future<void> listen({
    required String localeId,
    required Duration listenFor,
    required SttResultCallback onResult,
    required SttLevelCallback onLevel,
  }) async {
    calls.add('listen');
    resultCallbacks.add(onResult);
    listenedLocale = localeId;
    listenedFor = listenFor;
    _onResult = onResult;
    _onLevel = onLevel;
    if (listenGate != null) await listenGate!.future;
  }

  @override
  Future<void> stop() async {
    calls.add('stop');
    stopCalls++;
    afterStop?.call();
  }

  @override
  Future<void> cancel() async {
    calls.add('cancel');
    cancelCalls++;
  }

  // Test drivers.
  void emitResult(String words, {bool isFinal = false}) =>
      _onResult?.call(words, isFinal);
  void emitLevel(double level) => _onLevel?.call(level);
}

void main() {
  group('init — locale resolution (#8 / #9)', () {
    test('exact preferred locale is used', () async {
      final plugin = _FakeSttPlugin()..localeList = ['en_US', 'pt_BR'];
      final service = SpeechToTextService(plugin);
      final a = await service.init(preferredLocaleId: 'pt_BR');
      expect(a, const SpeechReady('pt_BR'));
    });

    test('falls back to a same-language variant', () async {
      final plugin = _FakeSttPlugin()..localeList = ['en_US', 'pt_BR'];
      final service = SpeechToTextService(plugin);
      final a = await service.init(preferredLocaleId: 'pt_PT');
      expect(a, const SpeechReady('pt_BR'));
    });

    test('locale without on-device support falls back to en_US (#9)', () async {
      final plugin = _FakeSttPlugin()..localeList = ['en_US', 'pt_BR'];
      final service = SpeechToTextService(plugin);
      final a = await service.init(preferredLocaleId: 'de_DE');
      expect(a, const SpeechReady('en_US'));
    });

    test('no en_US but another English variant present', () async {
      final plugin = _FakeSttPlugin()..localeList = ['en_GB', 'fr_FR'];
      final service = SpeechToTextService(plugin);
      final a = await service.init(preferredLocaleId: 'de_DE');
      expect(a, const SpeechReady('en_GB'));
    });

    test('case/separator-insensitive matching', () async {
      final plugin = _FakeSttPlugin()..localeList = ['en-us', 'pt_br'];
      final service = SpeechToTextService(plugin);
      final a = await service.init(preferredLocaleId: 'PT_BR');
      expect(a, const SpeechReady('pt_br'));
    });

    test('no acceptable locale → unsupported (mic hidden)', () async {
      final plugin = _FakeSttPlugin()..localeList = ['fr_FR'];
      final service = SpeechToTextService(plugin);
      final a = await service.init(preferredLocaleId: 'de_DE');
      expect(a, const SpeechUnsupported());
    });
  });

  group('init — availability', () {
    test(
      'permission denied when initialize fails & no permission (#10)',
      () async {
        final plugin = _FakeSttPlugin()
          ..initializeResult = false
          ..permission = false;
        final service = SpeechToTextService(plugin);
        final a = await service.init(preferredLocaleId: 'en_US');
        expect(a, const SpeechPermissionDenied());
      },
    );

    test('unsupported when initialize fails but permission granted', () async {
      final plugin = _FakeSttPlugin()
        ..initializeResult = false
        ..permission = true;
      final service = SpeechToTextService(plugin);
      final a = await service.init(preferredLocaleId: 'en_US');
      expect(a, const SpeechUnsupported());
    });
  });

  group('capture lifecycle', () {
    test(
      'live hypotheses are cumulative replacements, empty corrections ignored',
      () async {
        final plugin = _FakeSttPlugin();
        final service = SpeechToTextService(plugin);
        await service.init();
        final live = <String>[];
        await service.start(
          localeId: 'en_US',
          maxDuration: const Duration(seconds: 60),
          onTranscript: live.add,
        );
        plugin.emitResult('one');
        plugin.emitResult('won two');
        plugin.emitResult('  ');
        plugin.emitResult('won two three', isFinal: true);
        expect(live, ['one', 'won two', 'won two three']);
        expect(await service.stop(), 'won two three');
        service.dispose();
      },
    );

    test(
      'done from native stop does not discard first final delivered later',
      () async {
        final plugin = _FakeSttPlugin();
        final service = SpeechToTextService(plugin);
        await service.init();
        await service.start(
          localeId: 'en_US',
          maxDuration: const Duration(seconds: 60),
        );
        plugin.afterStop = () {
          plugin.status!('notListening');
          plugin.status!('done'); // plugin normalizes Android doneNoResult
          Timer(
            const Duration(milliseconds: 20),
            () => plugin.emitResult('first complete words', isFinal: true),
          );
        };
        expect(await service.stop(), 'first complete words');
        service.dispose();
      },
    );

    test(
      'no final uses bounded last valid partial and rejects late callbacks',
      () {
        fakeAsync((clock) {
          final plugin = _FakeSttPlugin();
          final service = SpeechToTextService(plugin);
          final live = <String>[];
          String? result;
          unawaited(service.init());
          clock.flushMicrotasks();
          unawaited(
            service.start(
              localeId: 'en_US',
              maxDuration: const Duration(seconds: 60),
              onTranscript: live.add,
            ),
          );
          clock.flushMicrotasks();
          plugin.emitResult('last valid');
          plugin.emitResult('');
          service.stop().then((text) => result = text);
          clock.flushMicrotasks();
          clock.elapse(const Duration(milliseconds: 1999));
          expect(result, isNull);
          clock.elapse(const Duration(milliseconds: 1));
          expect(result, 'last valid');
          plugin.emitResult('too late', isFinal: true);
          expect(live, ['last valid']);
          service.dispose();
          clock.flushMicrotasks();
        });
      },
    );

    test(
      'native early end/error informs caller once and releases via stop',
      () async {
        final plugin = _FakeSttPlugin();
        final service = SpeechToTextService(plugin);
        await service.init();
        var ends = 0;
        var errors = 0;
        await service.start(
          localeId: 'en_US',
          maxDuration: const Duration(seconds: 60),
          onEnded: () => ends++,
          onError: () => errors++,
        );
        plugin.emitResult('partial');
        plugin.status!('notListening');
        plugin.error!();
        plugin.status!('done');
        expect(ends, 1);
        expect(errors, 1);
        expect(await service.stop(), 'partial');
        expect(plugin.stopCalls, 1);
        service.dispose();
      },
    );

    test(
      'cancel during listen serializes microphone release before next session',
      () async {
        final plugin = _FakeSttPlugin()..listenGate = Completer<void>();
        final service = SpeechToTextService(plugin);
        await service.init();
        final first = service.start(
          localeId: 'en_US',
          maxDuration: const Duration(seconds: 60),
        );
        await Future<void>.delayed(Duration.zero);
        final old = plugin.resultCallbacks.single;
        final cancelling = service.cancel();
        final live = <String>[];
        final second = service.start(
          localeId: 'en_US',
          maxDuration: const Duration(seconds: 60),
          onTranscript: live.add,
        );
        plugin.listenGate!.complete();
        await first;
        await cancelling;
        await second;
        expect(plugin.calls, ['listen', 'cancel', 'listen']);
        old('old session', true);
        plugin.emitResult('new session', isFinal: true);
        expect(live, ['new session']);
        expect(await service.stop(), 'new session');
        service.dispose();
      },
    );

    test(
      'cancel or dispose unblocks finalization and discards late final',
      () async {
        for (final dispose in [false, true]) {
          final plugin = _FakeSttPlugin();
          final service = SpeechToTextService(plugin);
          await service.init();
          final live = <String>[];
          await service.start(
            localeId: 'en_US',
            maxDuration: const Duration(seconds: 60),
            onTranscript: live.add,
          );
          final finishing = service.stop();
          if (dispose) {
            service.dispose();
          } else {
            await service.cancel();
          }
          expect(await finishing, isEmpty);
          plugin.emitResult('late discarded', isFinal: true);
          expect(live, isEmpty);
          if (!dispose) service.dispose();
        }
      },
    );

    test(
      'stop waits for real final delivered after native stop returns',
      () async {
        final plugin = _FakeSttPlugin();
        final service = SpeechToTextService(plugin);
        await service.init(preferredLocaleId: 'en_US');
        await service.start(
          localeId: 'en_US',
          maxDuration: const Duration(seconds: 60),
        );
        plugin.emitResult('incomplete');
        plugin.afterStop = () => Timer(
          const Duration(milliseconds: 20),
          () => plugin.emitResult('complete final words', isFinal: true),
        );
        expect(await service.stop(), 'complete final words');
        service.dispose();
      },
    );
    test('stop returns the latest accumulated transcript, trimmed', () async {
      final plugin = _FakeSttPlugin();
      final service = SpeechToTextService(plugin);
      await service.init(preferredLocaleId: 'en_US');

      await service.start(
        localeId: 'en_US',
        maxDuration: const Duration(seconds: 60),
      );
      expect(plugin.listenedLocale, 'en_US');
      expect(plugin.listenedFor, const Duration(seconds: 60));

      plugin.emitResult('hello');
      plugin.emitResult('hello world  ', isFinal: true);
      final text = await service.stop();
      expect(text, 'hello world');
      expect(plugin.stopCalls, 1);
    });

    test('empty/silent capture resolves to empty string (#12)', () async {
      final plugin = _FakeSttPlugin();
      final service = SpeechToTextService(plugin);
      await service.init(preferredLocaleId: 'en_US');
      await service.start(
        localeId: 'en_US',
        maxDuration: const Duration(seconds: 60),
      );
      final text = await service.stop();
      expect(text, isEmpty);
    });

    test('cancel discards the transcript and never returns text', () async {
      final plugin = _FakeSttPlugin();
      final service = SpeechToTextService(plugin);
      await service.init(preferredLocaleId: 'en_US');

      await service.start(
        localeId: 'en_US',
        maxDuration: const Duration(seconds: 60),
      );
      plugin.emitResult('secret words');
      await service.cancel();
      expect(plugin.cancelCalls, 1);

      // A fresh capture must not inherit the cancelled transcript.
      await service.start(
        localeId: 'en_US',
        maxDuration: const Duration(seconds: 60),
      );
      expect(await service.stop(), isEmpty);
    });

    test(
      'sound level is normalized to 0..1 on the soundLevel stream (Android scale)',
      () async {
        final plugin = _FakeSttPlugin();
        // Pin the Android rmsdB scale so the assertions don't depend on the
        // host the test runs on (forPlatform() picks darwin on macOS).
        final service = SpeechToTextService(plugin, SoundLevelScale.android);
        await service.init(preferredLocaleId: 'en_US');

        final levels = <double>[];
        final sub = service.soundLevel.listen(levels.add);

        await service.start(
          localeId: 'en_US',
          maxDuration: const Duration(seconds: 60),
        );
        plugin.emitLevel(-2.0); // min → 0
        plugin.emitLevel(4.0); // midpoint → 0.5
        plugin.emitLevel(10.0); // max → 1
        plugin.emitLevel(99.0); // clamped → 1
        await Future<void>.delayed(Duration.zero);

        expect(levels, [0.0, 0.5, 1.0, 1.0]);
        await sub.cancel();
        service.dispose();
      },
    );

    test(
      'sound level uses the dBFS scale on iOS/macOS (negative avgPower)',
      () async {
        // Regression: iOS reports 20*log10(rms), a negative dBFS value. The
        // Android range [-2, 10] clamps all of it to 0 → flat waveform. The
        // darwin scale [-50, -10] must spread typical speech across 0..1.
        final plugin = _FakeSttPlugin();
        final service = SpeechToTextService(plugin, SoundLevelScale.darwin);
        await service.init(preferredLocaleId: 'en_US');

        final levels = <double>[];
        final sub = service.soundLevel.listen(levels.add);

        await service.start(
          localeId: 'en_US',
          maxDuration: const Duration(seconds: 60),
        );
        plugin.emitLevel(-50.0); // min → 0
        plugin.emitLevel(-30.0); // midpoint → 0.5
        plugin.emitLevel(-10.0); // max → 1
        plugin.emitLevel(-60.0); // below floor → clamped → 0
        plugin.emitLevel(double.negativeInfinity); // silent buffer → 0
        await Future<void>.delayed(Duration.zero);

        expect(levels, [0.0, 0.5, 1.0, 0.0, 0.0]);
        await sub.cancel();
        service.dispose();
      },
    );
  });

  group('SoundLevelScale', () {
    test('forPlatform picks the darwin scale on macOS test host', () {
      // The unit-test host is macOS, so the platform factory must resolve to
      // the dBFS scale — guarding the iOS waveform regression directly.
      expect(SoundLevelScale.forPlatform(), SoundLevelScale.darwin);
    });

    test('normalize clamps NaN and ±infinity to the endpoints', () {
      expect(SoundLevelScale.darwin.normalize(double.nan), 0.0);
      expect(SoundLevelScale.darwin.normalize(double.negativeInfinity), 0.0);
      expect(SoundLevelScale.darwin.normalize(double.infinity), 1.0);
    });
  });
}

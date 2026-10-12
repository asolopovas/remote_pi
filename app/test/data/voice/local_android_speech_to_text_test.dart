import 'dart:convert';

import 'package:app/data/voice/speech_service.dart';
import 'package:app/ui/chat/voice/states/voice_input_state.dart';
import 'package:app/ui/chat/voice/viewmodels/voice_input_viewmodel.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speech_to_text/local_android_speech_to_text.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
// Official upstream platform seam, already locked transitively; no new package.
// ignore: depend_on_referenced_packages
import 'package:speech_to_text_platform_interface/speech_to_text_platform_interface.dart';

const _channel = MethodChannel('plugin.csdcorp.com/speech_to_text');

String _words(String text, {bool finalResult = false}) => jsonEncode({
  'resultType': finalResult ? 2 : 0,
  'alternates': [
    {'recognizedWords': text, 'confidence': 1.0},
  ],
});

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late LocalAndroidSpeechToText platform;
  late SpeechToTextPlatform previous;
  late stt.SpeechToText speech;
  late int id;
  late List<String> calls;
  bool earlyFinal = false;

  Future<void> event(String method, Object payload, {int? captureId}) =>
      platform.processMethodCall(
        MethodCall(method, {'captureId': captureId ?? id, 'payload': payload}),
      );

  setUp(() {
    previous = SpeechToTextPlatform.instance;
    platform = LocalAndroidSpeechToText();
    SpeechToTextPlatform.instance = platform;
    speech = stt.SpeechToText.withMethodChannel();
    id = 0;
    calls = [];
    earlyFinal = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, (call) async {
          calls.add(call.method);
          switch (call.method) {
            case 'initialize':
            case 'has_permission':
              return true;
            case 'locales':
              return ['en_US:English'];
            case 'listen':
              final args = call.arguments as Map;
              id = args['captureId'] as int;
              expect(args['onDevice'], isTrue);
              expect(args['listenMode'], stt.ListenMode.dictation.index);
              if (earlyFinal) {
                await event('notifyStatus', 'notListening');
                await event(
                  'textRecognition',
                  _words('early final', finalResult: true),
                );
                await event('notifyStatus', 'done');
              } else {
                await event('notifyStatus', 'listening');
              }
              return true;
            case 'stop':
              await event('notifyStatus', 'notListening');
              return true;
            case 'cancel':
              return true;
          }
          throw StateError('Unexpected native method ${call.method}');
        });
  });

  tearDown(() async {
    await speech.cancel();
    SpeechToTextPlatform.instance = previous;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, null);
  });

  for (final code in ['error_no_match', 'error_speech_timeout']) {
    for (final ending in ['natural', 'manual', 'final']) {
      test('$code after $ending retains words without VoiceFailed', () async {
        final service = SpeechToTextService(
          SttPluginImpl(speech),
          null,
          const Duration(milliseconds: 40),
        );
        final vm = VoiceInputViewModel(service);
        final texts = <String>[];
        vm.transcripts.listen(texts.add);
        await vm.startRecording();
        await event('textRecognition', _words('synthetic partial'));
        Future<String>? stopping;
        if (ending == 'manual') stopping = vm.stopAndTranscribe();
        if (ending == 'natural') {
          await event('notifyStatus', 'notListening');
        }
        if (ending == 'final') {
          await event(
            'textRecognition',
            _words('synthetic final', finalResult: true),
          );
        }
        await event(
          'notifyError',
          jsonEncode({'errorMsg': code, 'permanent': true}),
        );
        if (ending != 'final') {
          // A benign terminal callback must not fence a queued real final.
          await event(
            'textRecognition',
            _words('synthetic final', finalResult: true),
          );
        }
        await stopping;
        await Future<void>.delayed(const Duration(milliseconds: 60));
        expect(vm.state, isA<VoiceIdle>());
        expect(texts.last, 'synthetic final');
        vm.dispose();
        service.dispose();
      });
    }
    test('$code with no speech ends idle with no transcript', () async {
      final service = SpeechToTextService(
        SttPluginImpl(speech),
        null,
        const Duration(milliseconds: 20),
      );
      final vm = VoiceInputViewModel(service);
      final texts = <String>[];
      vm.transcripts.listen(texts.add);
      await vm.startRecording();
      await event(
        'notifyError',
        jsonEncode({'errorMsg': code, 'permanent': true}),
      );
      await Future<void>.delayed(const Duration(milliseconds: 40));
      expect(vm.state, isA<VoiceIdle>());
      expect(texts, isEmpty);
      expect(calls.last, 'cancel');
      vm.dispose();
      service.dispose();
    });
  }

  for (final code in [
    'error_audio_error',
    'error_client',
    'error_permission',
    'error_network',
    'error_network_timeout',
    'error_busy',
    'error_server',
    'error_language_not_supported',
    'error_language_unavailable',
    'error_server_disconnected',
    'error_too_many_requests',
    'error_unknown (99)',
    'unrecognized_error',
  ]) {
    test('$code remains a failure even with words and after stop', () async {
      final service = SpeechToTextService(SttPluginImpl(speech));
      final vm = VoiceInputViewModel(service);
      final texts = <String>[];
      vm.transcripts.listen(texts.add);
      await vm.startRecording();
      await event('textRecognition', _words('synthetic retained'));
      final stopping = vm.stopAndTranscribe();
      await Future<void>.delayed(Duration.zero);
      await event(
        'notifyError',
        jsonEncode({'errorMsg': code, 'permanent': false}),
      );
      expect(await stopping, 'synthetic retained');
      expect(vm.state, isA<VoiceFailed>());
      expect(texts.last, 'synthetic retained');
      vm.dispose();
      service.dispose();
    });
  }

  test(
    'actual vendor adapter accepts final after stop, fences queued old IDs',
    () async {
      final service = SpeechToTextService(SttPluginImpl(speech));
      expect(
        await service.init(preferredLocaleId: 'en_US'),
        const SpeechReady('en_US'),
      );
      final live = <String>[];
      var errors = 0;
      await service.start(
        localeId: 'en_US',
        maxDuration: const Duration(seconds: 60),
        onTranscript: live.add,
        onError: () => errors++,
      );
      final firstId = id;
      await event('textRecognition', _words('one'));
      await event('textRecognition', _words('won two'));
      final stopping = service.stop();
      await Future<void>.delayed(Duration.zero);
      await event(
        'textRecognition',
        _words('won two three', finalResult: true),
      );
      expect(await stopping, 'won two three');
      expect(live, ['one', 'won two', 'won two three']);
      expect(calls.last, 'cancel');
      await service.start(
        localeId: 'en_US',
        maxDuration: const Duration(seconds: 60),
        onTranscript: live.add,
        onError: () => errors++,
      );
      expect(id, greaterThan(firstId));
      await event(
        'textRecognition',
        _words('stale final', finalResult: true),
        captureId: firstId,
      );
      await event('notifyStatus', 'notListening', captureId: firstId);
      await event(
        'notifyError',
        jsonEncode({'errorMsg': 'stale', 'permanent': true}),
        captureId: firstId,
      );
      await event('soundLevelChange', 8.0, captureId: firstId);
      expect(speech.isListening, isTrue);
      expect(errors, 0);
      expect(live, ['one', 'won two', 'won two three']);
      await service.cancel();
      await event(
        'textRecognition',
        _words('cancelled final', finalResult: true),
      );
      expect(live.length, 3);
      service.dispose();
    },
  );

  test(
    'initialized singleton rebinds owner listeners and forwards current stop errors',
    () async {
      var oldStatuses = 0;
      var newStatuses = 0;
      final errors = <SttError>[];
      final oldOwner = SttPluginImpl(speech);
      await oldOwner.initialize(onStatus: (_) => oldStatuses++);
      final newOwner = SttPluginImpl(speech);
      await newOwner.initialize(
        onStatus: (_) => newStatuses++,
        onError: errors.add,
      );
      await newOwner.listen(
        localeId: 'en_US',
        listenFor: const Duration(seconds: 60),
        onResult: (_, _) {},
        onLevel: (_) {},
      );
      await newOwner.stop();
      await event(
        'notifyError',
        jsonEncode({'errorMsg': 'error_client', 'permanent': true}),
      );
      expect(oldStatuses, 0);
      expect(newStatuses, 2);
      expect(errors.single.code, 'error_client');
      expect(errors.single.permanent, isTrue);
    },
  );

  test(
    'completed early final cannot resurrect VoiceRecording after native listen reply',
    () async {
      earlyFinal = true;
      final service = SpeechToTextService(SttPluginImpl(speech));
      final vm = VoiceInputViewModel(service);
      final states = <VoiceInputState>[];
      vm.addListener(() => states.add(vm.state));
      final texts = <String>[];
      final sub = vm.transcripts.listen(texts.add);
      await vm.startRecording();
      await Future<void>.delayed(Duration.zero);
      expect(vm.state, isA<VoiceIdle>());
      expect(states.whereType<VoiceRecording>(), isEmpty);
      expect(texts, everyElement('early final'));
      await sub.cancel();
      vm.dispose();
      service.dispose();
    },
  );
}

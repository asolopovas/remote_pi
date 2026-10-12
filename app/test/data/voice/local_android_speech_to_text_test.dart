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
      var errors = 0;
      final oldOwner = SttPluginImpl(speech);
      await oldOwner.initialize(onStatus: (_) => oldStatuses++);
      final newOwner = SttPluginImpl(speech);
      await newOwner.initialize(
        onStatus: (_) => newStatuses++,
        onError: () => errors++,
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
      expect(errors, 1);
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

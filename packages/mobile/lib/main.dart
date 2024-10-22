import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:logger/web.dart';
import 'package:mobile/widget/pull_to/pull_to.dart';
import 'package:model/controller/device_tilt.dart';
import 'package:model/controller/session.dart';
import 'package:model/firebase_options.dart';
import 'package:model/controller/latest_memo.dart';
import 'package:rich_text_editor/text_editor/rich_text_editor.dart';
import 'package:rich_text_editor/controller/rich_text_editor_controller.dart';
import 'package:rich_text_editor/toolbar/rich_text_editor_toolbar.dart';
import 'package:widgets/widget.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeFirebase();
  runApp(
    ProviderScope(
      observers: [_AppObserver()],
      child: const MyApp(),
    ),
  );
}

class _AppObserver extends ProviderObserver {
  @override
  void didUpdateProvider(
    ProviderBase<Object?> provider,
    Object? previousValue,
    Object? newValue,
    ProviderContainer container,
  ) {
    if (newValue is AsyncError) {
      final logger = Logger();
      logger.e(
        newValue.error.toString(),
        error: newValue.error,
        stackTrace: newValue.stackTrace,
      );
    }
  }

  @override
  void providerDidFail(
    ProviderBase<Object?> provider,
    Object error,
    StackTrace stackTrace,
    ProviderContainer container,
  ) {
    final logger = Logger();
    logger.e(
      error,
      error: error,
      stackTrace: stackTrace,
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: TokeruTheme.light,
      darkTheme: TokeruTheme.dark,
      themeMode: ThemeMode.light,
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends HookConsumerWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Timer? debounce;
    final session = ref.watch(sessionProvider);
    final controller = ref.watch(richTextEditorControllerProvider.notifier);
    final editorState = ref.watch(richTextEditorControllerProvider);
    ref.listen(latestMemoProvider, (previous, next) {
      final previousMemoId = previous?.valueOrNull?.id;
      final memo = next.valueOrNull;
      if (memo?.session != session || memo?.id != previousMemoId) {
        controller.updateContent(memo?.content ?? '');
      }
    });

    final focusNode = FocusNode();

    final deviceTilt = ref.watch(deviceTiltProvider);
    ref.listen(deviceTiltProvider, (previous, next) {
      if (next == DeviceTiltState.right || next == DeviceTiltState.left) {
        HapticFeedback.lightImpact();
      }
    });

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          PullToControl(
            child: RichTextEditor(
              header: SizedBox(height: MediaQuery.paddingOf(context).top),
              footer: const SizedBox(height: 100),
              editorState: editorState,
              focusNode: focusNode,
              padding: MediaQuery.paddingOf(context),
              onContentChanged: (content) {
                if (debounce?.isActive ?? false) {
                  debounce?.cancel();
                }
                debounce = Timer(const Duration(milliseconds: 400), () {
                  ref.read(latestMemoProvider.notifier).updateMemo(content);
                });
              },
            ),
            onPull: (count) async {
              if (count >= 1) {
                for (var i = 0; i < count; i++) {
                  controller.addNewLineAndMoveCursorToStart();
                }
              }
            },
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: RichTextEditorToolbar(
              leftAddPadding: deviceTilt == DeviceTiltState.right ? 100 : 0,
              rightAddPadding: deviceTilt == DeviceTiltState.left ? 100 : 0,
              controller: controller,
            ),
          ),
        ],
      ),
    );
  }
}

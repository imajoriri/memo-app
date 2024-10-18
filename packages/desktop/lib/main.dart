import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:logger/web.dart';
import 'package:model/controller/latest_memo.dart';
import 'package:model/controller/session.dart';
import 'package:model/firebase_options.dart';
import 'package:rich_text_editor/text_editor/rich_text_editor.dart';
import 'package:rich_text_editor/controller/rich_text_editor_controller.dart';

@pragma('vm:entry-point')
void panel() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeFirebase();

  const methodChannel = MethodChannel('panel_window');

  await hotKeyManager.unregisterAll();
  final hotKey = HotKey(
    key: PhysicalKeyboardKey.keyM,
    modifiers: [HotKeyModifier.control, HotKeyModifier.shift],
  );
  await hotKeyManager.register(
    hotKey,
    keyDownHandler: (hotKey) {
      methodChannel.invokeMethod('open');
    },
  );

  methodChannel.setMethodCallHandler((call) async {
    switch (call.method) {
      case 'active':
        break;
      case 'inactive':
        methodChannel.invokeMethod('close');
        break;
    }
    return null;
  });
  runApp(
    ProviderScope(
      observers: [_AppObserver()],
      child: MaterialApp(
        home: HookConsumer(builder: (context, ref, child) {
          final textEditingController = useTextEditingController();
          final focusNode = useFocusNode();
          return Scaffold(
            body: TextField(
              controller: textEditingController,
              focusNode: focusNode,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
              onSubmitted: (value) {
                ref.read(latestMemoProvider.notifier).addToBottom(value);
                textEditingController.clear();
                focusNode.requestFocus();
              },
            ),
          );
        }),
      ),
    ),
  );
}

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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
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

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: RichTextEditor(
                expands: false,
                editorState: editorState,
                padding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                onContentChanged: (content) {
                  if (debounce?.isActive ?? false) {
                    debounce?.cancel();
                  }
                  debounce = Timer(const Duration(milliseconds: 400), () {
                    ref.read(latestMemoProvider.notifier).updateMemo(content);
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

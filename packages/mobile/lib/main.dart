import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:logger/web.dart';
import 'package:model/controller/session.dart';
import 'package:model/firebase_options.dart';
import 'package:model/controller/latest_memo.dart';
import 'package:widgets/text_editor/rich_text_editor.dart';
import 'package:widgets/text_editor/rich_text_editor_controller.dart';
import 'package:widgets/text_editor/rich_text_editor_toolbar.dart';

@pragma('vm:entry-point')
void sharedExtension() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeFirebase();

  runApp(
    ProviderScope(
      observers: [_AppObserver()],
      child: MaterialApp(
        home: HookConsumer(builder: (context, ref, child) {
          return Scaffold(
            body: Text('panel'),
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
    final controller = useRichTextEditorController();
    controller.onReplaceText = (index, len, data) {
      if (debounce?.isActive ?? false) {
        debounce?.cancel();
      }

      debounce = Timer(const Duration(milliseconds: 400), () {
        ref.read(latestMemoProvider.notifier).updateMemo(controller.content);
      });
      return true;
    };
    final session = ref.watch(sessionProvider);
    ref.listen(latestMemoProvider, (previous, next) {
      final previousMemoId = previous?.valueOrNull?.id;
      final memo = next.valueOrNull;
      if (memo?.session != session || memo?.id != previousMemoId) {
        controller.content = memo?.content ?? '';
      }
    });

    final focusNode = useFocusNode();

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          controller.addNewLineAndFocusTop();
        },
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: RichTextEditor(
                controller: controller,
                focusNode: focusNode,
              ),
            ),
            RichTextEditorToolbar(
              controller: controller,
            ),
          ],
        ),
      ),
    );
  }
}

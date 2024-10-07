import 'dart:async';

import 'package:flutter/cupertino.dart';
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
    final scrollController = useScrollController();

    return Scaffold(
      // GestureDetectorだとonPointerMoveが呼ばれないのでListenerを使う。
      body: Listener(
        onPointerMove: (event) {
          final keyboardRect = MediaQuery.of(context).viewInsets.bottom;
          final bottomPosition =
              MediaQuery.of(context).size.height - event.position.dy;
          // ドラッグがキーボードよりも上の位置から下の位置に移動したら、キーボードを閉じる
          if (bottomPosition < keyboardRect) {
            // scrollControllerが0より小さい場合はpull to add中なのでskipする
            if (scrollController.position.pixels < 0) {
              return;
            }
            focusNode.unfocus();
          }
        },
        child: GestureDetector(
          onTap: () {
            focusNode.requestFocus();
            controller.moveCursorToEnd();
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              CustomScrollView(
                controller: scrollController,
                shrinkWrap: true,
                slivers: [
                  CupertinoSliverRefreshControl(
                    onRefresh: () async {
                      controller.addNewLineAndMoveCursorToStart();
                      focusNode.requestFocus();
                    },
                    builder: (context, mode, pulledExtent,
                        refreshTriggerPullDistance, refreshIndicatorExtent) {
                      return Container(
                        alignment: Alignment.topCenter,
                        padding: const EdgeInsets.only(top: 80),
                        child: const Text('add to top'),
                      );
                    },
                  ),
                  SliverToBoxAdapter(
                    child: RichTextEditor(
                      expands: false,
                      controller: controller,
                      focusNode: focusNode,
                      padding: const EdgeInsets.symmetric(
                          vertical: 80, horizontal: 16),
                    ),
                  ),
                ],
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: RichTextEditorToolbar(
                  controller: controller,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

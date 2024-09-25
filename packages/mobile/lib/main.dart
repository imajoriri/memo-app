import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:logger/web.dart';
import 'package:model/firebase_options.dart';
import 'package:model/controller/latest_memo.dart';

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
    final textEditingController = useTextEditingController();
    ref.listen(latestMemoProvider, (previous, next) {
      final content = next.valueOrNull?.content;
      if (content != textEditingController.text) {
        textEditingController.text = content!;
      }
    });

    final ops = jsonDecode(
        r'[{"insert": "https://hoge.com", "attributes": {"link": "https://hoge.com"}}, {"insert": "\n"}]');
    final controller = QuillController(
      document: Document.fromDelta(Delta.fromJson(ops)),
      selection: const TextSelection.collapsed(offset: 0),
    );

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ref.read(latestMemoProvider.notifier).createMemo();
        },
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: QuillEditor.basic(
          controller: controller,
          configurations: const QuillEditorConfigurations(
            expands: true,
            padding: EdgeInsets.all(16),
          ),
        ),
        // child: Padding(
        //   padding: const EdgeInsets.all(8.0),
        //   child: TextField(
        //     controller: textEditingController,
        //     expands: true,
        //     maxLines: null,
        //     onChanged: (value) {
        //       ref.read(latestMemoProvider.notifier).updateMemo(value);
        //     },
        //   ),
        // ),
      ),
    );
  }
}

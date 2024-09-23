import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:logger/web.dart';
import 'package:model/controller/latest_memo.dart';
import 'package:model/firebase_options.dart';

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
    final textEditingController = useTextEditingController();
    ref.listen(latestMemoProvider, (previous, next) {
      final content = next.valueOrNull?.content;
      if (content != textEditingController.text) {
        textEditingController.text = content!;
      }
    });

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ref.read(latestMemoProvider.notifier).createMemo();
        },
        child: const Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: TextField(
          controller: textEditingController,
          expands: true,
          maxLines: null,
          onChanged: (value) {
            ref.read(latestMemoProvider.notifier).updateMemo(value);
          },
        ),
      ),
    );
  }
}

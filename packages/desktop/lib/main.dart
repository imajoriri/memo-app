import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:logger/web.dart';
import 'package:model/controller/global_memo.dart';
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
                ref.read(globalMemoProvider.notifier).addToBottom(value);
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
    final textEditingController = TextEditingController();
    ref.listen(globalMemoProvider, (previous, next) {
      if (next.valueOrNull != textEditingController.text &&
          next.valueOrNull?.isNotEmpty == true) {
        textEditingController.text = next.requireValue;
      }
    });

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Flutter Demo Home Page'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: TextField(
          controller: textEditingController,
          expands: true,
          maxLines: null,
          onChanged: (value) {
            ref.read(globalMemoProvider.notifier).updateMemo(value);
          },
        ),
      ),
    );
  }
}

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:logger/web.dart';
import 'package:model/controller/latest_memo.dart';
import 'package:model/firebase_options.dart';
import 'package:model/systems/launch_url.dart';
import 'package:widgets/async/url_future_builder.dart';

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

    // https://hoge.com を表示する。
    final ops = jsonDecode(
        r'[{"insert": "https://hoge2.com", "attributes": {"link": "https://hoge.com"}}, {"insert": "\n"}]');
    final controller = QuillController(
      document: Document.fromDelta(Delta.fromJson(ops)),
      selection: const TextSelection.collapsed(offset: 0),
    );
    controller.addListener(() {
      // print(controller.document.toDelta().toJson());
      // print(controller.pastePlainText);
    });
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ref.read(latestMemoProvider.notifier).createMemo();
        },
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          QuillSimpleToolbar(
            controller: controller,
            configurations: const QuillSimpleToolbarConfigurations(),
          ),
          Expanded(
            child: QuillEditor.basic(
              controller: controller,
              configurations: QuillEditorConfigurations(
                expands: true,
                customActions: {
                  PasteTextIntent: CallbackAction(onInvoke: (intent) async {
                    final text = await Clipboard.getData(Clipboard.kTextPlain);
                    // textがurlかどうか。
                    final url = Uri.tryParse(text?.text ?? '');
                    if (url != null && url.hasAbsolutePath) {
                      _createUrlPreview(
                        url: url.toString(),
                        controller: controller,
                      );
                      return true;
                    }
                    controller.clipboardPaste();
                    return null;
                  }),
                },
                padding: const EdgeInsets.all(16),
                spaceShortcutEvents: standardSpaceShorcutEvents,
                characterShortcutEvents: standardCharactersShortcutEvents,
                embedBuilders: [UrlPreviewEmbedBuilder()],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _createUrlPreview({
    required String url,
    required QuillController controller,
  }) async {
    final block = BlockEmbed.custom(
      UrlPreviewBlockEmbed.fromUrl(url),
    );
    final index = controller.selection.baseOffset;
    final length = controller.selection.extentOffset - index;

    controller.replaceText(index, length, block, null);
  }
}

class UrlPreviewBlockEmbed extends CustomBlockEmbed {
  final String url;

  UrlPreviewBlockEmbed.fromUrl(this.url) : super('url_preview', url);

  Document get document => Document.fromJson(jsonDecode(data));
}

class UrlPreviewEmbedBuilder extends EmbedBuilder {
  @override
  String get key => 'url_preview';

  @override
  String toPlainText(Embed node) => node.value.data;

  @override
  bool get expanded => false;

  @override
  Widget build(
    BuildContext context,
    QuillController controller,
    Embed node,
    bool readOnly,
    bool inline,
    TextStyle textStyle,
  ) {
    return GestureDetector(
      onTap: () {
        launchUrl(Uri.parse(node.value.data));
      },
      child: FocusableActionDetector(
        mouseCursor: SystemMouseCursors.click,
        child: Container(
          color: Colors.red,
          alignment: Alignment.centerLeft,
          // TODO: 横幅目一杯に広がってしまうのを防ぐ。
          child: UrlFutureBuilder(
            url: Uri.parse(node.value.data),
            data: (ogp) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (ogp.iconUrl != null)
                  Image.network(
                    ogp.iconUrl!,
                    width: 16,
                    height: 16,
                  ),
                const SizedBox(width: 8),
                Text(
                  ogp.title ?? '',
                  style: textStyle,
                ),
              ],
            ),
            loading: () => const CircularProgressIndicator(),
            error: (e, s) => Text(e.toString()),
          ),
        ),
      ),
    );
  }
}

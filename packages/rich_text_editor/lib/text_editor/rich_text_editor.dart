import 'dart:convert';

import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:rich_text_editor/text_editor/rich_text_editor_controller.dart';

class RichTextEditor extends HookWidget {
  const RichTextEditor({
    super.key,
    required this.editorState,
    this.focusNode,
    this.scrollController,
    this.expands = true,
    this.scrollPhysics,
    this.padding,
    this.onContentChanged,
  });

  final RichTextEditorState editorState;
  final FocusNode? focusNode;
  final ScrollController? scrollController;
  final bool expands;
  final ScrollPhysics? scrollPhysics;
  final EdgeInsets? padding;
  final Function(String)? onContentChanged;

  @override
  Widget build(BuildContext context) {
    final editorScrollController = EditorScrollController(
      editorState: editorState,
    );
    editorState.transactionStream.listen((event) {
      if (event.$1 == TransactionTime.after) {
        onContentChanged?.call(jsonEncode(event.$2.document.toJson()));
      }
    });
    final blockComponentBuilders = useState(_buildBlockComponentBuilders());
    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: AppFlowyEditor(
        focusNode: focusNode,
        editorState: editorState,
        editorScrollController: editorScrollController,
        enableAutoComplete: true,
        shrinkWrap: true,
        editorStyle: const EditorStyle.mobile(
          padding: EdgeInsets.zero,
          textStyleConfiguration: TextStyleConfiguration(
            text: TextStyle(
              fontSize: 16,
              color: Colors.black,
            ),
          ),
        ),
        blockComponentBuilders: blockComponentBuilders.value,
        commandShortcutEvents: [
          ...standardCommandShortcutEvents,
        ],
        characterShortcutEvents: [
          ...standardCharacterShortcutEvents,
        ],
        autoFocus: true,
      ),
    );
    // return MobileToolbarV2(
    //   toolbarHeight: 48.0,
    //   toolbarItems: [
    //     textDecorationMobileToolbarItemV2,
    //     buildTextAndBackgroundColorMobileToolbarItem(),
    //     blocksMobileToolbarItem,
    //     linkMobileToolbarItem,
    //     dividerMobileToolbarItem,
    //   ],
    //   editorState: editorState,
    //   child: MobileFloatingToolbar(
    //     editorState: editorState,
    //     editorScrollController: editorScrollController,
    //     toolbarBuilder: (context, anchor, closeToolbar) {
    //       return AdaptiveTextSelectionToolbar.editable(
    //         clipboardStatus: ClipboardStatus.pasteable,
    //         onCopy: () {
    //           copyCommand.execute(editorState);
    //           closeToolbar();
    //         },
    //         onCut: () => cutCommand.execute(editorState),
    //         onPaste: () => pasteCommand.execute(editorState),
    //         onSelectAll: () => selectAllCommand.execute(editorState),
    //         onLiveTextInput: null,
    //         onLookUp: null,
    //         onSearchWeb: null,
    //         onShare: null,
    //         anchors: TextSelectionToolbarAnchors(
    //           primaryAnchor: anchor,
    //         ),
    //       );
    //     },
    //     child: Padding(
    //       padding: padding ?? EdgeInsets.zero,
    //       child: AppFlowyEditor(
    //         focusNode: focusNode,
    //         editorState: editorState,
    //         editorScrollController: editorScrollController,
    //         enableAutoComplete: true,
    //         shrinkWrap: true,
    //         editorStyle: const EditorStyle.mobile(
    //           padding: EdgeInsets.zero,
    //         ),
    //         commandShortcutEvents: [
    //           ...standardCommandShortcutEvents,
    //         ],
    //         autoFocus: true,
    //       ),
    //     ),
    //   ),
    // );
  }
}

Map<String, BlockComponentBuilder> _buildBlockComponentBuilders() {
  final map = {
    ...standardBlockComponentBuilderMap,
  };
  // Headerをカスタマイズ
  final levelToFontSize = isMobile
      ? [
          24.0,
          20.0,
          16.0,
          14.0,
          12.0,
          10.0,
        ]
      : [
          30.0,
          26.0,
          22.0,
          18.0,
          16.0,
          14.0,
        ];
  map[HeadingBlockKeys.type] = HeadingBlockComponentBuilder(
    textStyleBuilder: (level) => TextStyle(
      fontSize: levelToFontSize.elementAtOrNull(level - 1) ?? 14.0,
      fontWeight: FontWeight.w700,
    ),
  );

  map.forEach((key, value) {
    // 1行ごとのpaddingを設定
    value.configuration = value.configuration.copyWith(
      padding: (_) => const EdgeInsets.symmetric(vertical: 8.0),
    );
  });
  return map;
}

final isMobile = switch (defaultTargetPlatform) {
  TargetPlatform.android || TargetPlatform.iOS => true,
  _ => false,
};

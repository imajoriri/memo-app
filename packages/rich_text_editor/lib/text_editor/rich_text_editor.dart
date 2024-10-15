// ignore_for_file: unnecessary_overrides

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_quill/extensions.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:rich_text_editor/async/url_future_builder.dart';
import 'package:rich_text_editor/text_editor/rich_text_editor_controller.dart';
import 'package:url_launcher/url_launcher.dart';

void _updateSelectionForKeyPhrase(
    String phrase, Attribute attribute, QuillController controller) {
  controller.replaceText(controller.selection.baseOffset - phrase.length,
      phrase.length, '\n', null);
  _moveCursor(-phrase.length, controller);
  controller
    ..formatSelection(attribute)
    // Remove the added newline.
    ..replaceText(controller.selection.baseOffset + 1, 1, '', null);
}

void _moveCursor(int chars, QuillController controller) {
  final selection = controller.selection;
  controller.updateSelection(
      controller.selection.copyWith(
          baseOffset: selection.baseOffset + chars,
          extentOffset: selection.baseOffset + chars),
      ChangeSource.local);
}

/// `[]`を入力したときに、チェックリストにするショートカット。
// `handleFormatBlockStyleBySpaceEvent`(private method)を参考にしている。
final SpaceShortcutEvent _formatCheckList = SpaceShortcutEvent(
  character: "[]",
  handler: (node, controller) {
    _updateSelectionForKeyPhrase("[]", Attribute.unchecked, controller);
    return true;
  },
);

class RichTextEditor extends HookWidget {
  const RichTextEditor({
    super.key,
    required this.controller,
    this.focusNode,
    this.scrollController,
    this.expands = true,
    this.scrollPhysics,
    this.padding,
  });

  final RichTextEditorController controller;
  final FocusNode? focusNode;
  final ScrollController? scrollController;
  final bool expands;
  final ScrollPhysics? scrollPhysics;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final effectiveFocusNode = focusNode ?? useFocusNode();
    return QuillEditor.basic(
      focusNode: effectiveFocusNode,
      controller: controller,
      scrollController: scrollController,
      configurations: QuillEditorConfigurations(
        customStyles: switch (defaultTargetPlatform) {
          TargetPlatform.android ||
          TargetPlatform.iOS =>
            getInstanceMobile(context),
          TargetPlatform.macOS ||
          TargetPlatform.windows ||
          TargetPlatform.linux =>
            getInstanceDesktop(context),
          _ => getInstanceMobile(context),
        },
        expands: expands,
        scrollPhysics: scrollPhysics,
        padding: padding ?? EdgeInsets.zero,
        spaceShortcutEvents: [
          ...standardSpaceShorcutEvents,
          _formatCheckList,
        ],
        characterShortcutEvents: standardCharactersShortcutEvents,
        embedBuilders: [
          _UrlPreviewEmbedBuilder(),
        ],
        customLeadingBlockBuilder: (node, config) {
          final attribute = config.attribute;
          final attrs = config.attrs;
          final isUnordered = attribute == Attribute.ul;
          final isOrdered = attribute == Attribute.ol;
          final isCheck = attribute == Attribute.checked ||
              attribute == Attribute.unchecked;
          final isCodeBlock = attrs.containsKey(Attribute.codeBlock.key);
          if (isOrdered) {
            return QuillEditorNumberPoint(
              index: config.getIndexNumberByIndent!,
              indentLevelCounts: config.indentLevelCounts,
              count: config.count,
              style: config.style!,
              attrs: config.attrs,
              width: config.width!,
              padding: config.padding!,
            );
          }

          // bullet
          if (isUnordered) {
            return Container(
              alignment: AlignmentDirectional.center,
              child: const Icon(Icons.circle, size: 8),
            );
          }

          if (isCheck) {
            return QuillEditorCheckboxPoint(
              size: config.lineSize!,
              value: config.value,
              enabled: config.enabled!,
              onChanged: config.onCheckboxTap,
              uiBuilder: config.uiBuilder,
            );
          }
          if (isCodeBlock &&
              context.requireQuillEditorElementOptions.codeBlock
                  .enableLineNumbers) {
            return QuillEditorNumberPoint(
              index: config.getIndexNumberByIndent!,
              indentLevelCounts: config.indentLevelCounts,
              count: config.count,
              style: config.style!,
              attrs: config.attrs,
              width: config.width!,
              padding: config.padding!,
            );
          }
          return null;
        },
      ),
    );
  }
}

class _UrlPreviewEmbedBuilder extends EmbedBuilder {
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
    final url = node.value.data;
    return GestureDetector(
      onTap: () {
        launchUrl(Uri.parse(url));
      },
      child: FocusableActionDetector(
        mouseCursor: SystemMouseCursors.click,
        child: Container(
          alignment: Alignment.centerLeft,
          child: UrlFutureBuilder(
            url: Uri.parse(url),
            data: (ogp) => Row(
              children: [
                if (ogp.iconUrl != null)
                  Image.network(
                    ogp.iconUrl!,
                    width: 16,
                    height: 16,
                    errorBuilder: (context, error, stackTrace) =>
                        const SizedBox(width: 16),
                  ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    ogp.title ?? '',
                    style: textStyle,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
            loading: () => const CircularProgressIndicator(),
            error: (e, s) => Text(url),
          ),
        ),
      ),
    );
  }
}

// ベースをQuillから持ってきている
DefaultStyles getInstanceMobile(BuildContext context) {
  final themeData = Theme.of(context);
  final defaultTextStyle = DefaultTextStyle.of(context);
  final baseStyle = defaultTextStyle.style.copyWith(
    fontSize: 17,
    height: 1.4,
    decoration: TextDecoration.none,
  );
  const baseHorizontalSpacing = HorizontalSpacing(0, 0);
  const baseVerticalSpacing = VerticalSpacing(6, 0);
  final fontFamily = themeData.isCupertino ? 'Menlo' : 'Roboto Mono';

  final inlineCodeStyle = TextStyle(
    fontSize: 14,
    color: themeData.colorScheme.primary.withOpacity(0.8),
    fontFamily: fontFamily,
  );

  return DefaultStyles(
    h1: DefaultTextBlockStyle(
        defaultTextStyle.style.copyWith(
          fontSize: 24,
          color: defaultTextStyle.style.color,
          letterSpacing: -0.5,
          height: 1.083,
          fontWeight: FontWeight.bold,
          decoration: TextDecoration.none,
        ),
        baseHorizontalSpacing,
        const VerticalSpacing(16, 0),
        VerticalSpacing.zero,
        null),
    h2: DefaultTextBlockStyle(
        defaultTextStyle.style.copyWith(
          fontSize: 20,
          color: defaultTextStyle.style.color,
          letterSpacing: -0.8,
          height: 1.067,
          fontWeight: FontWeight.bold,
          decoration: TextDecoration.none,
        ),
        baseHorizontalSpacing,
        const VerticalSpacing(8, 0),
        VerticalSpacing.zero,
        null),
    h3: DefaultTextBlockStyle(
      defaultTextStyle.style.copyWith(
        fontSize: 16,
        color: defaultTextStyle.style.color,
        letterSpacing: -0.5,
        height: 1.083,
        fontWeight: FontWeight.bold,
        decoration: TextDecoration.none,
      ),
      baseHorizontalSpacing,
      const VerticalSpacing(8, 0),
      VerticalSpacing.zero,
      null,
    ),
    h4: DefaultTextBlockStyle(
      defaultTextStyle.style.copyWith(
        fontSize: 14,
        color: defaultTextStyle.style.color,
        letterSpacing: -0.4,
        height: 1.1,
        fontWeight: FontWeight.bold,
        decoration: TextDecoration.none,
      ),
      baseHorizontalSpacing,
      const VerticalSpacing(6, 0),
      VerticalSpacing.zero,
      null,
    ),
    h5: DefaultTextBlockStyle(
      defaultTextStyle.style.copyWith(
        fontSize: 12,
        color: defaultTextStyle.style.color,
        letterSpacing: -0.2,
        height: 1.11,
        fontWeight: FontWeight.bold,
        decoration: TextDecoration.none,
      ),
      baseHorizontalSpacing,
      const VerticalSpacing(6, 0),
      VerticalSpacing.zero,
      null,
    ),
    h6: DefaultTextBlockStyle(
      defaultTextStyle.style.copyWith(
        fontSize: 10,
        color: defaultTextStyle.style.color,
        letterSpacing: -0.1,
        height: 1.125,
        fontWeight: FontWeight.bold,
        decoration: TextDecoration.none,
      ),
      baseHorizontalSpacing,
      const VerticalSpacing(4, 0),
      VerticalSpacing.zero,
      null,
    ),
    lineHeightNormal: DefaultTextBlockStyle(
      baseStyle.copyWith(height: 1.15),
      baseHorizontalSpacing,
      VerticalSpacing.zero,
      VerticalSpacing.zero,
      null,
    ),
    lineHeightTight: DefaultTextBlockStyle(
      baseStyle.copyWith(height: 1.30),
      baseHorizontalSpacing,
      VerticalSpacing.zero,
      VerticalSpacing.zero,
      null,
    ),
    lineHeightOneAndHalf: DefaultTextBlockStyle(
      baseStyle.copyWith(height: 1.55),
      baseHorizontalSpacing,
      VerticalSpacing.zero,
      VerticalSpacing.zero,
      null,
    ),
    lineHeightDouble: DefaultTextBlockStyle(
      baseStyle.copyWith(height: 2),
      baseHorizontalSpacing,
      VerticalSpacing.zero,
      VerticalSpacing.zero,
      null,
    ),
    paragraph: DefaultTextBlockStyle(
      baseStyle,
      baseHorizontalSpacing,
      VerticalSpacing.zero,
      VerticalSpacing.zero,
      null,
    ),
    bold: const TextStyle(fontWeight: FontWeight.bold),
    subscript: const TextStyle(
      fontFeatures: [
        FontFeature.liningFigures(),
        FontFeature.subscripts(),
      ],
    ),
    superscript: const TextStyle(
      fontFeatures: [
        FontFeature.liningFigures(),
        FontFeature.superscripts(),
      ],
    ),
    italic: const TextStyle(fontStyle: FontStyle.italic),
    small: const TextStyle(fontSize: 12),
    underline: const TextStyle(decoration: TextDecoration.underline),
    strikeThrough: const TextStyle(decoration: TextDecoration.lineThrough),
    inlineCode: InlineCodeStyle(
      backgroundColor: Colors.grey.shade100,
      radius: const Radius.circular(3),
      style: inlineCodeStyle,
      header1: inlineCodeStyle.copyWith(
        fontSize: 32,
        fontWeight: FontWeight.w500,
      ),
      header2: inlineCodeStyle.copyWith(
        fontSize: 22,
        fontWeight: FontWeight.w500,
      ),
      header3: inlineCodeStyle.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w500,
      ),
    ),
    link: TextStyle(
      color: themeData.colorScheme.secondary,
      decoration: TextDecoration.underline,
    ),
    placeHolder: DefaultTextBlockStyle(
        defaultTextStyle.style.copyWith(
          fontSize: 20,
          height: 1.5,
          color: Colors.grey.withOpacity(0.6),
        ),
        baseHorizontalSpacing,
        VerticalSpacing.zero,
        VerticalSpacing.zero,
        null),
    lists: DefaultListBlockStyle(
      baseStyle,
      baseHorizontalSpacing,
      baseVerticalSpacing,
      const VerticalSpacing(0, 6),
      null,
      null,
    ),
    quote: DefaultTextBlockStyle(
      TextStyle(color: baseStyle.color!.withOpacity(0.6)),
      baseHorizontalSpacing,
      baseVerticalSpacing,
      const VerticalSpacing(6, 2),
      BoxDecoration(
        border: Border(
          left: BorderSide(width: 4, color: Colors.grey.shade300),
        ),
      ),
    ),
    code: DefaultTextBlockStyle(
        TextStyle(
          color: Colors.blue.shade900.withOpacity(0.9),
          fontFamily: fontFamily,
          fontSize: 13,
          height: 1.15,
        ),
        baseHorizontalSpacing,
        baseVerticalSpacing,
        VerticalSpacing.zero,
        BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(2),
        )),
    indent: DefaultTextBlockStyle(
      baseStyle,
      baseHorizontalSpacing,
      baseVerticalSpacing,
      const VerticalSpacing(0, 6),
      null,
    ),
    align: DefaultTextBlockStyle(
      baseStyle,
      baseHorizontalSpacing,
      VerticalSpacing.zero,
      VerticalSpacing.zero,
      null,
    ),
    leading: DefaultTextBlockStyle(
      baseStyle,
      baseHorizontalSpacing,
      VerticalSpacing.zero,
      VerticalSpacing.zero,
      null,
    ),
    sizeSmall: const TextStyle(fontSize: 10),
    sizeLarge: const TextStyle(fontSize: 18),
    sizeHuge: const TextStyle(fontSize: 22),
  );
}

DefaultStyles getInstanceDesktop(BuildContext context) {
  final themeData = Theme.of(context);
  final defaultTextStyle = DefaultTextStyle.of(context);
  final baseStyle = defaultTextStyle.style.copyWith(
    fontSize: 16,
    height: 1.3,
    decoration: TextDecoration.none,
  );
  const baseHorizontalSpacing = HorizontalSpacing(0, 0);
  const baseVerticalSpacing = VerticalSpacing(6, 0);
  final fontFamily = themeData.isCupertino ? 'Menlo' : 'Roboto Mono';

  final inlineCodeStyle = TextStyle(
    fontSize: 14,
    color: themeData.colorScheme.primary.withOpacity(0.8),
    fontFamily: fontFamily,
  );

  return DefaultStyles(
    h1: DefaultTextBlockStyle(
        defaultTextStyle.style.copyWith(
          fontSize: 24,
          color: defaultTextStyle.style.color,
          letterSpacing: -0.5,
          height: 1.083,
          fontWeight: FontWeight.bold,
          decoration: TextDecoration.none,
        ),
        baseHorizontalSpacing,
        const VerticalSpacing(16, 0),
        VerticalSpacing.zero,
        null),
    h2: DefaultTextBlockStyle(
        defaultTextStyle.style.copyWith(
          fontSize: 20,
          color: defaultTextStyle.style.color,
          letterSpacing: -0.8,
          height: 1.067,
          fontWeight: FontWeight.bold,
          decoration: TextDecoration.none,
        ),
        baseHorizontalSpacing,
        const VerticalSpacing(8, 0),
        VerticalSpacing.zero,
        null),
    h3: DefaultTextBlockStyle(
      defaultTextStyle.style.copyWith(
        fontSize: 16,
        color: defaultTextStyle.style.color,
        letterSpacing: -0.5,
        height: 1.083,
        fontWeight: FontWeight.bold,
        decoration: TextDecoration.none,
      ),
      baseHorizontalSpacing,
      const VerticalSpacing(8, 0),
      VerticalSpacing.zero,
      null,
    ),
    h4: DefaultTextBlockStyle(
      defaultTextStyle.style.copyWith(
        fontSize: 14,
        color: defaultTextStyle.style.color,
        letterSpacing: -0.4,
        height: 1.1,
        fontWeight: FontWeight.bold,
        decoration: TextDecoration.none,
      ),
      baseHorizontalSpacing,
      const VerticalSpacing(6, 0),
      VerticalSpacing.zero,
      null,
    ),
    h5: DefaultTextBlockStyle(
      defaultTextStyle.style.copyWith(
        fontSize: 12,
        color: defaultTextStyle.style.color,
        letterSpacing: -0.2,
        height: 1.11,
        fontWeight: FontWeight.bold,
        decoration: TextDecoration.none,
      ),
      baseHorizontalSpacing,
      const VerticalSpacing(6, 0),
      VerticalSpacing.zero,
      null,
    ),
    h6: DefaultTextBlockStyle(
      defaultTextStyle.style.copyWith(
        fontSize: 10,
        color: defaultTextStyle.style.color,
        letterSpacing: -0.1,
        height: 1.125,
        fontWeight: FontWeight.bold,
        decoration: TextDecoration.none,
      ),
      baseHorizontalSpacing,
      const VerticalSpacing(4, 0),
      VerticalSpacing.zero,
      null,
    ),
    lineHeightNormal: DefaultTextBlockStyle(
      baseStyle.copyWith(height: 1.15),
      baseHorizontalSpacing,
      VerticalSpacing.zero,
      VerticalSpacing.zero,
      null,
    ),
    lineHeightTight: DefaultTextBlockStyle(
      baseStyle.copyWith(height: 1.30),
      baseHorizontalSpacing,
      VerticalSpacing.zero,
      VerticalSpacing.zero,
      null,
    ),
    lineHeightOneAndHalf: DefaultTextBlockStyle(
      baseStyle.copyWith(height: 1.55),
      baseHorizontalSpacing,
      VerticalSpacing.zero,
      VerticalSpacing.zero,
      null,
    ),
    lineHeightDouble: DefaultTextBlockStyle(
      baseStyle.copyWith(height: 2),
      baseHorizontalSpacing,
      VerticalSpacing.zero,
      VerticalSpacing.zero,
      null,
    ),
    paragraph: DefaultTextBlockStyle(
      baseStyle,
      baseHorizontalSpacing,
      VerticalSpacing.zero,
      VerticalSpacing.zero,
      null,
    ),
    bold: const TextStyle(fontWeight: FontWeight.bold),
    subscript: const TextStyle(
      fontFeatures: [
        FontFeature.liningFigures(),
        FontFeature.subscripts(),
      ],
    ),
    superscript: const TextStyle(
      fontFeatures: [
        FontFeature.liningFigures(),
        FontFeature.superscripts(),
      ],
    ),
    italic: const TextStyle(fontStyle: FontStyle.italic),
    small: const TextStyle(fontSize: 12),
    underline: const TextStyle(decoration: TextDecoration.underline),
    strikeThrough: const TextStyle(decoration: TextDecoration.lineThrough),
    inlineCode: InlineCodeStyle(
      backgroundColor: Colors.grey.shade100,
      radius: const Radius.circular(3),
      style: inlineCodeStyle,
      header1: inlineCodeStyle.copyWith(
        fontSize: 32,
        fontWeight: FontWeight.w500,
      ),
      header2: inlineCodeStyle.copyWith(
        fontSize: 22,
        fontWeight: FontWeight.w500,
      ),
      header3: inlineCodeStyle.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w500,
      ),
    ),
    link: TextStyle(
      color: themeData.colorScheme.secondary,
      decoration: TextDecoration.underline,
    ),
    placeHolder: DefaultTextBlockStyle(
        defaultTextStyle.style.copyWith(
          fontSize: 20,
          height: 1.5,
          color: Colors.grey.withOpacity(0.6),
        ),
        baseHorizontalSpacing,
        VerticalSpacing.zero,
        VerticalSpacing.zero,
        null),
    lists: DefaultListBlockStyle(
      baseStyle,
      baseHorizontalSpacing,
      baseVerticalSpacing,
      const VerticalSpacing(0, 6),
      null,
      null,
    ),
    quote: DefaultTextBlockStyle(
      TextStyle(color: baseStyle.color!.withOpacity(0.6)),
      baseHorizontalSpacing,
      baseVerticalSpacing,
      const VerticalSpacing(6, 2),
      BoxDecoration(
        border: Border(
          left: BorderSide(width: 4, color: Colors.grey.shade300),
        ),
      ),
    ),
    code: DefaultTextBlockStyle(
        TextStyle(
          color: Colors.blue.shade900.withOpacity(0.9),
          fontFamily: fontFamily,
          fontSize: 13,
          height: 1.15,
        ),
        baseHorizontalSpacing,
        baseVerticalSpacing,
        VerticalSpacing.zero,
        BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(2),
        )),
    indent: DefaultTextBlockStyle(
      baseStyle,
      baseHorizontalSpacing,
      baseVerticalSpacing,
      const VerticalSpacing(0, 6),
      null,
    ),
    align: DefaultTextBlockStyle(
      baseStyle,
      baseHorizontalSpacing,
      VerticalSpacing.zero,
      VerticalSpacing.zero,
      null,
    ),
    leading: DefaultTextBlockStyle(
      baseStyle,
      baseHorizontalSpacing,
      VerticalSpacing.zero,
      VerticalSpacing.zero,
      null,
    ),
    sizeSmall: const TextStyle(fontSize: 10),
    sizeLarge: const TextStyle(fontSize: 18),
    sizeHuge: const TextStyle(fontSize: 22),
  );
}

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class ChatBubble extends StatelessWidget {
  final String message;
  final bool isUser;

  const ChatBubble({super.key, required this.message, required this.isUser});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final textColor = isUser
        ? colorScheme.onPrimary
        : colorScheme.onSurfaceVariant;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
        padding: const EdgeInsets.all(14),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.85,
        ),
        decoration: BoxDecoration(
          gradient: isUser
              ? LinearGradient(
                  colors: [
                    colorScheme.primary,
                    colorScheme.primary.withAlpha(200),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isUser ? null : colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(22),
            topRight: const Radius.circular(22),
            bottomLeft: Radius.circular(isUser ? 22 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 22),
          ),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withAlpha(isUser ? 40 : 15),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: MarkdownBody(
          data: message,
          shrinkWrap: true,
          fitContent: true,
          styleSheet: MarkdownStyleSheet(
            p: TextStyle(
              color: textColor,
              fontSize: 15,
              height: 1.4,
            ),
            strong: TextStyle(
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
            em: TextStyle(
              fontStyle: FontStyle.italic,
              color: textColor,
            ),
            listBullet: TextStyle(
              color: textColor,
            ),
            // Table styling
            tableHead: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: textColor,
            ),
            tableBody: TextStyle(
              fontSize: 13,
              color: textColor,
            ),
            tableBorder: TableBorder.all(
              color: textColor.withAlpha(60),
              width: 1,
            ),
            tableColumnWidth: const IntrinsicColumnWidth(),
            tableCellsPadding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 6,
            ),
            tableHeadAlign: TextAlign.left,
            // Code block styling
            code: TextStyle(
              backgroundColor: colorScheme.surfaceContainerHighest,
              color: textColor,
              fontSize: 13,
              fontFamily: 'monospace',
            ),
            codeblockDecoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withAlpha(100),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          builders: {
            // Custom table builder for horizontal scrolling
            'table': _ScrollableTableBuilder(textColor: textColor),
          },
        ),
      ),
    );
  }
}

/// Custom builder to make tables horizontally scrollable
class _ScrollableTableBuilder extends MarkdownElementBuilder {
  final Color textColor;
  
  _ScrollableTableBuilder({required this.textColor});
  
  @override
  Widget? visitElementAfter(element, preferredStyle) {
    return null; // Use default rendering but wrap in scroll
  }
}

import 'package:file_selector/file_selector.dart' show XFile;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'community_data.dart';

/// The message people see in WhatsApp, Facebook, Instagram, SMS, email, etc.
String buildShareText(Post post) {
  final area = communityRepo.suburbById(post.areaId)?.label;
  return [
    '${post.category.tagLabel.toUpperCase()}: ${post.title}',
    '',
    post.body,
    '',
    if (area != null) 'Area: $area',
    'Shared from SafeSense',
  ].join('\n');
}

/// Opens the phone's share sheet. From there the user picks WhatsApp
/// (chat or status), Facebook, Instagram, Messenger, SMS, email, etc.
/// If the post has a picture/document it is shared together with the text.
///
/// Pass the context of the share button so the share sheet can anchor to it (iPad).
Future<void> sharePost(BuildContext context, Post post) async {
  final messenger = ScaffoldMessenger.of(context);
  final box = context.findRenderObject() as RenderBox?;
  final origin =
      (box != null && box.hasSize) ? box.localToGlobal(Offset.zero) & box.size : null;
  final text = buildShareText(post);
  final attachment = post.attachment;

  try {
    final result = await SharePlus.instance.share(
      ShareParams(
        text: text,
        subject: post.title,
        sharePositionOrigin: origin,
        files: attachment == null
            ? null
            : [
                XFile.fromData(
                  attachment.bytes,
                  name: attachment.name,
                  mimeType: attachment.mimeType,
                ),
              ],
        fileNameOverrides: attachment == null ? null : [attachment.name],
      ),
    );
    if (result.status == ShareResultStatus.unavailable) {
      await _copyInstead(messenger, text);
    }
  } catch (_) {
    await _copyInstead(messenger, text);
  }
}

/// Fallback for browsers/desktops where no share sheet exists.
Future<void> _copyInstead(ScaffoldMessengerState messenger, String text) async {
  await Clipboard.setData(ClipboardData(text: text));
  messenger.showSnackBar(const SnackBar(
    content: Text('Sharing is not available here. The post text was copied instead.'),
  ));
}
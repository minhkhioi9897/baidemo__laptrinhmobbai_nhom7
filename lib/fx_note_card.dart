import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'fx.dart';
import 'fx_delete.dart';

/// Thẻ dùng chung cho GHI CHÚ và NHẬT KÝ (giao diện kính theo theme sáng/tối) + nút xoá "Thanos".
///
/// Ghi chú:
///   FxNoteCard(key: ValueKey(note.id), title: note.title, body: note.content, time: 'Hôm nay, 09:30',
///              onTap: () => moTrangSua(note), onDeleted: () => xoaGhiChu(note))
/// Nhật ký (thêm biểu tượng cảm xúc bên trái):
///   FxNoteCard(key: ValueKey(e.id), leading: Text('😊', style: TextStyle(fontSize: 30)), title: ..., body: ..., time: ...,
///              accent: Color(0xFFA78BFA), onDeleted: () => xoaNhatKy(e))
class FxNoteCard extends StatelessWidget {
  final String title, body, time;
  final Widget? leading;
  final VoidCallback? onTap;
  final VoidCallback onDeleted; // gọi SAU khi hiệu ứng tan biến xong -> xoá dữ liệu + setState ở đây
  final VoidCallback? onDeleteStart;
  final Color? accent;

  const FxNoteCard({
    super.key,
    required this.title,
    required this.body,
    required this.time,
    required this.onDeleted,
    this.leading,
    this.onTap,
    this.onDeleteStart,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<VoiceColors>()!;
    final edge = accent ?? c.accent;
    final r = BorderRadius.circular(22);

    return FxDeletable(
      onDeleted: onDeleted,
      onStart: onDeleteStart,
      color: c.danger,
      dust: Color.lerp(edge, c.danger, .5)!,
      builder: (context, del) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: FxPress(
          onTap: onTap,
          radius: r,
          burstColor: edge,
          scale: .97,
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
            decoration: BoxDecoration(
              borderRadius: r,
              gradient: LinearGradient(
                  begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [c.cardTop, c.cardBottom]),
              border: Border.all(color: c.useEdge ? edge.withAlpha(150) : c.cardBorder, width: 1.4),
              boxShadow: [
                BoxShadow(
                  color: c.useEdge ? edge.withAlpha(40) : c.cardShadow,
                  blurRadius: 16,
                  offset: Offset(0, c.useEdge ? 0 : 6),
                ),
              ],
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
              if (leading != null) ...[leading!, const SizedBox(width: 12)],
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: c.text)),
                  const SizedBox(height: 4),
                  Text(body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 14.5, color: c.sub)),
                  const SizedBox(height: 8),
                  Text(time, style: TextStyle(fontSize: 12.5, color: edge, fontWeight: FontWeight.w600)),
                ]),
              ),
              const SizedBox(width: 10),
              del,
            ]),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../models/note_model.dart';
import '../services/notes_service.dart';
import '../fx_note_card.dart';
import 'note_editor_screen.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final NotesService _notesService = NotesService();
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openEditor([NoteModel? note, bool autoStartVoice = false]) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => NoteEditorScreen(
          note: note,
          autoStartVoice: autoStartVoice,
        ),
      ),
    );

    if (result == true && mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF030918) : const Color(0xFFF9FAFB);
    final textColor = isDark ? Colors.white : const Color(0xFF111827);
    final subtitleColor = isDark ? const Color(0xFF8FA3CC) : const Color(0xFF6B7280);

    final allNotes = _notesService.notes;
    final displayNotes = _searchQuery.isEmpty
        ? allNotes
        : allNotes.where((note) {
            final titleMatch = note.title.toLowerCase().contains(_searchQuery);
            final contentMatch = note.content.toLowerCase().contains(_searchQuery);
            return titleMatch || contentMatch;
          }).toList();

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: TextStyle(color: textColor, fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm ghi chú...',
                  hintStyle: TextStyle(
                    color: isDark ? const Color(0xFF8FA3CC) : Colors.grey[500],
                  ),
                  border: InputBorder.none,
                ),
              )
            : Text(
                'Ghi chú',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: isDark
                ? BoxDecoration(
                    color: const Color(0x330284C7),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF38BDF8).withValues(alpha: 0.5),
                    ),
                  )
                : null,
            child: IconButton(
              icon: Icon(
                _isSearching ? Icons.close : Icons.search,
                color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF1D61E7),
                size: 20,
              ),
              onPressed: () {
                setState(() {
                  if (_isSearching) {
                    _isSearching = false;
                    _searchController.clear();
                  } else {
                    _isSearching = true;
                  }
                });
              },
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Total Notes Count Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text(
                '${displayNotes.length} ghi chú',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isDark ? const Color(0xFF8FA3CC) : Colors.grey[600],
                ),
              ),
            ),
            Expanded(
              child: displayNotes.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.note_alt_outlined,
                            size: 64,
                            color: isDark ? const Color(0xFF38BDF8).withValues(alpha: 0.4) : Colors.grey[400],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _searchQuery.isNotEmpty
                                ? 'Không tìm thấy ghi chú phù hợp'
                                : 'Chưa có ghi chú nào',
                            style: TextStyle(
                              fontSize: 15,
                              color: subtitleColor,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      itemCount: displayNotes.length,
                      itemBuilder: (context, index) {
                        final note = displayNotes[index];
                        return FxNoteCard(
                          key: ValueKey(note.id),
                          title: note.title,
                          body: note.content,
                          time: note.formattedDate,
                          onTap: () => _openEditor(note),
                          onDeleted: () async {
                            await _notesService.deleteNote(note.id);
                            if (mounted) setState(() {});
                          },
                        );
                      },
                    ),
            ),
            // Bottom Guide Text
            if (displayNotes.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 84, top: 8),
                child: Center(
                  child: Text(
                    'Nhấn giữ nút thùng rác để xoá (búng tay Thanos)',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? const Color(0xFF8FA3CC) : Colors.grey[500],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Voice Mic Button
          Container(
            decoration: isDark
                ? BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0284C7).withValues(alpha: 0.4),
                        blurRadius: 10,
                      ),
                    ],
                  )
                : null,
            child: Material(
              elevation: 2,
              color: isDark ? const Color(0xFF031930) : const Color(0xFFF3F4F6),
              shape: const CircleBorder(),
              child: InkWell(
                onTap: () => _openEditor(null, true),
                customBorder: const CircleBorder(),
                child: Container(
                  width: 52,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: isDark
                      ? BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF38BDF8), width: 1.5),
                        )
                      : null,
                  child: Icon(
                    Icons.mic_none_outlined,
                    color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF1D61E7),
                    size: 26,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Add Plus Button
          Container(
            decoration: isDark
                ? BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0284C7).withValues(alpha: 0.5),
                        blurRadius: 12,
                      ),
                    ],
                  )
                : null,
            child: Material(
              elevation: 4,
              color: isDark ? const Color(0xFF0284C7) : const Color(0xFF2563EB),
              shape: const CircleBorder(),
              child: InkWell(
                onTap: () => _openEditor(),
                customBorder: const CircleBorder(),
                child: Container(
                  width: 56,
                  height: 56,
                  alignment: Alignment.center,
                  decoration: isDark
                      ? BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF38BDF8), width: 1.5),
                        )
                      : null,
                  child: const Icon(
                    Icons.add,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

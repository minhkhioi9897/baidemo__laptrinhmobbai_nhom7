import 'package:flutter/material.dart';
import '../models/journal_model.dart';
import '../services/journal_service.dart';
import '../fx_note_card.dart';
import 'journal_editor_screen.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  final JournalService _journalService = JournalService();

  void _openEditor({JournalModel? journal, bool autoStartVoice = false}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => JournalEditorScreen(
          journal: journal,
          autoStartVoice: autoStartVoice,
        ),
      ),
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final journals = _journalService.journals;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0xFF030918) : const Color(0xFFF9FAFB);
    final textColor = isDark ? Colors.white : const Color(0xFF111827);
    final subtitleColor = isDark ? const Color(0xFF8FA3CC) : const Color(0xFF4B5563);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Nhật ký',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF2563EB), size: 28),
            onPressed: () => _openEditor(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: journals.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.menu_book_outlined,
                      size: 64,
                      color: isDark ? const Color(0xFF38BDF8).withValues(alpha: 0.4) : Colors.grey[300],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Chưa có nhật ký nào',
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
                  vertical: 16,
                ),
                itemCount: journals.length,
                itemBuilder: (context, index) {
                  final journal = journals[index];
                  return FxNoteCard(
                    key: ValueKey(journal.id),
                    leading: Text(
                      journal.emoji,
                      style: const TextStyle(fontSize: 28),
                    ),
                    title: journal.formattedDate,
                    body: journal.content,
                    time: 'Lưu lúc ${journal.formattedTime}',
                    accent: const Color(0xFFA78BFA),
                    onTap: () => _openEditor(journal: journal),
                    onDeleted: () async {
                      await _journalService.deleteJournal(journal.id);
                      if (mounted) setState(() {});
                    },
                  );
                },
              ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openEditor(autoStartVoice: true),
        backgroundColor: isDark ? const Color(0xFF0284C7) : const Color(0xFF2563EB),
        elevation: 4,
        shape: isDark
            ? const CircleBorder(side: BorderSide(color: Color(0xFF38BDF8), width: 1.5))
            : const CircleBorder(),
        child: const Icon(
          Icons.mic_none_outlined,
          color: Colors.white,
          size: 30,
        ),
      ),
    );
  }
}

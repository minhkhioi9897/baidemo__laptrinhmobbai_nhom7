import 'package:flutter/material.dart';

class AnimatedDeleteCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onDelete;
  final String confirmTitle;
  final String confirmMessage;

  const AnimatedDeleteCard({
    super.key,
    required this.child,
    required this.onDelete,
    this.confirmTitle = 'Xác nhận xoá',
    this.confirmMessage = 'Bạn có chắc chắn muốn xoá mục này?',
  });

  @override
  State<AnimatedDeleteCard> createState() => AnimatedDeleteCardState();
}

class AnimatedDeleteCardState extends State<AnimatedDeleteCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnim;
  late Animation<double> _slideAnim;
  late Animation<double> _opacityAnim;
  late Animation<double> _trashLidAnim;

  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    // Optimized 350ms duration for ultra-smooth 60/120fps hardware acceleration
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _scaleAnim = Tween<double>(begin: 1.0, end: 0.2).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeInBack),
      ),
    );

    _slideAnim = Tween<double>(begin: 0.0, end: 90.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.8, curve: Curves.fastOutSlowIn),
      ),
    );

    _opacityAnim = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
      ),
    );

    _trashLidAnim = Tween<double>(begin: 0.0, end: -0.35).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutCubic),
      ),
    );
  }

  void _triggerDeleteAnimation() async {
    if (_isDeleting) return;

    setState(() {
      _isDeleting = true;
    });

    await _animController.forward();

    widget.onDelete();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Stack(
        alignment: Alignment.centerRight,
        children: [
          // Background Trash Bin Container
          Positioned.fill(
            child: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFEF4444), Color(0xFFB91C1C)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: AnimatedBuilder(
                animation: _animController,
                builder: (context, child) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Transform.rotate(
                        angle: _trashLidAnim.value,
                        child: const Icon(
                          Icons.delete_sweep_rounded,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Xoá',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),

          // Foreground Hardware-Accelerated Sliding & Shrinking Card
          AnimatedBuilder(
            animation: _animController,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(_slideAnim.value, 0),
                child: Transform.scale(
                  scale: _scaleAnim.value,
                  child: Opacity(
                    opacity: _opacityAnim.value,
                    child: widget.child,
                  ),
                ),
              );
            },
          ),

          // Action Trigger Lock during animation
          if (_isDeleting)
            Positioned.fill(
              child: Container(color: Colors.transparent),
            ),
        ],
      ),
    );
  }

  /// Triggers delete with confirmation dialog
  void triggerWithConfirm(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFFFEE2E2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.delete_forever_rounded, color: Color(0xFFDC2626), size: 24),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(widget.confirmTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
          ],
        ),
        content: Text(widget.confirmMessage, style: const TextStyle(fontSize: 14, height: 1.4)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _triggerDeleteAnimation();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Xoá ngay'),
          ),
        ],
      ),
    );
  }
}

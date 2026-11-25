import 'package:flutter/material.dart';

class CustomTextField extends StatefulWidget {
  final String label;
  final String hintText;
  final bool isPassword;
  final TextEditingController? controller;
  final TextInputType keyboardType;
  final ValueChanged<String>? onChanged;

  const CustomTextField({
    super.key,
    required this.label,
    required this.hintText,
    this.isPassword = false,
    this.controller,
    this.keyboardType = TextInputType.text,
    this.onChanged,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  late bool _obscureText;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.isPassword;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final textColor = isDark ? Colors.white : const Color(0xFF111827);
    final labelColor = isDark ? const Color(0xFFD1D5DB) : const Color(0xFF374151);
    final hintColor = isDark ? Colors.grey[500] : Colors.grey[400];
    final fillColor = isDark ? const Color(0x20000000) : Colors.white;
    final borderColor = isDark ? const Color(0xFF00E5FF).withValues(alpha: 0.6) : Colors.grey[300]!;
    final focusBorderColor = isDark ? const Color(0xFF00E5FF) : const Color(0xFF2563EB);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: labelColor,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: isDark
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
                      blurRadius: 10,
                      spreadRadius: -1,
                    ),
                  ],
                )
              : null,
          child: TextField(
            controller: widget.controller,
            obscureText: _obscureText,
            keyboardType: widget.keyboardType,
            onChanged: widget.onChanged,
            style: TextStyle(fontSize: 15, color: textColor),
            decoration: InputDecoration(
              hintText: widget.hintText,
              hintStyle: TextStyle(
                color: hintColor,
                fontSize: 15,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              filled: true,
              fillColor: fillColor,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: borderColor, width: isDark ? 1.5 : 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: focusBorderColor, width: 2),
              ),
              prefixIcon: isDark
                  ? Icon(
                      widget.label.contains('Email')
                          ? Icons.email_outlined
                          : (widget.isPassword
                              ? Icons.lock_outline
                              : Icons.person_outline),
                      color: const Color(0xFF00E5FF),
                      size: 20,
                    )
                  : null,
              suffixIcon: widget.isPassword
                  ? IconButton(
                      icon: Icon(
                        _obscureText
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: isDark ? const Color(0xFF00E5FF) : Colors.grey[500],
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureText = !_obscureText;
                        });
                      },
                    )
                  : null,
            ),
          ),
        ),
      ],
    );
  }
}

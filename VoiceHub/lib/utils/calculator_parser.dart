class CalculatorParser {
  /// Converts spoken Vietnamese text or formatted numbers with spaces into a mathematical expression string.
  /// Stops processing if '=' or 'bằng' is encountered (only taking text up to '=' or 'bằng').
  /// Example: "305 x 4 102 + 4" -> "305 * 4102 + 4"
  static String parseVietnameseSpeech(String input) {
    if (input.trim().isEmpty) return '';

    String text = input.toLowerCase().trim();

    // Remove quotes if present
    text = text.replaceAll('"', '').replaceAll('\'', '');

    // Cut off everything from '=' or 'bằng' onwards as requested by user
    if (text.contains('=')) {
      text = text.split('=').first.trim();
    }
    if (text.contains('bằng')) {
      text = text.split('bằng').first.trim();
    }

    // 1. Chuẩn hóa các phép toán
    text = text.replaceAll('cộng', ' + ');
    text = text.replaceAll(' cộng ', ' + ');
    text = text.replaceAll('trừ', ' - ');
    text = text.replaceAll(' trừ ', ' - ');
    text = text.replaceAll('nhân', ' * ');
    text = text.replaceAll(' nhân ', ' * ');
    text = text.replaceAll('chia cho', ' / ');
    text = text.replaceAll('chia', ' / ');
    text = text.replaceAll('mở ngoặc', ' ( ');
    text = text.replaceAll('đóng ngoặc', ' ) ');

    // 2. Chuyển đổi các từ số tiếng Việt đặc thù
    text = text.replaceAll('chín trăm', '900');
    text = text.replaceAll('tám trăm', '800');
    text = text.replaceAll('bảy trăm', '700');
    text = text.replaceAll('sáu trăm', '600');
    text = text.replaceAll('năm trăm', '500');
    text = text.replaceAll('bốn trăm', '400');
    text = text.replaceAll('ba trăm', '300');
    text = text.replaceAll('hai trăm', '200');
    text = text.replaceAll('một trăm', '100');

    text = text.replaceAll('hai mươi mốt', '21');
    text = text.replaceAll('hai mươi hai', '22');
    text = text.replaceAll('hai mươi ba', '23');
    text = text.replaceAll('hai mươi bốn', '24');
    text = text.replaceAll('hai mươi tư', '24');
    text = text.replaceAll('hai mươi lăm', '25');
    text = text.replaceAll('hai mươi năm', '25');
    text = text.replaceAll('hai mươi sáu', '26');
    text = text.replaceAll('hai mươi bảy', '27');
    text = text.replaceAll('hai mươi tám', '28');
    text = text.replaceAll('hai mươi chín', '29');
    text = text.replaceAll('hai mươi', '20');

    text = text.replaceAll('ba mươi mốt', '31');
    text = text.replaceAll('ba mươi hai', '32');
    text = text.replaceAll('ba mươi ba', '33');
    text = text.replaceAll('ba mươi bốn', '34');
    text = text.replaceAll('ba mươi tư', '34');
    text = text.replaceAll('ba mươi lăm', '35');
    text = text.replaceAll('ba mươi năm', '35');
    text = text.replaceAll('ba mươi sáu', '36');
    text = text.replaceAll('ba mươi bảy', '37');
    text = text.replaceAll('ba mươi tám', '38');
    text = text.replaceAll('ba mươi chín', '39');
    text = text.replaceAll('ba mươi', '30');

    text = text.replaceAll('bốn mươi mốt', '41');
    text = text.replaceAll('bốn mươi hai', '42');
    text = text.replaceAll('bốn mươi ba', '43');
    text = text.replaceAll('bốn mươi bốn', '44');
    text = text.replaceAll('bốn mươi tư', '44');
    text = text.replaceAll('bốn mươi lăm', '45');
    text = text.replaceAll('bốn mươi năm', '45');
    text = text.replaceAll('bốn mươi sáu', '46');
    text = text.replaceAll('bốn mươi bảy', '47');
    text = text.replaceAll('bốn mươi tám', '48');
    text = text.replaceAll('bốn mươi chín', '49');
    text = text.replaceAll('bốn mươi', '40');

    text = text.replaceAll('năm mươi mốt', '51');
    text = text.replaceAll('năm mươi hai', '52');
    text = text.replaceAll('năm mươi ba', '53');
    text = text.replaceAll('năm mươi bốn', '54');
    text = text.replaceAll('năm mươi tư', '54');
    text = text.replaceAll('năm mươi lăm', '55');
    text = text.replaceAll('năm mươi năm', '55');
    text = text.replaceAll('năm mươi sáu', '56');
    text = text.replaceAll('năm mươi bảy', '57');
    text = text.replaceAll('năm mươi tám', '58');
    text = text.replaceAll('năm mươi chín', '59');
    text = text.replaceAll('năm mươi', '50');

    text = text.replaceAll('mười chín', '19');
    text = text.replaceAll('mười tám', '18');
    text = text.replaceAll('mười bảy', '17');
    text = text.replaceAll('mười sáu', '16');
    text = text.replaceAll('mười lăm', '15');
    text = text.replaceAll('mười năm', '15');
    text = text.replaceAll('mười bốn', '14');
    text = text.replaceAll('mười tư', '14');
    text = text.replaceAll('mười ba', '13');
    text = text.replaceAll('mười hai', '12');
    text = text.replaceAll('mười một', '11');
    text = text.replaceAll('mười', '10');

    final mapDigits = {
      'không': '0',
      'một': '1',
      'hai': '2',
      'ba': '3',
      'bốn': '4',
      'tư': '4',
      'năm': '5',
      'lăm': '5',
      'sáu': '6',
      'bảy': '7',
      'tám': '8',
      'chín': '9',
    };

    final rawTokens = text.split(RegExp(r'\s+'));
    final List<String> processedTokens = [];

    for (var token in rawTokens) {
      token = token.trim();
      if (token.isEmpty) continue;

      if (mapDigits.containsKey(token)) {
        processedTokens.add(mapDigits[token]!);
      } else {
        processedTokens.add(token);
      }
    }

    // 3. Ghép nối các chuỗi chữ số đứng cạnh nhau bị Google STT chèn khoảng trắng phân cách hàng ngàn (Ví dụ: "4 102" -> "4102")
    final List<String> exprTokens = [];
    final StringBuffer digitsGroupBuffer = StringBuffer();

    for (final token in processedTokens) {
      // Nếu là chuỗi toàn chữ số (ví dụ "305", "4", "102")
      if (RegExp(r'^\d+$').hasMatch(token)) {
        digitsGroupBuffer.write(token);
      } else {
        if (digitsGroupBuffer.isNotEmpty) {
          exprTokens.add(digitsGroupBuffer.toString());
          digitsGroupBuffer.clear();
        }
        exprTokens.add(token);
      }
    }

    if (digitsGroupBuffer.isNotEmpty) {
      exprTokens.add(digitsGroupBuffer.toString());
    }

    // 4. Ghép lại chuỗi biểu thức hoàn chỉnh
    String result = exprTokens.join(' ');

    // Chuẩn hóa khoảng trắng xung quanh toán tử
    result = result
        .replaceAll(RegExp(r'\s*\+\s*'), ' + ')
        .replaceAll(RegExp(r'\s*-\s*'), ' - ')
        .replaceAll(RegExp(r'\s*\*\s*'), ' * ')
        .replaceAll(RegExp(r'\s*/\s*'), ' / ')
        .replaceAll(RegExp(r'\s*\(\s*'), ' ( ')
        .replaceAll(RegExp(r'\s*\)\s*'), ' ) ');

    return result.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  /// Converts spoken numeric/symbol string to pure Vietnamese words.
  static String convertToVietnameseWords(String input) {
    if (input.trim().isEmpty) return '';

    String text = input.toLowerCase().trim();

    // Cut off at '=' or 'bằng'
    if (text.contains('=')) {
      text = text.split('=').first.trim();
    }
    if (text.contains('bằng')) {
      text = text.split('bằng').first.trim();
    }

    // Replace operator symbols with Vietnamese word equivalents
    text = text.replaceAll('+', ' cộng ');
    text = text.replaceAll('-', ' trừ ');
    text = text.replaceAll('x', ' nhân ');
    text = text.replaceAll('×', ' nhân ');
    text = text.replaceAll('*', ' nhân ');
    text = text.replaceAll('/', ' chia ');
    text = text.replaceAll('÷', ' chia ');

    // Normalize multiple spaces
    text = text.replaceAll(RegExp(r'\s+'), ' ');

    final tokens = text.split(' ');
    final buffer = StringBuffer();

    for (var token in tokens) {
      token = token.trim();
      if (token.isEmpty) continue;

      final parsedInt = int.tryParse(token);
      if (parsedInt != null) {
        buffer.write('${_numberToVietnameseWords(parsedInt)} ');
      } else {
        buffer.write('$token ');
      }
    }

    return buffer.toString().trim();
  }

  static String _numberToVietnameseWords(int number) {
    if (number < 0) return 'âm ${_numberToVietnameseWords(number.abs())}';

    final singleDigits = [
      'không',
      'một',
      'hai',
      'ba',
      'bốn',
      'năm',
      'sáu',
      'bảy',
      'tám',
      'chín'
    ];

    if (number < 10) return singleDigits[number];

    if (number < 20) {
      if (number == 10) return 'mười';
      if (number == 15) return 'mười lăm';
      return 'mười ${singleDigits[number % 10]}';
    }

    if (number < 100) {
      final tens = number ~/ 10;
      final remainder = number % 10;
      String tensStr = '${singleDigits[tens]} mươi';

      if (remainder == 0) return tensStr;
      if (remainder == 1) return '${singleDigits[tens]} mươi mốt';
      if (remainder == 5) return '${singleDigits[tens]} mươi lăm';
      return '$tensStr ${singleDigits[remainder]}';
    }

    if (number < 1000) {
      final hundreds = number ~/ 100;
      final remainder = number % 100;
      String hundredStr = '${singleDigits[hundreds]} trăm';

      if (remainder == 0) return hundredStr;
      if (remainder < 10) return '$hundredStr lẻ ${singleDigits[remainder]}';
      return '$hundredStr ${_numberToVietnameseWords(remainder)}';
    }

    return number.toString();
  }

  /// Evaluates mathematical expression string safely respecting operator precedence.
  /// Example: "305 * 4102 + 4" -> 1251114.0
  static double? evaluateExpression(String expression) {
    if (expression.trim().isEmpty) return null;

    try {
      // Clean up string
      String expr = expression
          .replaceAll('×', '*')
          .replaceAll('x', '*')
          .replaceAll('÷', '/')
          .replaceAll('=', '')
          .trim();

      // Simple Shunting-yard algorithm
      final tokens = _tokenize(expr);
      if (tokens.isEmpty) return null;

      final rpn = _toRPN(tokens);
      if (rpn == null) return null;

      return _evalRPN(rpn);
    } catch (_) {
      return null;
    }
  }

  static List<String> _tokenize(String expr) {
    final List<String> tokens = [];
    final StringBuffer numberBuffer = StringBuffer();

    for (int i = 0; i < expr.length; i++) {
      final char = expr[i];

      if (RegExp(r'[0-9.]').hasMatch(char)) {
        numberBuffer.write(char);
      } else {
        if (numberBuffer.isNotEmpty) {
          tokens.add(numberBuffer.toString());
          numberBuffer.clear();
        }
        if (char != ' ') {
          tokens.add(char);
        }
      }
    }
    if (numberBuffer.isNotEmpty) {
      tokens.add(numberBuffer.toString());
    }

    return tokens;
  }

  static List<String>? _toRPN(List<String> tokens) {
    final List<String> output = [];
    final List<String> stack = [];

    final precedence = {'+': 1, '-': 1, '*': 2, '/': 2};

    for (final token in tokens) {
      if (double.tryParse(token) != null) {
        output.add(token);
      } else if (precedence.containsKey(token)) {
        while (stack.isNotEmpty &&
            precedence.containsKey(stack.last) &&
            precedence[stack.last]! >= precedence[token]!) {
          output.add(stack.removeLast());
        }
        stack.add(token);
      } else if (token == '(') {
        stack.add(token);
      } else if (token == ')') {
        while (stack.isNotEmpty && stack.last != '(') {
          output.add(stack.removeLast());
        }
        if (stack.isEmpty) return null; // Unbalanced
        stack.removeLast(); // Remove '('
      }
    }

    while (stack.isNotEmpty) {
      if (stack.last == '(' || stack.last == ')') return null;
      output.add(stack.removeLast());
    }

    return output;
  }

  static double? _evalRPN(List<String> rpn) {
    final List<double> stack = [];

    for (final token in rpn) {
      final num = double.tryParse(token);
      if (num != null) {
        stack.add(num);
      } else {
        if (stack.length < 2) return null;
        final b = stack.removeLast();
        final a = stack.removeLast();

        switch (token) {
          case '+':
            stack.add(a + b);
            break;
          case '-':
            stack.add(a - b);
            break;
          case '*':
            stack.add(a * b);
            break;
          case '/':
            if (b == 0) return null;
            stack.add(a / b);
            break;
          default:
            return null;
        }
      }
    }

    return stack.length == 1 ? stack.single : null;
  }

  /// Formats result number cleanly (e.g. 1251114.0 -> "1251114", 3.14159 -> "3.14")
  static String formatResult(double result) {
    if (result == result.truncateToDouble()) {
      return result.toInt().toString();
    }
    return result.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '');
  }
}

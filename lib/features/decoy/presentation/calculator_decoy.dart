import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// Fully functional calculator — operates normally to deceive inspectors.
/// Includes history, real arithmetic, and no hint of vault functionality.
class CalculatorDecoy extends StatefulWidget {
  const CalculatorDecoy({super.key});

  @override
  State<CalculatorDecoy> createState() => _CalculatorDecoyState();
}

class _CalculatorDecoyState extends State<CalculatorDecoy> {
  String _display = '0';
  String _history = '';
  double? _firstOperand;
  String? _operator;
  bool _awaitingSecond = false;
  final List<String> _calcHistory = [];

  void _onDigit(String d) {
    setState(() {
      if (_display == '0' || _awaitingSecond) {
        _display = d;
        _awaitingSecond = false;
      } else {
        if (_display.length < 12) _display += d;
      }
    });
  }

  void _onDot() {
    if (_awaitingSecond) {
      setState(() { _display = '0.'; _awaitingSecond = false; });
      return;
    }
    if (!_display.contains('.')) setState(() => _display += '.');
  }

  void _onOperator(String op) {
    setState(() {
      _firstOperand = double.tryParse(_display);
      _operator = op;
      _history = '$_display $op';
      _awaitingSecond = true;
    });
  }

  void _onEquals() {
    if (_firstOperand == null || _operator == null) return;
    final second = double.tryParse(_display);
    if (second == null) return;
    double result = 0;
    switch (_operator) {
      case '+': result = _firstOperand! + second; break;
      case '−': result = _firstOperand! - second; break;
      case '×': result = _firstOperand! * second; break;
      case '÷': result = second != 0 ? _firstOperand! / second : 0; break;
    }
    final resultStr = result % 1 == 0 ? result.toInt().toString() : result.toStringAsFixed(6).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
    setState(() {
      _calcHistory.insert(0, '$_history $_display = $resultStr');
      if (_calcHistory.length > 10) _calcHistory.removeLast();
      _history = '';
      _display = resultStr;
      _firstOperand = null;
      _operator = null;
      _awaitingSecond = false;
    });
  }

  void _onClear() => setState(() { _display = '0'; _history = ''; _firstOperand = null; _operator = null; _awaitingSecond = false; });
  void _onBackspace() => setState(() { if (_display.length > 1) { _display = _display.substring(0, _display.length - 1); } else { _display = '0'; } });
  void _onPercent() { final v = double.tryParse(_display); if (v != null) setState(() => _display = (v / 100).toString()); }
  void _onToggleSign() { if (_display != '0') setState(() => _display = _display.startsWith('-') ? _display.substring(1) : '-$_display'); }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Display
        Container(
          width: double.infinity,
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (_history.isNotEmpty)
                Text(_history, style: const TextStyle(color: AppTheme.decoyMuted, fontSize: 14)),
              const SizedBox(height: 4),
              Text(_display, style: const TextStyle(color: AppTheme.decoyText, fontSize: 42, fontWeight: FontWeight.w300)),
              if (_calcHistory.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Divider(color: Color(0xFFE2E8F0)),
                const SizedBox(height: 8),
                ..._calcHistory.take(3).map((h) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(h, style: const TextStyle(color: AppTheme.decoyMuted, fontSize: 11)),
                )),
              ],
            ],
          ),
        ),
        // Keypad
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
            child: Column(
              children: [
                _buildRow(['AC', '±', '%', '÷'], isTopRow: true),
                _buildRow(['7', '8', '9', '×']),
                _buildRow(['4', '5', '6', '−']),
                _buildRow(['1', '2', '3', '+']),
                _buildRow(['0', '.', '⌫', '='], isBottomRow: true),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRow(List<String> keys, {bool isTopRow = false, bool isBottomRow = false}) {
    return Expanded(
      child: Row(
        children: keys.map((k) {
          final isOperator = ['÷', '×', '−', '+', '='].contains(k);
          final isEquals = k == '=';
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Material(
                color: isEquals
                    ? const Color(0xFF6366F1)
                    : isOperator
                        ? const Color(0xFFEEF2FF)
                        : isTopRow
                            ? const Color(0xFFF1F5F9)
                            : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () {
                    if (k == 'AC') { _onClear(); }
                    else if (k == '⌫') { _onBackspace(); }
                    else if (k == '%') { _onPercent(); }
                    else if (k == '±') { _onToggleSign(); }
                    else if (k == '.') { _onDot(); }
                    else if (k == '=') { _onEquals(); }
                    else if (['÷', '×', '−', '+'].contains(k)) { _onOperator(k); }
                    else { _onDigit(k); }
                  },
                  child: Center(
                    child: Text(k,
                        style: TextStyle(
                          color: isEquals ? Colors.white : isOperator ? const Color(0xFF6366F1) : AppTheme.decoyText,
                          fontSize: isEquals ? 28 : 22,
                          fontWeight: isOperator || isEquals ? FontWeight.w600 : FontWeight.w400,
                        )),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

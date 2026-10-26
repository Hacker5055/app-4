import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';

/// Stealth PIN input — dots with haptic feedback, no visible digits.
/// Supports both normal (green accent) and decoy-aware styling.
class PinInputWidget extends StatefulWidget {
  final int pinLength;
  final ValueChanged<String> onCompleted;
  final VoidCallback? onChanged;
  final bool enabled;
  final bool isError;
  final bool showBiometric;

  const PinInputWidget({
    super.key,
    this.pinLength = 6,
    required this.onCompleted,
    this.onChanged,
    this.enabled = true,
    this.isError = false,
    this.showBiometric = false,
  });

  @override
  State<PinInputWidget> createState() => PinInputWidgetState();
}

class PinInputWidgetState extends State<PinInputWidget> with SingleTickerProviderStateMixin {
  String _pin = '';
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _shakeAnimation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
  }

  @override
  void didUpdateWidget(PinInputWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isError && !oldWidget.isError) {
      _shakeController.forward(from: 0);
      HapticFeedback.heavyImpact();
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _onDigit(String digit) {
    if (!widget.enabled) return;
    if (_pin.length >= widget.pinLength) return;
    setState(() => _pin += digit);
    HapticFeedback.lightImpact();
    widget.onChanged?.call();
    if (_pin.length == widget.pinLength) {
      Future.delayed(const Duration(milliseconds: 150), () {
        widget.onCompleted(_pin);
      });
    }
  }

  void _onBackspace() {
    if (!widget.enabled) return;
    if (_pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
    HapticFeedback.selectionClick();
  }

  void _onClear() {
    if (!widget.enabled) return;
    setState(() => _pin = '');
    HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── PIN Dots ──
        AnimatedBuilder(
          animation: _shakeAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(_shakeAnimation.value * (widget.isError ? 1 : 0), 0),
              child: child,
            );
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.pinLength, (index) {
              final filled = index < _pin.length;
              final isActive = index == _pin.length;
              return Container(
                width: 18,
                height: 18,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: filled
                      ? (widget.isError ? AppTheme.dangerRed : AppTheme.neonGreen)
                      : Colors.transparent,
                  border: Border.all(
                    color: filled
                        ? (widget.isError ? AppTheme.dangerRed : AppTheme.neonGreen)
                        : isActive
                            ? AppTheme.neonGreen.withOpacity(0.5)
                            : AppTheme.obsidianBorder,
                    width: filled ? 0 : 1.5,
                  ),
                  boxShadow: filled
                      ? [
                          BoxShadow(
                            color: (widget.isError ? AppTheme.dangerRed : AppTheme.neonGreen).withOpacity(0.4),
                            blurRadius: 12,
                          ),
                        ]
                      : null,
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 36),

        // ── Numeric Keypad ──
        _buildKeypad(),
      ],
    );
  }

  Widget _buildKeypad() {
    return Column(
      children: [
        for (var row in [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
          ['clear', '0', 'backspace'],
        ])
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: row.map((key) {
                if (key == 'clear') {
                  return _KeypadButton(
                    label: 'C',
                    subLabel: 'CLEAR',
                    onTap: _onClear,
                    isAction: true,
                  );
                } else if (key == 'backspace') {
                  return _KeypadButton(
                    icon: Icons.backspace_outlined,
                    onTap: _onBackspace,
                    isAction: true,
                  );
                } else {
                  return _KeypadButton(
                    label: key,
                    subLabel: _getSubLabel(key),
                    onTap: () => _onDigit(key),
                  );
                }
              }).toList(),
            ),
          ),
      ],
    );
  }

  String _getSubLabel(String digit) {
    const map = {
      '1': '',
      '2': 'ABC',
      '3': 'DEF',
      '4': 'GHI',
      '5': 'JKL',
      '6': 'MNO',
      '7': 'PQRS',
      '8': 'TUV',
      '9': 'WXYZ',
      '0': '+',
    };
    return map[digit] ?? '';
  }

  /// Clears the entered digits so the gate can accept the next attempt.
  void clearPin() {
    if (!mounted) return;
    setState(() => _pin = '');
  }
}

class _KeypadButton extends StatefulWidget {
  final String? label;
  final String? subLabel;
  final IconData? icon;
  final VoidCallback onTap;
  final bool isAction;

  const _KeypadButton({
    this.label,
    this.subLabel,
    this.icon,
    required this.onTap,
    this.isAction = false,
  });

  @override
  State<_KeypadButton> createState() => _KeypadButtonState();
}

class _KeypadButtonState extends State<_KeypadButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: 78,
        height: 78,
        margin: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: _pressed
              ? AppTheme.neonGreen.withOpacity(0.15)
              : widget.isAction
                  ? AppTheme.obsidianLight
                  : AppTheme.obsidianPanel,
          shape: BoxShape.circle,
          border: Border.all(
            color: _pressed
                ? AppTheme.neonGreen.withOpacity(0.6)
                : AppTheme.obsidianBorder.withOpacity(0.6),
            width: 1,
          ),
          boxShadow: _pressed
              ? [BoxShadow(color: AppTheme.neonGreen.withOpacity(0.2), blurRadius: 16)]
              : null,
        ),
        child: widget.icon != null
            ? Icon(widget.icon, color: AppTheme.textSecondary, size: 22)
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.label ?? '',
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 26,
                      fontWeight: FontWeight.w300,
                      letterSpacing: 1,
                    ),
                  ),
                  if (widget.subLabel != null && widget.subLabel!.isNotEmpty)
                    Text(
                      widget.subLabel!,
                      style: const TextStyle(
                        color: AppTheme.textGhost,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

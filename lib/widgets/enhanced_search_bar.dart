import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/family_connect_theme.dart';

class EnhancedSearchBar extends StatefulWidget {
  final String hintText;
  final ValueChanged<String> onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final bool autofocus;
  final List<Widget>? actions;
  final bool showSuggestions;
  final List<String>? suggestions;

  const EnhancedSearchBar({
    super.key,
    required this.hintText,
    required this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.controller,
    this.focusNode,
    this.autofocus = false,
    this.actions,
    this.showSuggestions = false,
    this.suggestions,
  });

  @override
  State<EnhancedSearchBar> createState() => _EnhancedSearchBarState();
}

class _EnhancedSearchBarState extends State<EnhancedSearchBar> with TickerProviderStateMixin {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  bool _isFocused = false;
  bool _showSuggestions = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _focusNode = widget.focusNode ?? FocusNode();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _focusNode.addListener(_onFocusChange);
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    _pulseController.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
      if (_isFocused && widget.showSuggestions) {
        _showSuggestions = true;
        _pulseController.repeat(reverse: true);
      } else {
        _showSuggestions = false;
        _pulseController.stop();
      }
    });
  }

  void _onTextChanged() {
    final text = _controller.text;
    widget.onChanged(text);

    if (widget.showSuggestions) {
      setState(() {
        _showSuggestions = _isFocused && text.isNotEmpty;
      });
    }
  }

  void _onSubmitted(String value) {
    HapticFeedback.lightImpact();
    widget.onSubmitted?.call(value);
    setState(() {
      _showSuggestions = false;
    });
  }

  void _onClear() {
    HapticFeedback.lightImpact();
    _controller.clear();
    widget.onClear?.call();
    setState(() {
      _showSuggestions = false;
    });
  }

  void _onSuggestionTap(String suggestion) {
    HapticFeedback.lightImpact();
    _controller.text = suggestion;
    _onSubmitted(suggestion);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: Listenable.merge([_pulseAnimation, _pulseController]),
          builder: (context, child) {
            return Transform.scale(
              scale: _isFocused ? _pulseAnimation.value : 1.0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: _isFocused
                        ? [
                            Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                            Theme.of(context).colorScheme.secondary.withValues(alpha: 0.05),
                          ]
                        : [
                            Theme.of(context).colorScheme.surface,
                            Theme.of(context).colorScheme.surface,
                          ],
                  ),
                  borderRadius: FamilyConnectTheme.radiusLg,
                  boxShadow: _isFocused
                      ? FamilyConnectTheme.shadowLg
                      : FamilyConnectTheme.shadowSm,
                  border: Border.all(
                    color: _isFocused
                        ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)
                        : Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                    width: _isFocused ? 2 : 1,
                  ),
                ),
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  autofocus: widget.autofocus,
                  onChanged: widget.onChanged,
                  onSubmitted: _onSubmitted,
                  decoration: InputDecoration(
                    hintText: widget.hintText,
                    hintStyle: FamilyConnectTheme.bodyMedium.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                    prefixIcon: Container(
                      padding: const EdgeInsets.all(12),
                      child: Icon(
                        Icons.search,
                        color: _isFocused
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        size: 24,
                      ),
                    ),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.onClear != null && _controller.text.isNotEmpty)
                          IconButton(
                            onPressed: _onClear,
                            icon: Icon(
                              Icons.clear,
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                              size: 20,
                            ),
                          ),
                        if (widget.actions != null) ...widget.actions!,
                      ],
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  style: FamilyConnectTheme.bodyMedium.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            );
          },
        ),

        // Suggestions dropdown
        if (_showSuggestions && widget.suggestions != null && widget.suggestions!.isNotEmpty)
          AnimatedContainer(
            duration: FamilyConnectTheme.normalDuration,
            curve: FamilyConnectTheme.defaultCurve,
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: FamilyConnectTheme.radiusLg,
              boxShadow: FamilyConnectTheme.shadowLg,
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.suggestions!.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
              ),
              itemBuilder: (context, index) {
                final suggestion = widget.suggestions![index];
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _onSuggestionTap(suggestion),
                    borderRadius: FamilyConnectTheme.radiusSm,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.history,
                            size: 20,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              suggestion,
                              style: FamilyConnectTheme.bodyMedium.copyWith(
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/family_connect_theme.dart';

/// Loading animations modernes : Skeleton screens, shimmer effect, Lottie-style animations
/// Pull-to-refresh personnalisé, progress indicators animés
class LoadingAnimations {
  
  // ============================================
  // SKELETON SCREENS
  // ============================================
  
  /// Skeleton card pour les personnes
  static Widget personCardSkeleton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ShimmerEffect(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: FamilyConnectTheme.radiusLg,
            boxShadow: FamilyConnectTheme.shadowSm,
          ),
          child: Row(
            children: [
              // Avatar skeleton
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: FamilyConnectTheme.radiusFull,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nom skeleton
                    Container(
                      width: double.infinity,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: FamilyConnectTheme.radiusSm,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Détails skeleton
                    Container(
                      width: 150,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: FamilyConnectTheme.radiusSm,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 100,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: FamilyConnectTheme.radiusSm,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  /// Skeleton list pour plusieurs éléments
  static Widget listSkeleton({int itemCount = 3}) {
    return Column(
      children: List.generate(
        itemCount,
        (index) => personCardSkeleton(),
      ),
    );
  }
  
  // ============================================
  // PROGRESS INDICATORS
  // ============================================
  
  /// Progress indicator circulaire personnalisé
  static Widget circularProgress({
    double size = 48,
    Color? color,
    double strokeWidth = 4,
  }) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        valueColor: AlwaysStoppedAnimation<Color>(
          color ?? FamilyConnectTheme.primaryColor,
        ),
        backgroundColor: FamilyConnectTheme.primaryColor.withValues(alpha: 0.1),
      ),
    );
  }
  
  /// Progress indicator linéaire avec gradient
  static Widget linearProgress({
    double height = 4,
    double progress = 0.5,
    Color? backgroundColor,
    LinearGradient? gradient,
  }) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.grey[300],
        borderRadius: FamilyConnectTheme.radiusFull,
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress.clamp(0.0, 1.0),
        child: Container(
          decoration: BoxDecoration(
            gradient: gradient ?? FamilyConnectTheme.primaryGradient,
            borderRadius: FamilyConnectTheme.radiusFull,
          ),
        ),
      ),
    );
  }
  
  /// Progress dots animés
  static Widget dotsProgress({
    int dotCount = 3,
    Color? color,
    double dotSize = 8,
    double spacing = 4,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        dotCount,
        (index) => AnimatedDot(
          index: index,
          dotCount: dotCount,
          color: color ?? FamilyConnectTheme.primaryColor,
          size: dotSize,
          spacing: spacing,
        ),
      ),
    );
  }
  
  // ============================================
  // PULL-TO-REFRESH PERSONNALISÉ
  // ============================================
  
  static Widget customRefreshIndicator({
    required Widget child,
    required RefreshCallback onRefresh,
    String? message,
  }) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: FamilyConnectTheme.primaryColor,
      backgroundColor: Theme.of(Get.context!).colorScheme.surface,
      displacement: 60,
      child: child,
    );
  }
  
  // ============================================
  // LOADING STATES COMPLETS
  // ============================================
  
  /// Page loading complet avec animation
  static Widget fullPageLoading({
    String? message,
    Widget? customWidget,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (customWidget != null)
            customWidget
          else
            _buildAnimatedLogo(),
          const SizedBox(height: 24),
          if (message != null)
            Text(
              message,
              style: FamilyConnectTheme.bodyMedium.copyWith(
                color: Theme.of(Get.context!).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          const SizedBox(height: 16),
          dotsProgress(),
        ],
      ),
    );
  }
  
  /// Empty state moderne
  static Widget emptyState({
    required IconData icon,
    required String title,
    String? subtitle,
    List<Widget>? actions,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    FamilyConnectTheme.primaryColor.withValues(alpha: 0.1),
                    FamilyConnectTheme.secondaryColor.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: FamilyConnectTheme.radiusFull,
              ),
              child: Icon(
                icon,
                size: 48,
                color: FamilyConnectTheme.primaryColor.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: FamilyConnectTheme.h4.copyWith(
                color: Theme.of(Get.context!).colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: FamilyConnectTheme.bodyMedium.copyWith(
                  color: Theme.of(Get.context!).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (actions != null) ...[
              const SizedBox(height: 24),
              ...actions,
            ],
          ],
        ),
      ),
    );
  }
  
  // ============================================
  // WIDGETS INTERNES
  // ============================================
  
  static Widget _buildAnimatedLogo() {
    return TweenAnimationBuilder<double>(
      duration: const Duration(seconds: 2),
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, value, child) {
        return Transform.rotate(
          angle: value * 2 * 3.14159,
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: FamilyConnectTheme.primaryGradient,
              borderRadius: FamilyConnectTheme.radiusLg,
              boxShadow: FamilyConnectTheme.shadowMd,
            ),
            child: const Icon(
              Icons.family_restroom,
              color: Colors.white,
              size: 32,
            ),
          ),
        );
      },
    );
  }
}

/// Shimmer effect pour skeleton screens
class ShimmerEffect extends StatefulWidget {
  final Widget child;
  final Color? baseColor;
  final Color? highlightColor;
  final Duration duration;

  const ShimmerEffect({
    super.key,
    required this.child,
    this.baseColor,
    this.highlightColor,
    this.duration = const Duration(milliseconds: 1500),
  });

  @override
  State<ShimmerEffect> createState() => _ShimmerEffectState();
}

class _ShimmerEffectState extends State<ShimmerEffect>
    with SingleTickerProviderStateMixin {
  
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    
    _animation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment(-1.0 + _animation.value, 0),
              end: Alignment(1.0 + _animation.value, 0),
              colors: [
                widget.baseColor ?? Colors.grey[300]!,
                widget.highlightColor ?? Colors.grey[100]!,
                widget.baseColor ?? Colors.grey[300]!,
              ],
              stops: const [0.0, 0.5, 1.0],
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

/// Dot animé pour progress dots
class AnimatedDot extends StatefulWidget {
  final int index;
  final int dotCount;
  final Color color;
  final double size;
  final double spacing;

  const AnimatedDot({
    super.key,
    required this.index,
    required this.dotCount,
    required this.color,
    required this.size,
    required this.spacing,
  });

  @override
  State<AnimatedDot> createState() => _AnimatedDotState();
}

class _AnimatedDotState extends State<AnimatedDot>
    with SingleTickerProviderStateMixin {
  
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    final delay = widget.index * (1200 / widget.dotCount);
    
    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Interval(
        delay / 1200,
        (delay + 600) / 1200,
        curve: Curves.easeInOut,
      ),
    ));
    
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.size,
          height: widget.size,
          margin: EdgeInsets.symmetric(horizontal: widget.spacing / 2),
          decoration: BoxDecoration(
            color: widget.color.withValues(alpha: _animation.value),
            borderRadius: FamilyConnectTheme.radiusFull,
          ),
        );
      },
    );
  }
}

/// Bouton avec état de chargement
class LoadingButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color? color;
  final Color? textColor;
  final BorderRadius? borderRadius;
  final double? height;
  final double? width;

  const LoadingButton({
    super.key,
    required this.child,
    this.onPressed,
    this.isLoading = false,
    this.color,
    this.textColor,
    this.borderRadius,
    this.height,
    this.width,
  });

  @override
  State<LoadingButton> createState() => _LoadingButtonState();
}

class _LoadingButtonState extends State<LoadingButton>
    with SingleTickerProviderStateMixin {
  
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(LoadingButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoading != oldWidget.isLoading) {
      if (widget.isLoading) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return SizedBox(
          width: widget.width,
          height: widget.height ?? 48,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.isLoading ? null : widget.onPressed,
              borderRadius: widget.borderRadius ?? FamilyConnectTheme.radiusMd,
              child: Container(
                decoration: BoxDecoration(
                  gradient: widget.color != null
                      ? LinearGradient(colors: [widget.color!, widget.color!])
                      : FamilyConnectTheme.primaryGradient,
                  borderRadius: widget.borderRadius ?? FamilyConnectTheme.radiusMd,
                  boxShadow: FamilyConnectTheme.shadowSm,
                ),
                child: Center(
                  child: widget.isLoading
                      ? Transform.scale(
                          scale: _animation.value,
                          child: LoadingAnimations.circularProgress(
                            size: 20,
                            color: widget.textColor ?? Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : widget.child,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Extension pour obtenir le contexte facilement
extension Get on Widget {
  static BuildContext? _context;
  
  static BuildContext get context {
    assert(_context != null, 'Get.context n\'est pas initialisé');
    return _context!;
  }
  
  static void setContext(BuildContext context) {
    _context = context;
  }
}

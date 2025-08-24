import 'package:flutter/material.dart';

class ShimmerWidget extends StatefulWidget {
  final Widget child;
  final Color? baseColor;
  final Color? highlightColor;

  const ShimmerWidget({
    super.key,
    required this.child,
    this.baseColor,
    this.highlightColor,
  });

  @override
  State<ShimmerWidget> createState() => _ShimmerWidgetState();
}

class _ShimmerWidgetState extends State<ShimmerWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.baseColor ?? Colors.grey[300]!;
    final highlightColor = widget.highlightColor ?? Colors.grey[100]!;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: const Alignment(-1.0, 0.0),
              end: const Alignment(1.0, 0.0),
              colors: [
                baseColor,
                highlightColor,
                baseColor,
              ],
              stops: [
                (_animation.value - 1.0).clamp(0.0, 1.0),
                _animation.value.clamp(0.0, 1.0),
                (_animation.value + 1.0).clamp(0.0, 1.0),
              ],
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

class ImageShimmer extends StatelessWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const ImageShimmer({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
      ),
      child: ShimmerWidget(
        baseColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[700]! : Colors.grey[300]!,
        highlightColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[600]! : Colors.grey[100]!,
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[700]! : Colors.grey[300]!,
            borderRadius: borderRadius,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.image_outlined,
                color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[500] : Colors.grey[400],
                size: 40,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[600]!.withOpacity(0.8)
                      : Colors.white.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Loading...',
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[300] : Colors.grey[600],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PropertyCardShimmer extends StatelessWidget {
  const PropertyCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withOpacity(0.2)
                : Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image shimmer
          ImageShimmer(
            height: 200,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title shimmer
                ShimmerWidget(
                  child: Container(
                    height: 20,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Location shimmer
                ShimmerWidget(
                  child: Container(
                    height: 14,
                    width: 100,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Stats shimmer
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    for (int i = 0; i < 3; i++)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ShimmerWidget(
                            child: Container(
                              height: 12,
                              width: 60,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          ShimmerWidget(
                            child: Container(
                              height: 16,
                              width: 80,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

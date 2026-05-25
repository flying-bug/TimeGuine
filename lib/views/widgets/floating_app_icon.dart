import 'package:flutter/material.dart';

class FloatingAppIcon {
  static OverlayEntry? _overlayEntry;
  static final GlobalKey<_FloatingWidgetState> _key = GlobalKey<_FloatingWidgetState>();
  static double _lastX = 20.0;
  static double _lastY = 100.0;

  /// Gọi hàm này để hiển thị icon trôi nổi trên toàn bộ ứng dụng
  static void show(BuildContext context, {required String imageAssetPath, String message = '', VoidCallback? onTap}) {
    if (_overlayEntry != null) {
      _key.currentState?.updateMessage(message, onTap: onTap);
      return; 
    }

    _overlayEntry = OverlayEntry(
      builder: (context) => _FloatingWidget(
        key: _key,
        imageAssetPath: imageAssetPath,
        message: message,
        onTap: onTap,
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  /// Gọi hàm này để ẩn icon
  static void hide() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }
}

class _FloatingWidget extends StatefulWidget {
  final String imageAssetPath;
  final String message;
  final VoidCallback? onTap;

  const _FloatingWidget({
    Key? key,
    required this.imageAssetPath,
    required this.message,
    this.onTap,
  }) : super(key: key);

  @override
  State<_FloatingWidget> createState() => _FloatingWidgetState();
}

class _FloatingWidgetState extends State<_FloatingWidget> {
  // Vị trí mặc định ban đầu
  late double x;
  late double y;
  bool _showMessage = true;
  late String _currentMessage;
  VoidCallback? _currentOnTap;

  @override
  void initState() {
    super.initState();
    x = FloatingAppIcon._lastX;
    y = FloatingAppIcon._lastY;
    _currentMessage = widget.message;
    _currentOnTap = widget.onTap;
    _startTimer();
  }

  void updateMessage(String newMessage, {VoidCallback? onTap}) {
    setState(() {
      _currentMessage = newMessage;
      _currentOnTap = onTap;
      _showMessage = true;
    });
    _startTimer();
  }

  void _startTimer() {
    // Tự động ẩn tin nhắn sau 5 giây để gọn màn hình
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _showMessage = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final bool isLeftHalf = x < screenSize.width / 2;

    // Bong bóng thông báo (giống MBBank)
    final textBubbleWidget = AnimatedSize(
      duration: const Duration(milliseconds: 300),
      alignment: isLeftHalf ? Alignment.bottomLeft : Alignment.bottomRight,
      curve: Curves.easeInOut,
      child: (_showMessage && _currentMessage.isNotEmpty)
          ? Container(
              margin: EdgeInsets.only(
                bottom: 15,
                left: isLeftHalf ? 8 : 0,
                right: isLeftHalf ? 0 : 8,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              constraints: const BoxConstraints(maxWidth: 160),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isLeftHalf ? 0 : 16),
                  bottomRight: Radius.circular(isLeftHalf ? 16 : 0),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                _currentMessage,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),
            )
          : const SizedBox.shrink(),
    );

    // App Icon trôi nổi kèm nút đóng (dấu tick)
    final iconWidget = Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 55,
          height: 55,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
            // Nền trắng phòng trường hợp ảnh trong suốt
            color: Colors.white, 
            image: DecorationImage(
              image: AssetImage(widget.imageAssetPath),
              fit: BoxFit.cover,
            ),
          ),
        ),
        // Nút tắt hình dấu X đỏ
        Positioned(
          top: -4,
          right: -4,
          child: GestureDetector(
            onTap: () {
              FloatingAppIcon.hide();
            },
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.redAccent,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.close_rounded,
                color: Colors.white,
                size: 14,
              ),
            ),
          ),
        ),
      ],
    );

    return Positioned(
      left: x,
      top: y,
      child: Material(
        color: Colors.transparent,
        child: GestureDetector(
          onPanUpdate: (details) {
            setState(() {
              // Cập nhật vị trí khi người dùng kéo (drag)
              x = (x + details.delta.dx).clamp(0.0, screenSize.width - 60.0);
              y = (y + details.delta.dy).clamp(0.0, screenSize.height - 100.0);
              FloatingAppIcon._lastX = x;
              FloatingAppIcon._lastY = y;
            });
          },
          onTap: () {
            if (_currentOnTap != null) {
              _currentOnTap!();
            } else {
              // Bấm vào icon để bật/tắt hiển thị bong bóng chat
              setState(() {
                _showMessage = !_showMessage;
              });
            }
          },
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: isLeftHalf 
                ? [iconWidget, textBubbleWidget]
                : [textBubbleWidget, iconWidget],
          ),
        ),
      ),
    );
  }
}

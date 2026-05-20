import 'package:flutter/material.dart';

class FloatingGenie extends StatefulWidget {
  final String message;
  final String imageAssetPath; // Đường dẫn tới icon app của bạn (VD: 'assets/images/app_icon.png')
  final double initialX;
  final double initialY;

  const FloatingGenie({
    Key? key,
    required this.message,
    this.imageAssetPath = '', // Nếu không có ảnh, tạm dùng Icon mặc định
    this.initialX = 20.0,
    this.initialY = 100.0,
  }) : super(key: key);

  @override
  State<FloatingGenie> createState() => _FloatingGenieState();
}

class _FloatingGenieState extends State<FloatingGenie> {
  late double x;
  late double y;

  @override
  void initState() {
    super.initState();
    x = widget.initialX;
    y = widget.initialY;
  }

  @override
  Widget build(BuildContext context) {
    // Lấy kích thước màn hình để không kéo Thần đèn ra ngoài
    final screenSize = MediaQuery.of(context).size;

    return Positioned(
      left: x,
      top: y,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            // Cập nhật vị trí khi kéo (drag), giới hạn trong màn hình
            x = (x + details.delta.dx).clamp(0.0, screenSize.width - 80.0);
            y = (y + details.delta.dy).clamp(0.0, screenSize.height - 150.0);
          });
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bong bóng chat (Speech Bubble)
            if (widget.message.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 10, right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                constraints: const BoxConstraints(maxWidth: 150),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(15),
                    topRight: Radius.circular(15),
                    bottomLeft: Radius.circular(15),
                    bottomRight: Radius.circular(0), // Tạo hình đuôi bong bóng chat
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  widget.message,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

            // Icon Thần Đèn (App Icon của bạn)
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 25,
                backgroundColor: Colors.white,
                // Nếu bạn có file ảnh thật thì dùng Asset, nếu chưa có tạm dùng Icon
                child: widget.imageAssetPath.isNotEmpty
                    ? ClipOval(
                        child: Image.asset(
                          widget.imageAssetPath,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.face, size: 30, color: Colors.blue),
                        ),
                      )
                    : const Icon(Icons.face, size: 30, color: Colors.blue),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

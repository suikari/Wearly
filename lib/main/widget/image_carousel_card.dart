import 'dart:async';
import 'package:flutter/material.dart';

class ImageCarouselCard extends StatefulWidget {
  final List<String> imageUrls;
  final String profileImageUrl;
  final String userName;
  final VoidCallback onUserTap;
  final VoidCallback? onShareTap;
  final bool isLiked;
  final int likeCount;
  final VoidCallback onLikeToggle;

  const ImageCarouselCard({
    Key? key,
    required this.imageUrls,
    required this.profileImageUrl,
    required this.userName,
    required this.onUserTap,
    required this.isLiked,
    required this.likeCount,
    required this.onLikeToggle,
    required this.onShareTap,
  }) : super(key: key);

  @override
  State<ImageCarouselCard> createState() => _ImageCarouselCardState();
}

class _ImageCarouselCardState extends State<ImageCarouselCard> {
  late final PageController _pageController;
  int _currentPage = 0;
  bool _showPageNumber = false;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _hideTimer?.cancel();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index;
      _showPageNumber = true;
    });

    // 타이머 리셋
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _showPageNumber = false;
        });
      }
    });
  }

  void _showImageDialog(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(12),
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Center(
            child: InteractiveViewer(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.9,
                  height: MediaQuery.of(context).size.height * 0.7,
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain, // ✅ 모든 이미지가 박스 내에 맞게
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[300],
                        child: const Center(child: Icon(Icons.broken_image)),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.imageUrls.isEmpty) {
      return Container(
        height: 542,
        decoration: _backgroundDecoration(),
        child: Column(
          children: [
            _buildHeader(),
            const Expanded(
              child: Center(
                child: Text('이미지가 없습니다', style: TextStyle(color: Colors.black45)),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      height: 542,
      decoration: _backgroundDecoration(),
      child: Column(
        children: [
          _buildHeader(),
          const SizedBox(height: 8),
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(50),
                  topLeft: Radius.circular(10),
                  bottomLeft: Radius.circular(50),
                  bottomRight: Radius.circular(10),
                ),
                child: SizedBox(
                  height: 460,
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: widget.imageUrls.length,
                    onPageChanged: _onPageChanged,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () => _showImageDialog(widget.imageUrls[index]),
                        child: Image.network(
                          widget.imageUrls[index],
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[300],
                              child: const Center(child: Icon(Icons.broken_image)),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ),
              // ✅ 슬라이드 중일 때만 페이지 번호 보이기
              Positioned(
                top: 12,
                right: 16,
                child: AnimatedOpacity(
                  opacity: _showPageNumber ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_currentPage + 1} / ${widget.imageUrls.length}',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildPageIndicator(),
        ],
      ),
    );
  }

  BoxDecoration _backgroundDecoration() {
    return BoxDecoration(
      color: Colors.pink[50],
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(10),
        topRight: Radius.circular(50),
        bottomLeft: Radius.circular(50),
        bottomRight: Radius.circular(10),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: widget.onUserTap,
            child: Row(
              children: [
                ClipOval(
                  child: Container(
                    width: 32,
                    height: 32,
                    color: Colors.grey[300],
                    child: widget.profileImageUrl.isNotEmpty
                        ? Image.network(
                      widget.profileImageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(color: Colors.grey[400]);
                      },
                    )
                        : null,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  widget.userName.length > 8
                      ? '${widget.userName.substring(0, 8)}...'
                      : widget.userName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
          ),
          Row(
            children: [
              GestureDetector(
                onTap: widget.onLikeToggle,
                child: Row(
                  children: [
                    Icon(
                      widget.isLiked ? Icons.favorite : Icons.favorite_border,
                      color: widget.isLiked ? Colors.red : Colors.grey,
                      size: 20,
                    ),
                    const SizedBox(width: 4),
                    Text('${widget.likeCount}'),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              if (widget.onShareTap != null)
                GestureDetector(
                  onTap: widget.onShareTap,
                  child: const Icon(Icons.share, size: 20),
                ),
              const SizedBox(width: 16),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(widget.imageUrls.length, (index) {
        final isActive = index == _currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 16 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? Colors.pinkAccent : Colors.grey[300],
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

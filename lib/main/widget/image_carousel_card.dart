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
  final Color cardcolor;
  final Color pointColor;

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
    required this.cardcolor,
    required this.pointColor,
  }) : super(key: key);

  @override
  State<ImageCarouselCard> createState() => _ImageCarouselCardState();
}

class _ImageCarouselCardState extends State<ImageCarouselCard> {
  late final PageController _pageController;
  int _currentPage = 0;
  bool _showPageNumber = false;
  Timer? _hideTimer;

  get cardcolor => widget.cardcolor;

  get pointColor => widget.pointColor;

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
    FocusManager.instance.primaryFocus?.unfocus();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(12),
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: InteractiveViewer(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final calculatedHeight = screenWidth * 4 / 3;
    final baseHeight = calculatedHeight < 460 ? 460.0 : calculatedHeight;
    final containerHeight = baseHeight + 150; // 내부 내용물 높이보다 90 더 크게

    if (widget.imageUrls.isEmpty) {
      return Container(
        height: containerHeight,
        decoration: _backgroundDecoration(),
        child: Column(
          children: [
            _buildHeader(),
            const Expanded(
              child: Center(
                child: Text(
                  '이미지가 없습니다',
                  style: TextStyle(color: Colors.black45),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final cardHeight = calculatedHeight < 460 ? 460.0 : calculatedHeight;

// headerHeight와 여백도 비율로 계산 (예: 가로 20% 정도를 header에 할당)
    final headerHeight = screenWidth * 0.12; // 필요하면 조정
    final bottomMargin = screenWidth * 0.1;// 고정값 또는 비율로도 가능

    final pageViewHeight = cardHeight - headerHeight - bottomMargin;

    return Container(
      height: cardHeight,
      decoration: _backgroundDecoration(),
      child: Column(
        children: [
          SizedBox(height: headerHeight, child: _buildHeader()),
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
                  height: pageViewHeight,  // 전체 높이에서 헤더, 간격, 페이지 인디케이터 높이 뺀 값
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
          SizedBox(
            height: 20, // _buildPageIndicator() 예상 높이 (필요시 조정)
            child: _buildPageIndicator(),
          ),
        ],
      ),
    );

  }

  BoxDecoration _backgroundDecoration() {
    return BoxDecoration(
      color: cardcolor,
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
                      color: widget.isLiked ? pointColor : Colors.grey,
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
            color: isActive ? pointColor : Colors.grey[300],
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

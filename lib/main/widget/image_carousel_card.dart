import 'package:flutter/material.dart';

class ImageCarouselCard extends StatefulWidget {
  final List<String> imageUrls;
  final String profileImageUrl;
  final String userName;
  final VoidCallback onUserTap;
  final VoidCallback? onShareTap; // 추가

  // ✅ 추가
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

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomNavTheme = theme.bottomNavigationBarTheme;
    final backgroundColor = theme.scaffoldBackgroundColor;
    final navBackgroundColor = bottomNavTheme.backgroundColor ?? theme.primaryColor;
    final selectedItemColor = bottomNavTheme.selectedItemColor ?? Colors.white;
    final unselectedItemColor = bottomNavTheme.unselectedItemColor ?? Colors.white70;
    final screenWidth = MediaQuery.of(context).size.width;

    if (widget.imageUrls.isEmpty) {
      return Container(
        height: 520, // 높이 늘림 (아래 인디케이터 공간 확보)
        decoration: BoxDecoration(
          color: Colors.pink[50],
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(60),
            bottomLeft: Radius.circular(40),
            bottomRight: Radius.circular(40),
          ),
        ),
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

    if (widget.imageUrls.length == 1) {
      return SizedBox(
        height: 520,
        child: Column(
          children: [
            _buildImageCard(widget.imageUrls[0]),
            const SizedBox(height: 12),
            _buildPageIndicator(), // 1개라도 인디케이터 표시 가능
          ],
        ),
      );
    } else {
      return SizedBox(
        height: 520,
        child: Column(
          children: [
            SizedBox(
              height: 480,
              child: PageView.builder(
                controller: _pageController,
                itemCount: widget.imageUrls.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  return _buildImageCard(widget.imageUrls[index]);
                },
              ),
            ),
            const SizedBox(height: 12),
            _buildPageIndicator(),
          ],
        ),
      );
    }
  }

  Widget _buildHeader() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(10),
          topRight: Radius.circular(50),
        ),
      ),
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
                  widget.userName.length > 8 ? '${widget.userName.substring(0, 8)}...' : widget.userName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
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
                    child: const Icon(Icons.share, size: 20)),
              const SizedBox(width: 16),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImageCard(String imageUrl) {
    return Container(
      height: 480,
      decoration: BoxDecoration(
        color: Colors.pink[50],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(10),
          topRight: Radius.circular(50),
          bottomLeft: Radius.circular(50),
          bottomRight: Radius.circular(10),
        ),
      ),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(50),
                topLeft: Radius.circular(10),
                bottomLeft: Radius.circular(50),
                bottomRight: Radius.circular(10),
              ),
              child: Image.network(
                imageUrl,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
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

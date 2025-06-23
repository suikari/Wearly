// image_carousel_card.dart
import 'package:flutter/material.dart';

class ImageCarouselCard extends StatelessWidget {
  final List<String> imageUrls;
  final String profileImageUrl;
  final String userName;
  final VoidCallback onUserTap;
  final VoidCallback? onShareTap;  // 추가

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
  Widget build(BuildContext context) {

    final theme = Theme.of(context);
    final bottomNavTheme = theme.bottomNavigationBarTheme;
    final backgroundColor = theme.scaffoldBackgroundColor;
    final navBackgroundColor = bottomNavTheme.backgroundColor ?? theme.primaryColor;
    final selectedItemColor = bottomNavTheme.selectedItemColor ?? Colors.white;
    final unselectedItemColor = bottomNavTheme.unselectedItemColor ?? Colors.white70;
    final screenWidth = MediaQuery.of(context).size.width;

    if (imageUrls.isEmpty) {
      return Container(
        height: 480,
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

    if (imageUrls.length == 1) {
      return _buildImageCard(imageUrls[0]);
    } else {
      return SizedBox(
        height: 480,
        child: PageView.builder(
          itemCount: imageUrls.length,
          itemBuilder: (context, index) {
            return _buildImageCard(imageUrls[index]);
          },
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
            onTap: onUserTap,
            child: Row(
              children: [
                ClipOval(
                  child: Container(
                    width: 32,
                    height: 32,
                    color: Colors.grey[300],
                    child: profileImageUrl.isNotEmpty
                        ? Image.network(
                      profileImageUrl,
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
                  userName.length > 8 ? '${userName.substring(0, 8)}...' : userName,
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
                onTap: onLikeToggle,
                child: Row(
                  children: [
                    Icon(
                      isLiked ? Icons.favorite : Icons.favorite_border,
                      color: isLiked ? Colors.red : Colors.grey,
                      size: 20,
                    ),
                    SizedBox(width: 4),
                    Text('$likeCount'),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: onShareTap,
                child: Icon(Icons.share, size: 20)
              ),

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
}

import 'package:flutter/material.dart';

class AdBannerSection extends StatefulWidget {
  const AdBannerSection({super.key});

  @override
  State<AdBannerSection> createState() => _AdBannerSectionState();
}

class _AdBannerSectionState extends State<AdBannerSection> {
  final List<String> adImages = [
    'assets/ad_banner5.jpg',
    'assets/ad_banner2.jpg',
    'assets/ad_banner3.jpg',
    'assets/ad_banner4.jpg',
    'assets/ad_banner1.jpg',
  ];
  int currentPage = 0;
  final PageController _pageController = PageController();

  final List<Map<String, String>> zigzagThumbs = [
    {
      "img": "assets/ad_banner2.jpg",
      "brand": "바이보니",
    },
    {
      "img": "assets/ad_banner3.jpg",
      "brand": "moment.",
    },
    {
      "img": "assets/ad_banner4.jpg",
      "brand": "써스데이아일랜드",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 광고 1 (상단 고정)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Card(
            elevation: 6,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.asset(
                adImages[0], // 광고1 이미지는 고정
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        // 광고2: ZIGZAG 스타일 + 슬라이드/썸네일 연동
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 상단 타이틀
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 8),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Color(0xffe15eef),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          "Z",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 20,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    Text(
                      "광고2",
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Spacer(),
                    Icon(Icons.two_k, size: 22, color: Colors.grey[700]),
                  ],
                ),
              ),
              // 메인(대표) 이미지 : PageView로 바꿈!
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: AspectRatio(
                  aspectRatio: 0.78, // 이미지 비율
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: zigzagThumbs.length,
                      onPageChanged: (idx) {
                        setState(() {
                          currentPage = idx;
                        });
                      },
                      itemBuilder: (context, idx) {
                        return Image.asset(
                          zigzagThumbs[idx]["img"]!,
                          fit: BoxFit.cover,
                        );
                      },
                    ),
                  ),
                ),
              ),
              // 썸네일 3개 (하단)
              Padding(
                padding: const EdgeInsets.only(top: 14, left: 10, right: 10),
                child: Row(
                  children: List.generate(zigzagThumbs.length, (idx) {
                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          _pageController.animateToPage(
                            idx,
                            duration: Duration(milliseconds: 250),
                            curve: Curves.easeInOut,
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: currentPage == idx
                                        ? Color(0xffe15eef)
                                        : Colors.transparent,
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(13),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(13),
                                  child: AspectRatio(
                                    aspectRatio: 1,
                                    child: Image.asset(
                                      zigzagThumbs[idx]["img"]!,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                zigzagThumbs[idx]["brand"]!,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Row(
                                children: [
                                  Icon(
                                    Icons.favorite_border,
                                    size: 15,
                                    color: Colors.grey[600],
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    "99+",
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// WeeklyBestWidget는 변경 없음
class WeeklyBestWidget extends StatelessWidget {
  const WeeklyBestWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Text(
            'WEEKLY WEARLY BEST',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 6),
          child: Text(
            '2025.06.02 ~ 2025.06.08',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 1등
            Column(
              children: [
                Container(
                  width: 160,
                  height: 160,
                  margin: EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    image: DecorationImage(
                      image: AssetImage('assets/profile1.jpg'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Row(
                  children: [
                    Icon(Icons.emoji_events, color: Colors.orange, size: 18),
                    SizedBox(width: 4),
                    Text('옆집악마', style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(width: 4),
                    Icon(Icons.favorite, color: Colors.pink, size: 15),
                    SizedBox(width: 2),
                    Text('1,253'),
                  ],
                ),
              ],
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 2등
            Column(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  margin: EdgeInsets.only(top: 10, right: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    image: DecorationImage(
                      image: AssetImage('assets/profile2.jpg'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Row(
                  children: [
                    Icon(Icons.account_circle, size: 16, color: Colors.grey),
                    SizedBox(width: 2),
                    Text(
                      'Ranez',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.favorite, color: Colors.pink, size: 13),
                    SizedBox(width: 2),
                    Text('1,111', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ],
            ),
            // 3등
            Column(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  margin: EdgeInsets.only(top: 10, left: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    image: DecorationImage(
                      image: AssetImage('assets/profile3.jpg'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Row(
                  children: [
                    Icon(Icons.account_circle, size: 16, color: Colors.grey),
                    SizedBox(width: 2),
                    Text('이두나', style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(width: 4),
                    Icon(Icons.favorite, color: Colors.pink, size: 13),
                    SizedBox(width: 2),
                    Text('987', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ],
            ),
          ],
        ),
        SizedBox(height: 28),
      ],
    );
  }
}

import 'package:flutter/material.dart';

class PostsScreen extends StatefulWidget {
  const PostsScreen({super.key});

  @override
  State<PostsScreen> createState() => _PostsScreenState();
}

class _PostsScreenState extends State<PostsScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final List<Post> _posts = [
    Post(
      id: '1',
      authorName: 'أحمد محمد',
      authorAvatar: 'https://via.placeholder.com/50',
      content: 'مرحباً بالجميع في تطبيق HUS! أتطلع للانضمام إلى غرف الدردشة الصوتية قريباً 🎤',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      likes: 15,
      comments: 3,
      isLiked: false,
    ),
    Post(
      id: '2',
      authorName: 'فاطمة أحمد',
      authorAvatar: 'https://via.placeholder.com/50',
      content: 'هل يمكن لأحد أن يشرح لي كيفية إنشاء غرفة صوتية جديدة؟ شكراً مقدماً! 🙏',
      timestamp: DateTime.now().subtract(const Duration(hours: 5)),
      likes: 8,
      comments: 7,
      isLiked: true,
    ),
    Post(
      id: '3',
      authorName: 'محمد علي',
      authorAvatar: 'https://via.placeholder.com/50',
      content: 'تجربة رائعة مع التطبيق حتى الآن! التصميم جميل والفكرة مبتكرة ✨',
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      likes: 23,
      comments: 12,
      isLiked: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            floating: true,
            backgroundColor: Colors.white,
            elevation: 0,
            title: const Text(
              'المنشورات',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1f2937),
                fontFamily: 'Cairo',
              ),
            ),
            actions: [
              IconButton(
                onPressed: _showCreatePostDialog,
                icon: const Icon(
                  Icons.add_circle_outline,
                  color: Color(0xFF8b5cf6),
                ),
              ),
            ],
          ),

          // قائمة المنشورات
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  if (index == 0) {
                    return Column(
                      children: [
                        _buildCreatePostCard(),
                        const SizedBox(height: 16),
                        _buildPostCard(_posts[0]),
                      ],
                    );
                  }
                  return Column(
                    children: [
                      const SizedBox(height: 16),
                      _buildPostCard(_posts[index]),
                    ],
                  );
                },
                childCount: _posts.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreatePostCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xFF8b5cf6),
            child: const Icon(
              Icons.person,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: _showCreatePostDialog,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Text(
                  'ما الذي تفكر فيه؟',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                    fontFamily: 'Cairo',
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            onPressed: _showCreatePostDialog,
            icon: const Icon(
              Icons.photo_camera,
              color: Color(0xFF8b5cf6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostCard(Post post) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // رأس المنشور
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: NetworkImage(post.authorAvatar),
                onBackgroundImageError: (exception, stackTrace) {},
                child: post.authorAvatar.contains('placeholder')
                    ? Text(
                        post.authorName[0],
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.authorName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cairo',
                      ),
                    ),
                    Text(
                      _formatTimestamp(post.timestamp),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _showPostOptions(post),
                icon: const Icon(Icons.more_horiz),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // محتوى المنشور
          Text(
            post.content,
            style: const TextStyle(
              fontSize: 16,
              height: 1.5,
              fontFamily: 'Cairo',
            ),
          ),
          
          const SizedBox(height: 16),
          
          // أزرار التفاعل
          Row(
            children: [
              _buildInteractionButton(
                icon: post.isLiked ? Icons.favorite : Icons.favorite_border,
                label: '${post.likes}',
                color: post.isLiked ? Colors.red : Colors.grey[600]!,
                onTap: () => _toggleLike(post),
              ),
              const SizedBox(width: 24),
              _buildInteractionButton(
                icon: Icons.chat_bubble_outline,
                label: '${post.comments}',
                color: Colors.grey[600]!,
                onTap: () => _showComments(post),
              ),
              const SizedBox(width: 24),
              _buildInteractionButton(
                icon: Icons.share_outlined,
                label: 'مشاركة',
                color: Colors.grey[600]!,
                onTap: () => _sharePost(post),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInteractionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: color,
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 60) {
      return 'منذ ${difference.inMinutes} دقيقة';
    } else if (difference.inHours < 24) {
      return 'منذ ${difference.inHours} ساعة';
    } else {
      return 'منذ ${difference.inDays} يوم';
    }
  }

  void _showCreatePostDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'إنشاء منشور جديد',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo',
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'ما الذي تفكر فيه؟',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      maxLines: 5,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[300],
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'إلغاء',
                              style: TextStyle(fontFamily: 'Cairo'),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('سيتم إضافة هذه الميزة قريباً'),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF8b5cf6),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'نشر',
                              style: TextStyle(fontFamily: 'Cairo'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleLike(Post post) {
    setState(() {
      post.isLiked = !post.isLiked;
      post.likes += post.isLiked ? 1 : -1;
    });
  }

  void _showComments(Post post) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('سيتم إضافة التعليقات قريباً'),
      ),
    );
  }

  void _sharePost(Post post) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('سيتم إضافة المشاركة قريباً'),
      ),
    );
  }

  void _showPostOptions(Post post) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.bookmark_border),
              title: const Text(
                'حفظ المنشور',
                style: TextStyle(fontFamily: 'Cairo'),
              ),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم حفظ المنشور')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.report_outlined),
              title: const Text(
                'الإبلاغ عن المنشور',
                style: TextStyle(fontFamily: 'Cairo'),
              ),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم الإبلاغ عن المنشور')),
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class Post {
  final String id;
  final String authorName;
  final String authorAvatar;
  final String content;
  final DateTime timestamp;
  int likes;
  final int comments;
  bool isLiked;

  Post({
    required this.id,
    required this.authorName,
    required this.authorAvatar,
    required this.content,
    required this.timestamp,
    required this.likes,
    required this.comments,
    required this.isLiked,
  });
}


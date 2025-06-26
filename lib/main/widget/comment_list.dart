import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CommentSection extends StatefulWidget {
  final String feedId;
  final String currentUserId;
  final void Function(String)? onUserTap; // ← 콜백 타입 정의
  static FocusNode? globalFocusNode;


  const CommentSection({
    Key? key,
    required this.feedId,
    required this.currentUserId,

    this.onUserTap,
  }) : super(key: key);

  @override
  State<CommentSection> createState() => _CommentSectionState();
}

class _CommentSectionState extends State<CommentSection> {
  final TextEditingController commentController = TextEditingController();
  final TextEditingController replycommentController = TextEditingController();
  final TextEditingController editingController = TextEditingController();
  final FocusNode commentFocusNode = FocusNode();

  String? replyingToId;
  String? editingCommentId;
  String? postWriteUserId;

  late Future<List<Comment>> _commentFuture;


  @override
  void initState() {
    super.initState();
    CommentSection.globalFocusNode = commentFocusNode;
    _commentFuture = _loadComments();
  }

  void _refreshComments() {
    setState(() {
      _commentFuture = _loadComments();
    });
  }

  Future<List<Comment>> _loadComments() async {
    final commentsRef = FirebaseFirestore.instance
        .collection('feeds')
        .doc(widget.feedId)
        .collection('comment');
    final snapshot = await commentsRef.orderBy('cdatetime').get();

    final List<Comment> comments = [];
    final Map<String, UserData> userCache = {};

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final userId = (data['userId'] ?? '').toString();
      final commentText = data['comment']?.toString() ?? '';
      final timestamp = data['cdatetime'] as Timestamp?;
      final parentId = data['parentId']?.toString();

      String nickname = '익명';
      String profileImage = '';

      if (userId.isNotEmpty) {
        if (userCache.containsKey(userId)) {
          final cached = userCache[userId]!;
          nickname = cached.nickname;
          profileImage = cached.profileImage;
        } else {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .get();
          if (userDoc.exists) {
            final userData = userDoc.data() ?? {};
            nickname = userData['nickname']?.toString() ?? '익명';
            profileImage = userData['profileImage']?.toString() ?? '';
            userCache[userId] = UserData(
              nickname: nickname,
              profileImage: profileImage,
            );
          }
        }
      }

      comments.add(Comment(
        id: doc.id,
        userId: userId,
        userName: nickname,
        userprofileImage: profileImage,
        comment: commentText,
        cdatetime: timestamp?.toDate() ?? DateTime.now(),
        parentId: parentId,
      ));
    }

    return comments;
  }

  Future<void> _addComment(String text) async {
    if (text.trim().isEmpty) return;

    final commentData = {
      'userId': widget.currentUserId,
      'comment': text.trim(),
      'cdatetime': Timestamp.now(),
      'parentId': replyingToId,
    };

    final commentsRef = FirebaseFirestore.instance
        .collection('feeds')
        .doc(widget.feedId)
        .collection('comment');

    if (editingCommentId != null) {
      await commentsRef.doc(editingCommentId).update({'comment': text.trim()});
    } else {
      await FirebaseFirestore.instance.collection('notifications').add({
        'uid' : postWriteUserId, // 알림 받을 사람(피드 주인)
        'type' : 'comment',
        'fromUid': widget.currentUserId,
        'content': ' 게시글에 댓글을 남겼습니다. ',
        'postId': widget.feedId,
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
      });

      await commentsRef.add(commentData);
    }

    setState(() {
      replyingToId = null;
      editingCommentId = null;
      commentController.clear();
      replycommentController.clear();
    });

    _refreshComments();
  }

  Future<void> _deleteComment(String commentId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("댓글 삭제"),
        content: const Text("정말로 이 댓글을 삭제하시겠습니까? 대댓글도 함께 삭제됩니다."),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("취소"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("삭제", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final commentsRef = FirebaseFirestore.instance
        .collection('feeds')
        .doc(widget.feedId)
        .collection('comment');

    final replies = await commentsRef.where('parentId', isEqualTo: commentId).get();
    for (var doc in replies.docs) {
      await doc.reference.delete();
    }

    await commentsRef.doc(commentId).delete();
    _refreshComments();
  }

  Widget _buildCommentInput() {
    return Row(
        children: [
          Expanded(
            child: TextField(
              controller: commentController,
              decoration: InputDecoration(
                hintText: "댓글을 입력하세요",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {
              if (commentController.text != '') {
                replyingToId = null;
                _addComment(commentController.text);
              }
            },
            child: const Text("등록"),
          ),
        ],
    );
  }

  Widget _buildreplyCommentInput({String? hintText}) {
    return Row(
        children: [
          Expanded(
            child: TextField(
              controller: replycommentController,
              focusNode: commentFocusNode,
              decoration: InputDecoration(
                hintText: hintText ?? "답글 입력...",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {
              if (replycommentController.text != '') {
                _addComment(replycommentController.text);
              }
            },
            child: const Text("등록"),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                replyingToId = null;
                editingCommentId = null;
                replycommentController.clear();
              });
            },
            child: const Text("취소"),
          ),
        ],
    );
  }

  Widget _buildCommentTile({
    required Comment comment,
    required bool isReply,
    required Map<String, List<Comment>> replyMap,
  }) {
    final isAuthor = comment.userId == widget.currentUserId;
    final isReplyingHere = replyingToId == comment.id;
    final replies = replyMap[comment.id] ?? [];

    postWriteUserId = comment.userId;

    if (isReplyingHere  && !commentFocusNode.hasFocus) {
      Future.microtask(() {
        if (mounted) commentFocusNode.requestFocus();
      });
    }
    final avatar = comment.userprofileImage != null && comment.userprofileImage!.isNotEmpty
        ? CircleAvatar(
      radius: 12,
      backgroundImage: NetworkImage(comment.userprofileImage!),
    )
        : const CircleAvatar(
      radius: 18,
      child: Icon(Icons.person, size: 18),
    );

    return Padding(
      padding: EdgeInsets.only(left: isReply ? 40 : 0, top: 8, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              widget.onUserTap != null
                  ? GestureDetector(
                behavior: HitTestBehavior.translucent, 
                onTap: () {
                  widget.onUserTap!(comment.userId);
                },
                child: avatar,
              ) : avatar,
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(comment.userName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text(
                          DateFormat('MM-dd HH:mm').format(comment.cdatetime),
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    editingCommentId == comment.id
                        ? Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: editingController..text = comment.comment,
                            autofocus: true,
                            decoration: const InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 1,
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          height: 36,
                          child: ElevatedButton(
                            onPressed: () {
                              _addComment(editingController.text);
                            },
                            child: const Text("수정", style: TextStyle(fontSize: 12)),
                          ),
                        ),
                        const SizedBox(width: 4),
                        SizedBox(
                          height: 36,
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                editingCommentId = null;
                                editingController.clear();
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[300],
                            ),
                            child: const Text("취소", style: TextStyle(fontSize: 12, color: Colors.black)),
                          ),
                        ),
                      ],
                    )
                        : Text(comment.comment),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isAuthor)
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  editingCommentId = comment.id;
                                  replyingToId = null;
                                });
                              },
                              child: const Text("수정", style: TextStyle(fontSize: 12)),
                            ),
                          if (isAuthor)
                            TextButton(
                              onPressed: () => _deleteComment(comment.id),
                              child: const Text("삭제", style: TextStyle(fontSize: 12)),
                            ),
                          if (!isReply)
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  replyingToId = comment.id;
                                  editingCommentId = null;
                                  commentController.clear();
                                });
                              },
                              child: const Text("답글", style: TextStyle(fontSize: 12)),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (!isReply) ...[
            const SizedBox(height: 8),
            ...replies.map((reply) => _buildCommentTile(comment: reply, isReply: true, replyMap: replyMap)),
            if (isReplyingHere)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: _buildreplyCommentInput(),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildComments(List<Comment> allComments) {
    final rootComments = allComments.where((c) => c.parentId == null).toList();
    final Map<String, List<Comment>> replyMap = {};

    for (var comment in allComments) {
      if (comment.parentId != null) {
        replyMap.putIfAbsent(comment.parentId!, () => []);
        replyMap[comment.parentId!]!.add(comment);
      }
    }

    return Column(
      children: rootComments
          .map((comment) => _buildCommentTile(comment: comment, isReply: false, replyMap: replyMap))
          .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Column(
        children: [
          FutureBuilder<List<Comment>>(
            future: _commentFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Text('댓글 로딩 오류: ${snapshot.error}');
              }
              final comments = snapshot.data ?? [];
              if (comments.isEmpty) {
                return const Text('아직 댓글이 없습니다. 첫 댓글을 남겨보세요!');
              }
              return _buildComments(comments);
            },
          ),
          const SizedBox(height: 8),
          _buildCommentInput(),
        ],
      ),
    );
  }

  @override
  void dispose() {
    CommentSection.globalFocusNode = null;
    commentController.dispose();
    replycommentController.dispose();
    editingController.dispose();
    commentFocusNode.dispose();
    super.dispose();
  }
}

class Comment {
  final String id;
  final String userId;
  final String userName;
  final String comment;
  final DateTime cdatetime;
  final String? parentId;
  final String? userprofileImage;

  Comment({
    required this.id,
    required this.userId,
    required this.userName,
    required this.comment,
    required this.cdatetime,
    this.parentId,
    this.userprofileImage,
  });
}

class UserData {
  final String nickname;
  final String profileImage;

  UserData({
    required this.nickname,
    required this.profileImage,
  });

}

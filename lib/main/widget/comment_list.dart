import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CommentSection extends StatefulWidget {
  final String feedId;
  final String currentUserId; // 현재 로그인한 유저 ID를 외부에서 받음

  const CommentSection({
    Key? key,
    required this.feedId,
    required this.currentUserId,
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

  @override
  void dispose() {
    commentController.dispose();
    commentFocusNode.dispose();
    super.dispose();
  }

  Future<void> _addComment(String text) async {
    if (text.trim().isEmpty) return;

    final commentData = {
      'userId': widget.currentUserId,
      'userName': 'User', // 필요시 로그인 유저 이름으로 수정하세요
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
      await commentsRef.add(commentData);
    }

    setState(() {
      replyingToId = null;
      editingCommentId = null;
      commentController.clear();
      replycommentController.clear();
    });
  }

  Future<void> _deleteComment(String commentId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("댓글 삭제"),
        content: const Text("정말로 이 댓글을 삭제하시겠습니까? 대댓글도 함께 삭제됩니다."),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false), // 취소
            child: const Text("취소"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true), // 확인
            child: const Text("삭제", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return; // 사용자가 취소하면 중단

    final commentsRef = FirebaseFirestore.instance
        .collection('feeds')
        .doc(widget.feedId)
        .collection('comment');

    // 대댓글 함께 삭제 (1차 대댓글까지만)
    final replies = await commentsRef.where('parentId', isEqualTo: commentId).get();
    for (var doc in replies.docs) {
      await doc.reference.delete();
    }

    await commentsRef.doc(commentId).delete();
  }

  Widget _buildCommentInput({String? hintText}) {
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
          child: Text("등록"),
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
              hintText: hintText ?? (replyingToId != null ? "답글 입력..." : "댓글을 입력하세요"),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: () {
              if (replycommentController.text != '') {
              replyingToId = null;
              _addComment(replycommentController.text);
              }
          },
          child: Text("등록"),
        ),
        ElevatedButton(
          onPressed: () {

            setState(() {
              replyingToId = null;
              editingCommentId = null;
              replycommentController.clear();
            });

          },
          child: Text("취소"),
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

    // 답글 작성창이 켜질 때 포커스 주기
    if (isReplyingHere) {
      Future.microtask(() {
        if (mounted) {
          commentFocusNode.requestFocus();
        }
      });
    }

    return Padding(
      padding: EdgeInsets.only(left: isReply ? 40 : 0, top: 8, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CircleAvatar(radius: 18, child: Icon(Icons.person, size: 18)),
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
                            // TextField 영역 (가변 너비)
                            Expanded(
                              child: TextField(
                                controller: editingController..text = comment.comment,
                                autofocus: true,
                                decoration: const InputDecoration(
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                  border: OutlineInputBorder(),
                                ),
                                maxLines: 1, // 한 줄로 제한
                              ),
                            ),
                            const SizedBox(width: 8),

                            // 수정 버튼
                            SizedBox(
                              height: 36,
                              child: ElevatedButton(
                                onPressed: () {
                                  _addComment(editingController.text);
                                },
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  minimumSize: const Size(40, 36),
                                ),
                                child: const Text("수정", style: TextStyle(fontSize: 12)),
                              ),
                            ),
                            const SizedBox(width: 4),

                            // 취소 버튼
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
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  minimumSize: const Size(40, 36),
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

            // 1차 대댓글만 표시
            ...replies.map((reply) => _buildCommentTile(comment: reply, isReply: true, replyMap: replyMap)),

            // 답글 작성창은 해당 댓글 밑, 대댓글 밑 마지막에 표시
            if (isReplyingHere)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: _buildreplyCommentInput(hintText: "답글을 입력하세요"),
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
    final commentsRef = FirebaseFirestore.instance
        .collection('feeds')
        .doc(widget.feedId)
        .collection('comment')
        .orderBy('cdatetime');

    return Column(
      children: [
        StreamBuilder<QuerySnapshot>(
          stream: commentsRef.snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const CircularProgressIndicator();

            final commentDocs = snapshot.data!.docs;
            final comments = commentDocs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return Comment(
                id: doc.id,
                userId: data['userId'] ?? '',
                userName: data['userName'] ?? '익명',
                comment: data['comment'] ?? '',
                cdatetime: (data['cdatetime'] as Timestamp).toDate(),
                parentId: data['parentId'],
              );
            }).toList();

            return _buildComments(comments);
          },
        ),
        const SizedBox(height: 8),
        // 항상 화면 맨 아래에 댓글 등록창 보여줌 (최상위 댓글 등록창)
        _buildCommentInput(),
      ],
    );
  }
}

class Comment {
  final String id;
  final String userId;
  final String userName;
  final String comment;
  final DateTime cdatetime;
  final String? parentId;

  Comment({
    required this.id,
    required this.userId,
    required this.userName,
    required this.comment,
    required this.cdatetime,
    this.parentId,
  });
}

import 'package/lib.Dieat.dart';

class CommunityScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  CommunityScreen({required this.userData});

  @override
  _CommunityScreenState createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();
  List<Post> _posts = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      QuerySnapshot snapshot = await _firestore
          .collection('posts')
          .orderBy('timestamp', descending: true)
          .get();

      setState(() {
        _posts = snapshot.docs
            .map((doc) =>
            Post.fromDocument(doc.id, doc.data() as Map<String, dynamic>))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      print("Error loading posts: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _createPost() async {
    String? category;
    String? title;
    String? content;
    File? image;

    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: Text('새 게시물 작성'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: category,
                      hint: Text('카테고리 선택'),
                      items: ['약 복용', '사진']
                          .map((label) => DropdownMenuItem(
                        child: Text(label),
                        value: label,
                      ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          category = value;
                        });
                      },
                    ),
                    TextField(
                      decoration: InputDecoration(hintText: "제목"),
                      onChanged: (value) => title = value,
                    ),
                    TextField(
                      maxLines: 3,
                      decoration: InputDecoration(hintText: "내용"),
                      onChanged: (value) => content = value,
                    ),
                    ElevatedButton(
                      child: Text('이미지 선택'),
                      onPressed: () async {
                        final XFile? selectedImage = await _picker.pickImage(
                            source: ImageSource.gallery);
                        if (selectedImage != null) {
                          setState(() {
                            image = File(selectedImage.path);
                          });
                        }
                      },
                    ),
                    if (image != null) Image.file(image!, height: 100),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                    child: Text('취소'),
                    onPressed: () => Navigator.of(context).pop()),
                TextButton(
                  child: Text('게시'),
                  onPressed: () async {
                    if (category != null && title != null && content != null) {
                      Navigator.of(context).pop();
                      await _uploadPost(category!, title!, content!, image);
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _uploadPost(
      String category, String title, String content, File? image) async {
    setState(() {
      _isLoading = true;
    });

    try {
      String? imageUrl;
      if (image != null) {
        File compressedImage = await compressImage(image);
        imageUrl = await _uploadImage(compressedImage);
      }

      DocumentReference postRef = await _firestore.collection('posts').add({
        'category': category,
        'title': title,
        'content': content,
        'imageUrl': imageUrl,
        'author': widget.userData['name'],
        'authorId': FirebaseAuth.instance.currentUser?.uid,
        'timestamp': FieldValue.serverTimestamp(),
        'likes': [],
      });

      Post newPost = Post(
        id: postRef.id,
        category: category,
        title: title,
        content: content,
        imageUrl: imageUrl,
        author: widget.userData['name'],
        authorId: FirebaseAuth.instance.currentUser?.uid ?? '',
        timestamp: DateTime.now(),
        likes: [],
      );

      setState(() {
        _posts.insert(0, newPost);
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('게시물이 성공적으로 업로드되었습니다.')),
      );
    } catch (e) {
      print("Error uploading post: $e");
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('게시물 업로드 중 오류가 발생했습니다.')),
      );
    }
  }

  Future<String> _uploadImage(File image) async {
    final ref = FirebaseStorage.instance
        .ref()
        .child('post_images/${DateTime.now().toString()}');
    final uploadTask = ref.putFile(image);

    uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
      final progress = snapshot.bytesTransferred / snapshot.totalBytes;
      print('Upload is $progress% complete.');
    });

    await uploadTask;
    return await ref.getDownloadURL();
  }

  Future<File> compressImage(File file) async {
    final filePath = file.absolute.path;
    final lastIndex = filePath.lastIndexOf(RegExp(r'.jpg|.png'));
    final splitted = filePath.substring(0, lastIndex);
    final outPath = "${splitted}_compressed.jpg";
    var result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      outPath,
      quality: 70,
    );
    return result!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Yakson 커뮤니티"),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _createPost,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: _posts.length,
        itemBuilder: (context, index) {
          return PostWidget(
              post: _posts[index], userData: widget.userData);
        },
      ),
    );
  }
}

class Post {
  final String id;
  final String category;
  final String title;
  final String content;
  final String? imageUrl;
  final String author;
  final String authorId;
  final DateTime timestamp;
  final List<String> likes;

  Post({
    required this.id,
    required this.category,
    required this.title,
    required this.content,
    this.imageUrl,
    required this.author,
    required this.authorId,
    required this.timestamp,
    required this.likes,
  });

  factory Post.fromDocument(String id, Map<String, dynamic> doc) {
    var likesData = doc['likes'];
    List<String> likesList;
    if (likesData is List) {
      likesList = likesData.map((item) => item.toString()).toList();
    } else if (likesData is int) {
      likesList = List.generate(likesData, (index) => index.toString());
    } else {
      likesList = [];
    }

    return Post(
      id: id,
      category: doc['category'] ?? '',
      title: doc['title'] ?? '',
      content: doc['content'] ?? '',
      imageUrl: doc['imageUrl'],
      author: doc['author'] ?? '',
      authorId: doc['authorId'] ?? '',
      timestamp: (doc['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      likes: likesList,
    );
  }
}

class PostWidget extends StatelessWidget {
  final Post post;
  final Map<String, dynamic> userData;

  PostWidget({required this.post, required this.userData});

  void _likePost(BuildContext context) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      final postRef =
      FirebaseFirestore.instance.collection('posts').doc(post.id);
      if (post.likes.contains(userId)) {
        await postRef.update({
          'likes': FieldValue.arrayRemove([userId])
        });
      } else {
        await postRef.update({
          'likes': FieldValue.arrayUnion([userId])
        });
      }
    }
  }

  Future<void> _sharePost(BuildContext context) async {
    final DynamicLinkParameters parameters = DynamicLinkParameters(
      uriPrefix: 'https://yourapp.page.link',
      link: Uri.parse('https://yourapp.com/post/${post.id}'),
      androidParameters: AndroidParameters(
        packageName: 'com.example.yourapp',
      ),
      iosParameters: IOSParameters(
        bundleId: 'com.example.yourapp',
      ),
    );

    final ShortDynamicLink shortLink =
    await FirebaseDynamicLinks.instance.buildShortLink(parameters);
    final Uri shortUrl = shortLink.shortUrl;

    await Share.share('내 게시물을 확인해보세요: $shortUrl');
  }

  void _showComments(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => CommentsWidget(postId: post.id),
    );
  }

  Color _getCategoryColor() {
    switch (post.category) {
      case '약 복용 인증':
        return Colors.green[100]!;
      case '사진':
        return Colors.yellow[100]!;
      default:
        return Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    final isLiked = userId != null && post.likes.contains(userId);

    return Card(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundImage: NetworkImage('https://via.placeholder.com/150'),
            ),
            title: Text(post.author),
            subtitle: Text(timeago.format(post.timestamp)),
            trailing: Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getCategoryColor(),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                post.category,
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          if (post.imageUrl != null)
            Image.network(post.imageUrl!,
                height: 200, width: double.infinity, fit: BoxFit.cover),
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(post.title,
                    style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text(post.content),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                          isLiked ? Icons.favorite : Icons.favorite_border,
                          color: isLiked ? Colors.green : null),
                      onPressed: () => _likePost(context),
                    ),
                    Text('${post.likes.length}'),
                    SizedBox(width: 16),
                    IconButton(
                      icon: Icon(Icons.comment),
                      onPressed: () => _showComments(context),
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(Icons.share),
                  onPressed: () => _sharePost(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// 커뮤니티 댓글 관련

class CommentsWidget extends StatefulWidget {
  final String postId;

  CommentsWidget({required this.postId});

  @override
  _CommentsWidgetState createState() => _CommentsWidgetState();
}

class _CommentsWidgetState extends State<CommentsWidget> {
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _commentController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _addComment() async {
    if (_commentController.text.isNotEmpty) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          await FirebaseFirestore.instance
              .collection('posts')
              .doc(widget.postId)
              .collection('comments')
              .add({
            'content': _commentController.text,
            'author': user.displayName ?? 'Anonymous',
            'authorId': user.uid,
            'timestamp': FieldValue.serverTimestamp(),
          });
          _commentController.clear();
          print('댓글이 성공적으로 추가되었습니다.');
        } catch (e) {
          print('댓글 추가 중 오류 발생: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('댓글 추가 중 오류가 발생했습니다.')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('posts')
                  .doc(widget.postId)
                  .collection('comments')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('오류가 발생했습니다: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                final comments = snapshot.data?.docs ?? [];

                if (comments.isEmpty) {
                  return Center(child: Text('아직 댓글이 없습니다.'));
                }

                return ListView.builder(
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final data = comments[index].data() as Map<String, dynamic>;
                    return ListTile(
                      title: Text(data['author'] ?? ''),
                      subtitle: Text(data['content'] ?? ''),
                      trailing: Text(DateFormat('yyyy-MM-dd HH:mm')
                          .format((data['timestamp'] as Timestamp).toDate())),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomSheet: Container(
        padding: EdgeInsets.only(
            left: 8,
            right: 8,
            bottom: MediaQuery.of(context).viewInsets.bottom),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              offset: Offset(0, -3),
              blurRadius: 6,
              color: Colors.black12,
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _commentController,
                focusNode: _focusNode,
                decoration: InputDecoration(
                  hintText: '댓글을 입력하세요',
                  border: InputBorder.none,
                ),
              ),
            ),
            IconButton(
              icon: Icon(Icons.send),
              onPressed: _addComment,
            ),
          ],
        ),
      ),
    );
  }
}
// 커뮤니티 페이지

class MyPageScreen extends StatelessWidget {
  final Map<String, dynamic> userData;

  MyPageScreen({required this.userData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("My Page"),
      ),
      body: Center(
          child: Text(
              "내 정보 페이지\n사용자: ${userData['name']}\n활동 레벨: ${userData['activityLevel']}\n목표: ${userData['goal']}")),
    );
  }
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async'; // 이 import 추가
import 'package:intl/intl.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  print('Firebase 초기화 성공!');
  // Firestore 데이터 업데이트 호출
  await getDocumentId(); // 함수 호출
  // Firestore 데이터 테스트 호출
  runApp(const MyApp());
}

Future<void> getDocumentId() async {
  final querySnapshot =
      await FirebaseFirestore.instance.collection('users').get();
  for (var doc in querySnapshot.docs) {
    print('문서 ID: ${doc.id}');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Welcome Screen',
      theme: ThemeData(
        primarySwatch: MaterialColor(
          0xFFC21B26, // 메인 색상
          const <int, Color>{
            50: Color(0xFFFFEBEE),
            100: Color(0xFFFFCDD2),
            200: Color(0xFFEF9A9A),
            300: Color(0xFFE57373),
            400: Color(0xFFEF5350),
            500: Color(0xFFC21B26),
            600: Color(0xFFE53935),
            700: Color(0xFFD32F2F),
            800: Color(0xFFC62828),
            900: Color(0xFFB71C1C),
          },
        ),
        scaffoldBackgroundColor: Colors.white, // 배경색을 흰색으로 설정
        appBarTheme: AppBarTheme(
          backgroundColor: const Color.fromARGB(255, 241, 100, 90)
              .withOpacity(0.3), // 연한 빨강색으로 설정
        ),
      ),
      home: const WelcomeScreen(),
    );
  }
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/appstartpage.png', // 이미지 경로
              fit: BoxFit.cover,
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 250.0),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const QRViewExample()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: Colors.black, width: 2),
                  ),
                ),
                child: const Text(
                  '인증하기',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class QRViewExample extends StatefulWidget {
  const QRViewExample({super.key});

  @override
  _QRViewExampleState createState() => _QRViewExampleState();
}

class _QRViewExampleState extends State<QRViewExample> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;

  bool isSimulator = (const bool.fromEnvironment('dart.vm.product') ==
      false); // Simulated environment
  final TextEditingController qrInputController = TextEditingController();

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller?.pauseCamera();
    } else if (Platform.isIOS) {
      controller?.resumeCamera();
    }
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      final String scannedData = scanData.code ?? "";
      if (scannedData == "여 제2기숙사") {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => const RegisterPage()), // 회원가입 화면으로 이동
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('인증되지 않은 QR 코드입니다.')),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isSimulator) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('QR 코드 입력'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: qrInputController,
                decoration: const InputDecoration(
                  labelText: 'QR 코드 입력',
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (qrInputController.text.trim() == "여 제2기숙사") {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              const RegisterPage()), // 회원가입 화면으로 이동
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('인증되지 않은 QR 코드입니다.')),
                    );
                  }
                },
                child: const Text('인증하기'),
              ),
            ],
          ),
        ),
      );
    }

    // 실제 QR 스캐너 UI
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Code Scanner'),
      ),
      body: QRView(
        key: qrKey,
        onQRViewCreated: _onQRViewCreated,
      ),
    );
  }

  @override
  void dispose() {
    controller?.dispose();
    qrInputController.dispose();
    super.dispose();
  }
}

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController nicknameController = TextEditingController();
  final TextEditingController roomNumberController = TextEditingController();

  /// Firestore에서 닉네임과 방번호를 검증하는 함수
  Future<bool> verifyUser(String nickname, String roomNumber) async {
    try {
      // Firestore에서 지정된 문서 읽기
      final docSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc('iyXGKYZkEeUxSsayjwCn') // Document ID
          .get();

      if (docSnapshot.exists) {
        final data = docSnapshot.data();
        final user1 = data?['user1'];
        final user2 = data?['user2'];

        // 입력된 닉네임과 방번호가 user1 또는 user2와 일치하는지 확인
        if ((user1['nickName'] == nickname &&
                user1['roomNumber'] == roomNumber) ||
            (user2['nickName'] == nickname &&
                user2['roomNumber'] == roomNumber)) {
          return true;
        }
      }
    } catch (e) {
      print('Firestore 오류: $e');
    }
    return false; // 인증 실패
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('회원가입')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '회원가입',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: nicknameController,
              decoration: const InputDecoration(labelText: '닉네임'),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: roomNumberController,
              decoration: const InputDecoration(labelText: '방번호'),
            ),
            const SizedBox(height: 40),
            Center(
              child: ElevatedButton(
                onPressed: () async {
                  final nickname = nicknameController.text.trim();
                  final roomNumber = roomNumberController.text.trim();

                  // Firestore 데이터와 검증
                  final isVerified = await verifyUser(nickname, roomNumber);

                  if (isVerified) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('회원가입 성공!')),
                    );
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const MainPage()),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('닉네임 또는 방번호가 올바르지 않습니다.')),
                    );
                  }
                },
                child: const Text('인증하기'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    MarketPage(),
    TipsPage(),
    ChatListPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _selectedIndex == 0
              ? '중고거래 게판'
              : _selectedIndex == 1
                  ? '팁 게시판'
                  : '채팅', // 채팅 페이지 제목
        ),
      ),
      body: _pages[_selectedIndex], // 선택된 페이지 렌더링
      floatingActionButton: (_selectedIndex != 2 && currentUserId == 'ADMIN_ID')
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WritePostPage(
                      isTipsPage: _selectedIndex == 1, // 팁 게시판 여부 전달
                    ),
                  ),
                );
              },
              child: const Icon(Icons.add), // 글쓰기 버튼
            )
          : null, // 채팅 페이지에서는 글쓰기 버튼 없음
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Divider(
            height: 1,
            thickness: 1,
            color: Color(0x19000000), // 연한 검은색의 분리선
          ),
          BottomNavigationBar(
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.shopping_cart),
                label: '중고거래',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.lightbulb),
                label: '팁 게시판',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.chat), // 채팅 아이콘
                label: '채팅',
              ),
            ],
            currentIndex: _selectedIndex,
            selectedItemColor: Color.fromARGB(255, 241, 100, 90), // 선택된 색상
            unselectedItemColor: Colors.black, // 선택되지 않은 색상
            backgroundColor: Colors.white, // 하단바 배경색을 흰색으로 설정
            onTap: _onItemTapped,
          ),
        ],
      ),
    );
  }
}

// 중고거래 게시판
class MarketPage extends StatelessWidget {
  const MarketPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('market')
            .orderBy('timestamp', descending: true)
            .limit(5)
            .snapshots(),
        builder: (context, snapshot) {
          // 로딩 상태
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // 데이터가 없을 때
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('게시글이 없습니다.'));
          }
          final items = snapshot.data!.docs;

          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final currentUserId = FirebaseAuth.instance.currentUser!.uid;
              final authorId = item['authorId'];

              return Column(
                children: [
                  ListTile(
                    // ListTile만 사용
                    title: Text(item['title']),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DetailPage(
                            isTipsPage: false,
                            docId: item.id,
                            title: item['title'],
                            content: item['content'],
                            isPinned: item['isPinned'] ?? false,
                            authorId: authorId,
                          ),
                        ),
                      );
                    },
                  ),
                  const Divider(), // 항목 사이에 분리선 추가
                ],
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // 글기 페이지로 이동
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const WritePostPage(isTipsPage: false),
            ),
          );
        },
        child: const Icon(Icons.edit), // 연필 모양 아이콘
      ),
    );
  }
}

// 팁 게시판
class TipsPage extends StatelessWidget {
  const TipsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('tips')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('오류 발생!'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('게시글이 없습니다.'));
          }
          /*
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }*/
          final items = snapshot.data!.docs;

          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final currentUserId = FirebaseAuth.instance.currentUser!.uid;
              final bool isPinned = item['isPinned'] ?? false;

              return Column(
                children: [
                  ListTile(
                    // ListTile만 사용
                    title: Row(
                      children: [
                        if (isPinned) // 고정글이면 이모지 추가
                          const Text(
                            '📌',
                            style: TextStyle(
                                color: Colors.red,
                                fontSize: 16,
                                fontWeight: FontWeight.bold),
                          ),
                        const SizedBox(width: 5), // 간격 추가
                        Text(item['title']),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DetailPage(
                            isTipsPage: true,
                            docId: item.id,
                            title: item['title'],
                            content: item['content'],
                            isPinned: item['isPinned'],
                            authorId: item['authorId'],
                          ),
                        ),
                      );
                    },
                  ),
                  const Divider(), // 항목 사이에 분리선 추가
                ],
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // 글쓰기 페이지로 이동
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const WritePostPage(isTipsPage: true),
            ),
          );
        },
        child: const Icon(Icons.edit), // 연필 모양 아이콘
      ),
    );
  }
}

// 게시글 상세 페이지
class DetailPage extends StatelessWidget {
  final bool isTipsPage;
  final String docId;
  final String title;
  final String content;
  final bool isPinned;
  final String authorId;

  const DetailPage({
    required this.isTipsPage,
    required this.docId,
    required this.title,
    required this.content,
    required this.isPinned,
    required this.authorId,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: SingleChildScrollView(
        // Scrollable 위젯으로 변경
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isPinned)
              const Text(
                '📌 고정글',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.red),
              ),
            const SizedBox(height: 8),
            Text(
              content,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            if (currentUserId == authorId)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditPostPage(
                            isTipsPage: isTipsPage,
                            docId: docId,
                            currentTitle: title,
                            currentContent: content,
                          ),
                        ),
                      );
                    },
                    child: const Text("수정"),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () async {
                      await FirebaseFirestore.instance
                          .collection(isTipsPage ? 'tips' : 'market')
                          .doc(docId)
                          .delete();
                      Navigator.pop(context);
                    },
                    child: const Text("삭제"),
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  ),
                ],
              ),

            const SizedBox(height: 20),
            // 중고거래 게시판에서만 채팅 버튼 표시
            if (!isTipsPage &&
                currentUserId != null &&
                currentUserId != authorId)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton.icon(
                  onPressed: () async {
                    // 두 사용자 ID를 정렬하여 일관된 채팅방 ID 생성
                    List<String> userIds = [currentUserId, authorId];
                    userIds.sort();
                    final chatId = '${userIds.join('_')}_$docId';

                    try {
                      // 채팅방 생성 또는 업데이트
                      await FirebaseFirestore.instance
                          .collection('chats')
                          .doc(chatId)
                          .set({
                        'userIds': userIds,
                        'lastMessage': '',
                        'timestamp': FieldValue.serverTimestamp(),
                        'postId': docId,
                        'postTitle': title,
                        'postType': 'market',
                      }, SetOptions(merge: true));

                      if (context.mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatPage(
                              chatId: chatId,
                              currentUserId: currentUserId,
                              otherUserId: authorId,
                              postTitle: title,
                            ),
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('채팅방 생성 실패: $e')),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.chat),
                  label: const Text('채팅하기'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// 채팅 목록 페이지
class ChatListPage extends StatelessWidget {
  const ChatListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    if (currentUserId == null) {
      return const Center(child: Text('로그인이 필요합니다.'));
    }

    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chats')
            .where('userIds', arrayContains: currentUserId)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('오류 발생: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final chats = snapshot.data!.docs;

          if (chats.isEmpty) {
            return const Center(child: Text('진행 중인 채팅이 없습니다.'));
          }

          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index].data() as Map<String, dynamic>;
              final otherUserId = (chat['userIds'] as List)
                  .firstWhere((id) => id != currentUserId);
              final postTitle = chat['postTitle'] ?? '제목 없음';
              final lastMessage = chat['lastMessage'] ?? '';
              final timestamp = chat['timestamp'] as Timestamp?;
              final formattedTime =
                  timestamp != null ? _formatTimestamp(timestamp) : '';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatPage(
                          chatId: chats[index].id,
                          currentUserId: currentUserId,
                          otherUserId: otherUserId,
                          postTitle: postTitle,
                        ),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                postTitle,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              formattedTime,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                lastMessage.isEmpty
                                    ? '대화를 시작해보세요!'
                                    : lastMessage,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '상대방: $otherUserId',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            Icon(
                              Icons.chevron_right,
                              color: Colors.grey[400],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatTimestamp(Timestamp timestamp) {
    final now = DateTime.now();
    final messageTime = timestamp.toDate();
    final difference = now.difference(messageTime);

    if (difference.inMinutes < 1) {
      return '방금 전';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}분 전';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}시간 전';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}일 전';
    } else {
      return '${messageTime.month}월 ${messageTime.day}일';
    }
  }
}

// 글 작성 페이지
class WritePostPage extends StatefulWidget {
  final bool isTipsPage;

  const WritePostPage({required this.isTipsPage, super.key});

  @override
  State<WritePostPage> createState() => _WritePostPageState();
}

class _WritePostPageState extends State<WritePostPage> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController contentController = TextEditingController();
  bool isPinned = false;
  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isTipsPage ? '팁 작성' : '중고거래 글쓰기'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: '제목'),
            ),
            TextField(
              controller: contentController,
              decoration: const InputDecoration(labelText: '내용'),
              maxLines: 5,
            ),
            if (currentUserId == 'ADMIN_ID') // 관리자만 고정글 설정 가능
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('고정글로 설정'),
                  Switch(
                    value: isPinned,
                    onChanged: (value) {
                      setState(() {
                        isPinned = value;
                      });
                    },
                  ),
                ],
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green, // 버튼 배경색
                foregroundColor: Colors.white, // 버튼 텍스트 색
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection(widget.isTipsPage ? 'tips' : 'market')
                    .add({
                  'title': titleController.text,
                  'content': contentController.text,
                  'isPinned': isPinned,
                  'timestamp': FieldValue.serverTimestamp(),
                  'authorId': currentUserId,
                });
                Navigator.pop(context);
              },
              child: const Text('게시하기'),
            ),
          ],
        ),
      ),
    );
  }
}

// 글 수정 페이지
class EditPostPage extends StatelessWidget {
  final bool isTipsPage;
  final String docId;
  final String currentTitle;
  final String currentContent;

  const EditPostPage({
    super.key,
    required this.isTipsPage,
    required this.docId,
    required this.currentTitle,
    required this.currentContent,
  });

  @override
  Widget build(BuildContext context) {
    final titleController = TextEditingController(text: currentTitle);
    final contentController = TextEditingController(text: currentContent);

    return Scaffold(
      appBar: AppBar(title: const Text('글 수정')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: '제목'),
            ),
            TextField(
              controller: contentController,
              decoration: const InputDecoration(labelText: '내용'),
              maxLines: 5,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection(isTipsPage ? 'tips' : 'market')
                    .doc(docId)
                    .update({
                  'title': titleController.text,
                  'content': contentController.text,
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('글이 수정되었습니다!')),
                );

                Navigator.pop(context);
              },
              child: const Text('수정 완료'),
            ),
          ],
        ),
      ),
    );
  }
}

// 채팅하는 화면
class ChatPage extends StatefulWidget {
  final String chatId;
  final String currentUserId;
  final String otherUserId;
  final String postTitle;

  const ChatPage({
    super.key,
    required this.chatId,
    required this.currentUserId,
    required this.otherUserId,
    required this.postTitle,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.postTitle),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(widget.chatId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  print('Error: ${snapshot.error}');
                  return Center(child: Text('오류가 발생했습니다: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data?.docs ?? [];

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message =
                        messages[index].data() as Map<String, dynamic>;
                    final isMe = message['senderId'] == widget.currentUserId;
                    final messageText = message['content'] as String? ?? '';
                    final timestamp = message['timestamp'] as Timestamp?;
                    final time = timestamp != null
                        ? DateFormat('HH:mm').format(timestamp.toDate())
                        : '';

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8.0,
                        vertical: 4.0,
                      ),
                      child: Row(
                        mainAxisAlignment: isMe
                            ? MainAxisAlignment.end
                            : MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (!isMe) ...[
                            const CircleAvatar(
                              radius: 16,
                              child: Icon(Icons.person, size: 20),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Column(
                            crossAxisAlignment: isMe
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
                            children: [
                              Container(
                                constraints: BoxConstraints(
                                  maxWidth:
                                      MediaQuery.of(context).size.width * 0.7,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: isMe
                                      ? Colors.blue[100]
                                      : Colors.grey[300],
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(messageText),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                time,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 3,
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: '메시지를 입력하세요',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                  color: Theme.of(context).primaryColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty) return;

    try {
      // 메시지 전송 전에 컨트롤러 초기화 (더 빠른 UI 응답)
      _messageController.clear();

      final chatRef =
          FirebaseFirestore.instance.collection('chats').doc(widget.chatId);

      // 트랜잭션으로 메시지 전송과 채팅방 업데이트를 동시에 처리
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        // 메시지 추가
        final messageRef = chatRef.collection('messages').doc();
        transaction.set(messageRef, {
          'content': messageText,
          'senderId': widget.currentUserId,
          'timestamp': FieldValue.serverTimestamp(),
        });

        // 채팅방 정보 업데이트
        transaction.update(chatRef, {
          'lastMessage': messageText,
          'timestamp': FieldValue.serverTimestamp(),
        });
      });

      print('메시지 전송 성공: $messageText'); // 디버깅용
    } catch (e) {
      print('메시지 전송 실패: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('메시지 전송 실패: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

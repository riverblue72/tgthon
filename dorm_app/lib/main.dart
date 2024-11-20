import 'dart:io';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
      if (scannedData == "AUTHORIZED_QR_CODE") {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MainPage()),
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
    bool isSimulator = true;
    if (isSimulator) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('QR Code Scanner (시뮬레이터 모드)'),
        ),
        body: Center(
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => RegisterPage()),
              );
            },
            child: const Text('회원가입으로 이동'),
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
        title: Text(_selectedIndex == 0 ? '중고거래 게시판' : '팁 게시판'),
      ),
      body: _pages[_selectedIndex],
      floatingActionButton: currentUserId == 'ADMIN_ID'
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WritePostPage(
                      isTipsPage: _selectedIndex == 1,
                    ),
                  ),
                );
              },
              child: const Icon(Icons.add),
            )
          : null,
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
          // 글쓰기 페이지로 이동
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
            if (!isTipsPage)
              ElevatedButton.icon(
                onPressed: () async {
                  final chatId =
                      _generateChatId(docId, currentUserId!, authorId);

                  // Firestore에 채팅방 생성 (이미 존재하면 덮어쓰기 없음)
                  await FirebaseFirestore.instance
                      .collection('chats')
                      .doc(chatId)
                      .set({
                    'postId': docId,
                    'userIds': [currentUserId, authorId],
                    'lastMessage': '',
                    'timestamp': FieldValue.serverTimestamp(),
                  });

                  // 채팅 페이지로 이동
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatPage(
                        chatId: chatId,
                        currentUserId: currentUserId,
                        otherUserId: authorId,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.chat),
                label: const Text("채팅하기"),
              ),
          ],
        ),
      ),
    );
  }

  // 고유 chatId 생성
  String _generateChatId(String docId, String userId1, String userId2) {
    final ids = [docId, userId1, userId2];
    ids.sort();
    return ids.join('_');
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

class ChatPage extends StatefulWidget {
  final String chatId;
  final String currentUserId;
  final String otherUserId;

  const ChatPage({
    super.key,
    required this.chatId,
    required this.currentUserId,
    required this.otherUserId,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('채팅 - ${widget.otherUserId}'),
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
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('메시지가 없습니다.'));
                }

                final messages = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMine = message['senderId'] == widget.currentUserId;

                    return Align(
                      alignment:
                          isMine ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                            vertical: 4, horizontal: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color:
                              isMine ? Colors.blueAccent : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          message['content'],
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: '메시지를 입력하세요',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final message = {
      'senderId': widget.currentUserId,
      'content': _messageController.text.trim(),
      'timestamp': FieldValue.serverTimestamp(),
    };

    await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .add(message);

    // 채팅방 메타데이터 업데이트
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .update({
      'lastMessage': message['content'],
      'timestamp': FieldValue.serverTimestamp(),
    });

    _messageController.clear();
  }
}

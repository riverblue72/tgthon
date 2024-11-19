import 'dart:io';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Authentication 초기화 및 디버깅
  if (FirebaseAuth.instance.currentUser == null) {
    await FirebaseAuth.instance.signInAnonymously();
    print("익명 로그인 성공: ${FirebaseAuth.instance.currentUser!.uid}");
  } else {
    print("이미 로그인된 사용자: ${FirebaseAuth.instance.currentUser!.uid}");
  }
  runApp(const MyApp());
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
                MaterialPageRoute(builder: (context) => MainPage()),
              );
            },
            child: const Text('게시판으로 이동'),
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

// 메인 게시판 화면
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
    print("현재 사용자 UID: $currentUserId");
    print("FloatingActionButton 조건: ${currentUserId == 'ADMIN_ID'}");

    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedIndex == 0 ? '중고거래 게시판' : '팁 게시판'),
      ),
      body: _pages[_selectedIndex],
      floatingActionButton: FirebaseAuth.instance.currentUser!.uid == 'ADMIN_ID'
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
      bottomNavigationBar: BottomNavigationBar(
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
        selectedItemColor: Colors.blue,
        onTap: _onItemTapped,
      ),
    );
  }
}

// 중고거래 게시판
class MarketPage extends StatelessWidget {
  const MarketPage({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('market')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
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
    );
  }
}

// 팁 게시판
class TipsPage extends StatelessWidget {
  const TipsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('tips')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
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
    print("현재 사용자 UID: $currentUserId");
    print("글 작성자 UID: $authorId");
    print("수정/삭제 버튼 조건: ${currentUserId == authorId}");

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Padding(
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
            const Spacer(),
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
          ],
        ),
      ),
    );
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

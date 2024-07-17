import 'dart:async';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Yakson',
      home: SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(Duration(seconds: 3), () {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => HomePage()));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Image.asset('assets/name.png'),
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _handleSignIn(BuildContext context) async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        print('Google sign in was aborted by the user.');
        return;
      }
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;
      if (user == null) {
        print('Firebase login failed');
        return;
      }
      print('Logged in successfully: ${user.uid}');
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => MainPage()));
    } catch (error) {
      print('Login failed: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                SizedBox(height: 60),
                //Text('손 쉽게 찾는 약 정보', style: TextStyle(fontSize: 27, fontWeight: FontWeight.bold)),
                SizedBox(height: 20),
                Image.asset('assets/name.png', width: 500, height: 300),
                SizedBox(height: 30),
                _buildButtonContainer(_buildOutlinedButton('이메일로 로그인', Colors.orangeAccent)),
                SizedBox(height: 20),
                _buildButtonContainer(_buildGoogleButton(context)),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('회원가입', style: TextStyle(fontSize: 18, color: Colors.grey)),
                    SizedBox(width: 20),
                    Text('아이디 | 비밀번호 찾기', style: TextStyle(fontSize: 18, color: Colors.grey)),
                  ],
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildButtonContainer(Widget button) {
    return Container(width: 250, child: button);
  }

  Widget _buildOutlinedButton(String label, Color borderColor) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: borderColor, width: 2),
        foregroundColor: borderColor,
        backgroundColor: Colors.white,
        padding: EdgeInsets.symmetric(vertical: 15, horizontal : 30),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
      onPressed: () {},
      child: Text(label, style: TextStyle(fontSize: 16)),
    );
  }

  Widget _buildGoogleButton(BuildContext context) {
    return OutlinedButton.icon(
      icon: FaIcon(FontAwesomeIcons.google, color: Colors.blue),
      label: Text('구글 계정으로 로그인'),
      onPressed: () => _handleSignIn(context),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: Colors.blue, width: 2),
        foregroundColor: Colors.black,
        backgroundColor: Colors.white,
        padding: EdgeInsets.symmetric(vertical: 15, horizontal : 30),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
    );
  }
}

class MainPage extends StatefulWidget {
  @override
  _MainPageState createState() => _MainPageState();
}
class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;
  int yellowBoxCheckboxCount = 0;

  List<Widget> _pages = [];

  @override
  void initState() {
    super.initState();
    _pages = [
      CalendarPage(
        yellowBoxCheckboxCount: yellowBoxCheckboxCount,
        updateYellowBoxCheckboxCount: updateYellowBoxCheckboxCount,
      ),
      HomePageContent(),
      CommunityPage(),
      MyPage(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void updateYellowBoxCheckboxCount(int count) {
    setState(() {
      yellowBoxCheckboxCount = count;
      _pages[0] = CalendarPage(
        yellowBoxCheckboxCount: yellowBoxCheckboxCount,
        updateYellowBoxCheckboxCount: updateYellowBoxCheckboxCount,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.forum),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: '',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.amber[800],
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        showSelectedLabels: false,
        showUnselectedLabels: false,
      ),
    );
  }
}

class CalendarPage extends StatefulWidget {
  final int yellowBoxCheckboxCount;
  final Function(int) updateYellowBoxCheckboxCount;

  CalendarPage({this.yellowBoxCheckboxCount = 0, required this.updateYellowBoxCheckboxCount});

  @override
  _CalendarPageState createState() => _CalendarPageState();
}
class _CalendarPageState extends State<CalendarPage> {
  late CalendarFormat _calendarFormat;
  late DateTime _focusedDay;
  DateTime? _selectedDay;
  Map<DateTime, Map<String, String>> _eventData = {};
  Map<String, TextEditingController> _controllers = {
    'yellowBox': TextEditingController(),
    'blueBox': TextEditingController(),
    'greenBox': TextEditingController(),
  };

  @override
  void initState() {
    super.initState();
    _calendarFormat = CalendarFormat.month;
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();
    _initializeEventData(_focusedDay); // Initialize data for current day
  }

  @override
  void dispose() {
    _controllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  // Initialize event data for a given day
  void _initializeEventData(DateTime day) {
    DateTime dateOnly = DateTime(day.year, day.month, day.day);
    _eventData[dateOnly] ??= {
      'yellowBox': '',
      'blueBox': '',
      'greenBox': '',
    };

    // Safely update controllers with the data of the day
    _updateControllers(day);
  }

  void _updateControllers(DateTime day) {
    DateTime dateOnly = DateTime(day.year, day.month, day.day);
    Map<String, String>? dayData = _eventData[dateOnly];
    if (dayData != null) {
      _controllers['yellowBox']?.text = dayData['yellowBox'] ?? '';
      _controllers['blueBox']?.text = dayData['blueBox'] ?? '';
      _controllers['greenBox']?.text = dayData['greenBox'] ?? '';
    }
  }

  Widget _buildDecoratedBox(String key, Color borderColor, String title, [String content = '']) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20),
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: borderColor, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          TextField(
            controller: _controllers[key],
            keyboardType: TextInputType.multiline,
            maxLines: null,
            style: TextStyle(fontSize: 16),
            decoration: InputDecoration(
              hintText: '내용을 입력하세요...',
              border: InputBorder.none,
            ),
            onChanged: (value) {
              DateTime dateOnly = DateTime(_selectedDay!.year, _selectedDay!.month, _selectedDay!.day);
              // Ensure the entry is not null before updating
              if (_eventData[dateOnly] != null) {
                _eventData[dateOnly]![key] = value;
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Opacity(
          opacity: 0.5,
          child: Image.asset('assets/name.png', height: 50),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            TableCalendar(
              firstDay: DateTime.utc(2010, 1, 1),
              lastDay: DateTime.utc(2040, 12, 31),
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                  _initializeEventData(selectedDay);
                });
              },
              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
              },
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
              ),
              headerStyle: HeaderStyle(
                titleCentered: true,
                formatButtonVisible: false,
              ),
            ),


                  _buildDecoratedBox('greenBox', Color(0xFFF2A306), '오늘 먹은 약'),
                ],
              ),
            ),
          //],
        ); //,
      //); //,
    //);
  }
}

class HomePageContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('홈'),
      ),
      body: Center(
        child: Text('홈 페이지 내용'),
      ),
    );
  }
}

class CommunityPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('커뮤니티'),
      ),
      body: Center(
        child: Text('커뮤니티 페이지 내용'),
      ),
    );
  }
}

class MyPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('마이페이지'),
      ),
      body: Center(
        child: Text('마이페이지 내용'),
      ),
    );
  }
}

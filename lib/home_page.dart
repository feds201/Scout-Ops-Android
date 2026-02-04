import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scouting_app/Pit_Checklist/Pit_Checklist.dart';
import 'package:scouting_app/Qualitative/qualitative.dart';
import 'package:scouting_app/about_page.dart';
import 'package:scouting_app/logs.dart';
import 'package:scouting_app/settings_page.dart';
import 'services/Colors.dart';
import 'Experiment/ExpStateManager.dart';
import 'Match_Pages/match_page.dart';
import 'Pit_Recorder/Pit_Recorder.dart';
import 'Plugins/plugins.dart';
import 'References.dart';
import 'components/Animator/GridPainter.dart';
import 'components/Button.dart';
import 'main.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _colorAnimation;

  bool isExperimentBoxOpen = false;
  bool isCardBuilderOpen = false;
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const _HomePageContent(),
    const MatchPage(),
    const LogsPage(),
    const SettingsPage(),
    const AboutPage(),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _colorAnimation = ColorTween(
      begin: Colors.red,
      end: Colors.blue,
    ).animate(_controller);

    _checkExperimentBox();
  }

  Future<void> _checkExperimentBox() async {
    bool isOpen = await isExperimentBoxOpenFunc();
    bool isCardOpen = await isCardBuilderOpenFunc();
    setState(() {
      isExperimentBoxOpen = isOpen;
      isCardBuilderOpen = isCardOpen;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor:
        islightmode() ? lightColors.white : darkColors.goodblack,
      ),
      home: Scaffold(
        body: Stack(
          children: [
            const Positioned.fill(
              child: WaveGrid(),
            ),
            Column(
              children: [
                _buildCustomAppBar(context),
                Expanded(child: _pages[_selectedIndex]),
              ],
            ),
          ],
        ),
        bottomNavigationBar: _buildBottomNavigationBar(),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.sports_score_outlined),
          label: 'Match',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.list_alt_outlined),
          label: 'Logs',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings_outlined),
          label: 'Settings',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.info_outline),
          label: 'About',
        ),
      ],
      currentIndex: _selectedIndex,
      selectedItemColor: Colors.amber[800],
      unselectedItemColor: islightmode() ? Colors.black : Colors.white,
      backgroundColor: islightmode() ? lightColors.white : darkColors.goodblack,
      onTap: _onItemTapped,
      type: BottomNavigationBarType.fixed,
    );
  }

  Future<bool> isExperimentBoxOpenFunc() async {
    final ExpStateManager stateManager = ExpStateManager();
    Map<String, bool> states = await stateManager.loadAllPluginStates([
      'templateStudioEnabled',
      'templateStudioExpanded',
      'cardBuilderEnabled',
      'cardBuilderExpanded'
    ]);
    return states['templateStudioEnabled'] ?? false;
  }

  Future<bool> isCardBuilderOpenFunc() async {
    final ExpStateManager stateManager = ExpStateManager();
    Map<String, bool> states = await stateManager
        .loadAllPluginStates(['cardBuilderEnabled', 'cardBuilderExpanded']);
    return states['cardBuilderEnabled'] ?? false;
  }
}

class _HomePageContent extends StatelessWidget {
  const _HomePageContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.only(left: 30.0),
            child: ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [
                  Colors.redAccent,
                  Colors.blue,
                  Colors.blueAccent,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds),
              child: Text(
                'Scout-Ops',
                style: GoogleFonts.chivoMono(
                  fontSize: 70,
                  fontWeight: FontWeight.w300,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      color: Colors.red.withOpacity(0.3),
                      blurRadius: 15.0,
                      offset: const Offset(5, 5),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.only(left: 30.0),
            child: ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Colors.red, Colors.blue, Colors.lightBlueAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds),
              child: Row(
                children: [
                  Text(
                    'DEVELOPED BY ',
                    style: GoogleFonts.museoModerno(
                      fontSize: 20,
                      fontWeight: FontWeight.w300,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'FEDS201',
                    style: GoogleFonts.museoModerno(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 30),
          // Additional home page content goes here
        ],
      ),
    );
  }
}

Widget _buildCustomAppBar(BuildContext context) {
  return AppBar(
    backgroundColor: Colors.transparent, // show animation behind
    elevation: 0,
    actions: [
      IconButton(
        icon: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Colors.redAccent, Colors.lightBlueAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: const Icon(Icons.attach_file_rounded,
              size: 30, color: Colors.white),
        ),
        onPressed: () {
          Route route =
          MaterialPageRoute(builder: (context) => const InfiniteZoomImage());
          Navigator.push(context, route);
        },
      ),
      IconButton(
        icon: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Colors.red, Colors.lightBlueAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomLeft,
          ).createShader(bounds),
          child: const Icon(Icons.extension, size: 30, color: Colors.white),
        ),
        onPressed: () {
          Route route =
          MaterialPageRoute(builder: (context) => const Plugins(), fullscreenDialog: true);
          Navigator.push(context, route);
        },
      ),
    ],
  );
}

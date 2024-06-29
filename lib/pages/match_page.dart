import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'components/nav.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'match.dart';
import 'dart:developer';

class MatchPage extends StatefulWidget {
  const MatchPage({super.key});

  @override
  MatchPageState createState() => MatchPageState();
}

class MatchPageState extends State<MatchPage> {
  final TextEditingController eventKeyController = TextEditingController();
  final WidgetStatesController buttonState = WidgetStatesController();
  Future<List<dynamic>>? matches;
  bool isLoading = false;
  int _selectedIndex = 0;
  int _selectedMatchType = 0;
  bool iserror = false;

  NavigationRailLabelType labelType = NavigationRailLabelType.all;
  bool showLeading = false;
  bool showTrailing = false;
  double groupAlignment = -1.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const NavBar(),
      appBar: AppBar(
        title: const Text('Match'),
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: 'Refresh',
            onPressed: () {
              clearStorage();
              setState(() {
                eventKeyController.clear();
                isLoading = false;
              });
            },
          ),
        ],
      ),
      body: matchPage(context, _selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Setup',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.schedule),
            label: 'Match',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.red,
        onTap: (int index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }

  matchPage(BuildContext context, int selectedIndex) {
    switch (selectedIndex) {
      case 0:
        return setup(context);
      case 1:
        return matchSelection(context);
    }
  }

  prepopluateData() async {
    try {
      var data = Hive.box("matchData").get("matches", defaultValue: null);
      putStorage(Types.eventFile, data.toString());
      putStorage(Types.eventKey, data[0]['event_key']);
      eventKeyController.text = getStorage(Types.eventKey);
      await writeJson(data);
      setState(() {
        matches = readJson();
        isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) {
        print('Failed to load data');
      }
      setState(() {
        isLoading = true;
        iserror = true;
      });
    }
  }

  List<Widget> modules(BuildContext context) {
    return [
      const SizedBox(height: 10),
      TextField(
        controller: eventKeyController,
        decoration: InputDecoration(
          labelText: 'Match Event Key (e.g. 2023cmptx)',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.black),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.black),
          ),
        ),
      ),
      const SizedBox(height: 10),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isLoading ? Colors.red : Colors.green,
                shape: BoxShape.circle,
              ),
            ),
            ButtonBar(
              alignment: MainAxisAlignment.center,
              children: <Widget>[
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize:
                        Size(MediaQuery.of(context).size.width / 2, 50),
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.blue,
                  ),
                  onPressed: () => getData(eventKeyController.text),
                  child: const Text('Load Event'),
                ),
              ],
            ),
            ButtonBar(
              alignment: MainAxisAlignment.center,
              children: <Widget>[
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(80, 50),
                    foregroundColor: Colors.white,
                    backgroundColor: iserror ? Colors.grey : Colors.red,
                  ),
                  onPressed: prepopluateData,
                  child: const Text('Use Local'),
                ),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      Row(
        children: <Widget>[
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(right: 5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: getStorage(Types.allianceColor) == 'Red'
                      ? Colors.red
                      : Colors.grey,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: const BorderSide(color: Colors.red)),
                ),
                onPressed: () {
                  setState(() {
                    putStorage(Types.allianceColor, 'Red');
                  });
                },
                child: const Text('Red'),
              ),
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(left: 5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: getStorage(Types.allianceColor) == 'Blue'
                      ? Colors.blue
                      : Colors.grey,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: const BorderSide(color: Colors.blue),
                  ),
                ),
                onPressed: () {
                  setState(() {
                    putStorage(Types.allianceColor, 'Blue');
                  });
                },
                child: const Text('Blue'),
              ),
            ),
          ),
        ],
      ),
      if (getStorage(Types.allianceColor) == "Red") ...[
        const SizedBox(height: 10),
        Column(
          children: [
            const SizedBox(height: 10),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        putStorage(Types.selectedStation, 'R1');
                      });
                    },
                    style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor:
                            getStorage(Types.selectedStation) == "R1"
                                ? Colors.red
                                : Colors.grey,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        )),
                    child: const Text('R1'),
                  ),
                  const SizedBox(width: 60),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        putStorage(Types.selectedStation, 'R2');
                      });
                    },
                    style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor:
                            getStorage(Types.selectedStation) == "R2"
                                ? Colors.red
                                : Colors.grey,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        )),
                    child: const Text('R2'),
                  ),
                  const SizedBox(width: 60),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        putStorage(Types.selectedStation, 'R3');
                      });
                    },
                    //change the color when selected

                    style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor:
                            getStorage(Types.selectedStation) == "R3"
                                ? Colors.red
                                : Colors.grey,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        )),
                    child: const Text('R3'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/${getStorage(Types.allianceColor)}Alliance.png',
                    width: MediaQuery.of(context).size.width * 0.90,
                  ),
                ],
              ),
            )
          ],
        ),
      ] else if (getStorage(Types.allianceColor) == "Blue") ...[
        const SizedBox(height: 10),
        Column(
          children: [
            const SizedBox(height: 10),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        putStorage(Types.selectedStation, "B1");
                      });
                    },
                    style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor:
                            getStorage(Types.selectedStation) == "B1"
                                ? Colors.blue
                                : Colors.grey,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        )),
                    child: const Text('B1'),
                  ),
                  const SizedBox(width: 60),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        putStorage(Types.selectedStation, "B2");
                      });
                    },
                    style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor:
                            getStorage(Types.selectedStation) == "B2"
                                ? Colors.blue
                                : Colors.grey,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        )),
                    child: const Text('B2'),
                  ),
                  const SizedBox(width: 60),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        putStorage(Types.selectedStation, "B3");
                      });
                    },
                    style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor:
                            getStorage(Types.selectedStation) == "B3"
                                ? Colors.blue
                                : Colors.grey,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        )),
                    child: const Text('B3'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/${getStorage(Types.allianceColor)}Alliance.png',
                    width: MediaQuery.of(context).size.width * 0.90,
                  ),
                ],
              ),
            )
          ],
        ),
      ]
    ];
  }

  getData(String eventKey) async {
    setState(() {
      isLoading = true;
    });

    var headers = {
      'X-TBA-Auth-Key':
          '2ujRBcLLwzp008e9TxIrLYKG6PCt2maIpmyiWtfWGl2bT6ddpqGLoLM79o56mx3W'
    };
    var response = await http.get(
        Uri.parse(
            'https://www.thebluealliance.com/api/v3/event/$eventKey/matches'),
        headers: headers);

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);

      if (kDebugMode) {
        print(data);
      }

      putStorage(Types.eventFile, data.toString());

      await writeJson(data);

      setState(() {
        matches = readJson();
        isLoading = false;
      });
    } else {
      if (kDebugMode) {
        print('Failed to load data');
      }
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> writeJson(List<dynamic> data) async {
    final path = await _localPath;
    final file = File('$path/data.json');

    return file.writeAsString(jsonEncode(data));
  }

  Future<List<dynamic>> readJson() async {
    try {
      final path = await _localPath;
      final file = File('$path/data.json');
      final contents = await file.readAsString();
      return jsonDecode(contents);
    } catch (e) {
      return [];
    }
  }

  Widget setup(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: modules(context),
        ),
      ),
    );
  }

  Widget matchSelection(BuildContext context) {
    return Row(
      children: <Widget>[
        // Navigation Rail
        NavigationRail(
          selectedIndex: _selectedMatchType,
          onDestinationSelected: (int index) {
            setState(() {
              _selectedMatchType = index;
            });
          },
          labelType: labelType,
          destinations: const [
            NavigationRailDestination(
              icon: Icon(Icons.refresh),
              selectedIcon: Icon(Icons.refresh_rounded),
              label: Text('Quals'),
            ),
            NavigationRailDestination(
              icon: Icon(Icons.add_road),
              selectedIcon: Icon(Icons.add_road_outlined),
              label: Text('Match'),
            ),
            NavigationRailDestination(
              icon: Icon(Icons.emoji_events),
              selectedIcon: Icon(Icons.emoji_events_outlined),
              label: Text('Finals'),
            ),
          ],
        ),
        // Vertical Divider
        const VerticalDivider(thickness: 1, width: 1),
        if (_selectedMatchType == 0) ...[
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: matches,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  var otherMatches = snapshot.data!
                      .where((match) =>
                          !match['comp_level'].startsWith('f') &&
                          !match['comp_level'].startsWith('sf'))
                      .toList()
                    ..sort((a, b) =>
                        a['match_number'].compareTo(b['match_number']));
                  if (otherMatches.isNotEmpty) {
                    return _buildMatchList(otherMatches, Colors.black);
                  } else {
                    return const Text('No Matches');
                  }
                } else {
                  return const CircularProgressIndicator();
                }
              },
            ),
          ),
        ] else if (_selectedMatchType == 1) ...[
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: matches,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  // Filter and sort finals matches
                  var finalsMatches = snapshot.data!
                      // Get 11 from sf11m1
                      .where((match) => match['comp_level'].startsWith('sf'))
                      .toList()
                    ..sort(
                        (a, b) => a['set_number'].compareTo(b['set_number']));
                  return _buildMatchList(finalsMatches, Colors.deepOrange);
                } else {
                  return const CircularProgressIndicator();
                }
              },
            ),
          ),
        ] else if (_selectedMatchType == 2) ...[
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: matches,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  // Filter and sort semifinals matches
                  var semifinalsMatches = snapshot.data!
                      .where((match) => match['comp_level'].startsWith('f'))
                      .toList()
                    ..sort((a, b) =>
                        a['match_number'].compareTo(b['match_number']));
                  return _buildMatchList(semifinalsMatches, Colors.red);
                } else {
                  return const CircularProgressIndicator();
                }
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMatchList(List<dynamic> matches, Color buttonColor) {
    return GridView.builder(
      padding: const EdgeInsets.all(8.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, // Number of columns
        mainAxisSpacing: 8.0,
        crossAxisSpacing: 8.0,
        childAspectRatio: 1.5, // Width is 1.5 times the height
      ),
      itemCount: matches.length,
      itemBuilder: (context, index) {
        var match = matches[index];
        putStorage(Types.matchFile, match);
        return ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: buttonColor,
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const Match(),
              ),
            );
          },
          child: Text(
            match['comp_level'].startsWith('sf')
                ? '${match['set_number']}'
                : '${match['match_number']}',
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        );
      },
    );
  }
}

enum Types {
  eventKey,
  matchKey,
  allianceColor,
  selectedStation,
  eventFile,
  matchFile,
}

putStorage(Types key, dynamic value) {
  var box = Hive.box('matchData');
  box.put((key).toString(), value);
}

getStorage(Types key) {
  var box = Hive.box('matchData');
  return box.get((key).toString());
}

clearStorage() {
  var scoutbox = Hive.box('ScoutData');
  putStorage(Types.eventKey, null);
  putStorage(Types.matchFile, null);
  putStorage(Types.allianceColor, null);
  putStorage(Types.selectedStation, null);
  putStorage(Types.matchKey, null);
  scoutbox.clear();
}

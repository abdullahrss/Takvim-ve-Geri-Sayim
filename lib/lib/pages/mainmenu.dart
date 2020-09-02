import 'dart:async';
import 'package:flutter/material.dart';

import 'package:dynamic_theme/dynamic_theme.dart';

import '../databasehelper/dataBaseHelper.dart';
import '../databasehelper/settingsHelper.dart';
import '../events/addevent.dart';
import '../events/closesEvent.dart';
import '../helpers/backgroundProcesses.dart';
import 'calendar.dart';
import 'countdownpage.dart';
import 'settings.dart';

class MainMenu extends StatelessWidget {
  MainMenu({Key key}) : super(key: key);
  final _sdb = SettingsDbHelper();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _sdb.getSettings(),
      builder: (context, snapshot) {
        if (snapshot.data == null) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              body: Center(
                child: Text("Yükleniyor....."),
              ),
            ),
          );
        } else {
          return DynamicTheme(
              defaultBrightness: Brightness.light,
              data: (brightness) => ThemeData(
                    brightness: brightness,
                    fontFamily: snapshot.data[0].fontName,
                    floatingActionButtonTheme: FloatingActionButtonThemeData(
                      foregroundColor: Colors.green,
                    ),
                  ),
              themedWidgetBuilder: (context, theme) {
                return MaterialApp(
                  debugShowCheckedModeBanner: false,
                  theme: theme,
                  home: MainMenuBody(warning: snapshot.data[0].warning,),
                  // navigatorKey: navigatorKey,
                );
              });
        }
      },
    );
  }
}

class MainMenuBody extends StatefulWidget {

  final int warning;

  const MainMenuBody({Key key, this.warning}) : super(key: key);

  @override
  _MainMenuBodyState createState() => _MainMenuBodyState();
}

class _MainMenuBodyState extends State<MainMenuBody> {
  // Database
  var _db = DbHelper();

  // Background services
  BackGroundProcesses _backGroundProcesses;

  // Locals
  int _selectedIndex = 0;
  static int _selectedOrder = 0;
  int radioValue;

  // Timer
  Timer timer;

  // Navigation
  int bottomSelectedIndex = 0;
  final PageController pageController = PageController(
    initialPage: 0,
    keepPage: true,
  );
  List<Widget> _widgetOptions = <Widget>[
    Soclose(index: _selectedOrder),
    FutureCalendar(),
    CountDownPage(),
  ];

  @override
  void initState() {
    super.initState();
    // Background processes
    _backGroundProcesses = BackGroundProcesses();
    _backGroundProcesses.startBgServicesManually();
    // Active processes
    _db.openNotificationBar();
    timer = Timer.periodic(Duration(minutes: 1), (timer) {
      _db.openNotificationBar();
    });
  }

  @override
  void dispose() {
    pageController.dispose();
    timer.cancel();
    super.dispose();
  }


  Widget buildPageView() {
    return PageView.builder(
      onPageChanged: _pageChange,
      controller: pageController,
      itemCount: 3,
      physics: ScrollPhysics(),
      itemBuilder: (BuildContext context,int itemIndex){
        return _widgetOptions[itemIndex];
      },
      scrollDirection: Axis.horizontal,
    );
  }

  void _pageChange(int index){
    setState(() {
      _selectedIndex = index;
      bottomSelectedIndex = index;
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      pageController.jumpToPage(_selectedIndex);
    });
  }

  void changeRadios(int e) {
    setState(() {
      radioValue = e;
      _selectedOrder = e;
      _widgetOptions[0] = Soclose(index: radioValue,);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: Padding(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 50.0),
        child: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AddEvent(warningstatus: widget.warning,)),
            );
          },
          child: Icon(
            Icons.add,
            color: Colors.blueAccent,
          ),
          backgroundColor: Colors.green,
        ),
      ),
      appBar: AppBar(
        title: Text('Takvim ve Geri Sayım'),
        //centerTitle: true,
        actions: <Widget>[
          if (_selectedIndex == 0)
            Container(
              child: IconButton(
                onPressed: () {
                  showMySortDialog(context);
                },
                icon: Icon(
                  Icons.sort,
                  size: 30,
                  color: Colors.white,
                ),
              ),
            ),
          SizedBox(
            width: 15,
          ),
          IconButton(
              icon: Icon(
                Icons.settings,
                size: 30,
              ),
              onPressed: () async {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => (Settings())),
                );
              })
        ],
      ),
      body: buildPageView(),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.schedule),
            title: Text(
              'Yakındakiler',
              style: TextStyle(fontSize: 18),
            ),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.business),
            title: Text(
              'Takvim',
              style: TextStyle(fontSize: 18),
            ),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.watch),
            title: Text(
              'Geri Sayım',
              style: TextStyle(fontSize: 18),
            ),
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.amber[800],
        onTap: _onItemTapped,
      ),
    );
  }

  Future<void> showMySortDialog(context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Sıralama'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Radio(
                      value: 0,
                      groupValue: radioValue,
                      onChanged: (e) async {
                        changeRadios(e);
                        Navigator.pop(context);
                      },
                    ),
                    Text("A-Z a-z"),
                  ],
                ),
                Row(
                  children: <Widget>[
                    Radio(
                      value: 1,
                      groupValue: radioValue,
                      onChanged: (e) async {
                        changeRadios(e);
                        Navigator.pop(context);
                      },
                    ),
                    Text("Z-A z-a"),
                  ],
                ),
                Row(
                  children: <Widget>[
                    Radio(
                      value: 2,
                      groupValue: radioValue,
                      onChanged: (e) async {
                        changeRadios(e);
                        Navigator.pop(context);
                      },
                    ),
                    Text("Gelecek tarihler başta"),
                  ],
                ),
                Row(
                  children: <Widget>[
                    Radio(
                      value: 3,
                      groupValue: radioValue,
                      onChanged: (e) async {
                        changeRadios(e);
                        Navigator.pop(context);
                      },
                    ),
                    Text("Geçmiş tarihler başta"),
                  ],
                ),
              ],
            ),
          ),
          actions: <Widget>[
            FlatButton(
              child: Text(
                "Geri",
                style: TextStyle(fontSize: 24),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}

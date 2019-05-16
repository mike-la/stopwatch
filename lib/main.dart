import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:ui';
import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:background_fetch/background_fetch.dart';

const StartTime_KEY = "startTime";
const IsRunning_KEY = "isRunning";
const StopTime_KEY = "stopTime";

/// This "Headless Task" is run when app is terminated.
void backgroundFetchHeadlessTask() async {
  print('[BackgroundFetch] Headless event received.');
  SharedPreferences prefs = await SharedPreferences.getInstance();

  int startTime;
  int sT = prefs.getInt(StartTime_KEY);
  if (sT != null) {
    startTime = sT;
  } else {
    startTime = new DateTime.now().millisecondsSinceEpoch;
    startTime = (startTime / 1000).toInt();
  }
  prefs.setInt(StartTime_KEY, startTime);

  int stopTime;
  int stopT = prefs.getInt(StopTime_KEY);
  if (stopT != null) {
    stopTime = stopT;
  } else {
    stopTime = new DateTime.now().millisecondsSinceEpoch;
    stopTime = (stopTime / 1000).toInt();
  }
  prefs.setInt(StopTime_KEY, stopTime);

  bool isRunning;
  bool iR = prefs.getBool(IsRunning_KEY);
  if (iR != null) {
    isRunning = iR;
  } else {
    isRunning = false;
  }
  prefs.setBool(IsRunning_KEY, isRunning);

  BackgroundFetch.finish();
}

void main() {
  // Enable integration testing with the Flutter Driver extension.
  // See https://flutter.io/testing/ for more info.
  runApp(new MyApp());

  // Register to receive BackgroundFetch events after app is terminated.
  // Requires {stopOnTerminate: false, enableHeadless: true}
  BackgroundFetch.registerHeadlessTask(backgroundFetchHeadlessTask);
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: stopwatch(title: 'Stopwatch'),
    );
  }
}

class stopwatch extends StatefulWidget {
  stopwatch({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _stopwatchState createState() => _stopwatchState();
}

class _stopwatchState extends State<stopwatch> {
  int startTime;
  bool isRunning=false;
  int stopTime; //sec, since 1970, when isRunning==false

  int actTimerSeconds;
  String actTimeMinutesSeconds = "";
  Timer _timer;

  String startStopBtnText = "Start";
  ColorSwatch startStopBtnColor = Colors.green;

  String actErrors = ""; //only for debug

  /*_stopwatchState() {
    setActTimeMinutesSeconds(); //for 00:00 at first
  }*/

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  Future<void> initPlatformState() async {
    setActTimeMinutesSeconds(); //for 00:00 at first
    // Load persisted fetch events from SharedPreferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    /*setState(() {
      actErrors += "after prefs \n";
    }); */

    startTime = prefs.getInt(StartTime_KEY);
    stopTime = prefs.getInt(StopTime_KEY);
    /*setState(() {
      actErrors += "startTime: $startTime \n ";
    }); */

    int actTime = new DateTime.now().millisecondsSinceEpoch;
    actTime = (actTime / 1000).toInt();
   /* setState(() {
      actErrors += "actTime $actTime \n ";
    }); */

    if (startTime != null) {

      /*
      setState(() {
        actErrors += "inIF:_ $actTime | $startTime";
      });
      */

      actTimerSeconds = actTime - startTime;
      setState(() {
        setActTimeMinutesSeconds();
      });
      setState(() {
        actErrors += "actTimerSeconds_ $actTimerSeconds \n";
      });
      isRunning = prefs.getBool(IsRunning_KEY);
      if(isRunning){
        if (_timer != null) {
          _timer.cancel(); //stop timer if exist
        }
        startTimer(); //start Timer with actual values
      }
      else{
        actTimerSeconds = actTimerSeconds-(actTime-stopTime); //subtrac the time beetween last stop click and now
      }

    } else {
      startTime = actTime;
      actTimerSeconds = 0;
      isRunning=false; //when no seconds count, the timer cannot be started
    }

    setState(() {
      setActTimeMinutesSeconds();
    });

    setState(() {
      actErrors += "vor Status, startTime: $startTime \n ";
    });
    // Optionally query the current BackgroundFetch status.
    int status = await BackgroundFetch.status;

    // Configure BackgroundFetch.
    BackgroundFetch.configure(
            BackgroundFetchConfig(
                minimumFetchInterval: 15,
                stopOnTerminate: false,
                enableHeadless: true,
                forceReload: false),
            _onBackgroundFetch)
        .then((int status) {
      // Persist fetch events in SharedPreferences
      print('[BackgroundFetch] SUCCESS: $status');
      /*setState(() {
        actErrors += "\n L156, $status";
      }); */
    }).catchError((Exception e) {
      print('[BackgroundFetch] ERROR: $e');
      setState(() {
        actErrors += "\n L162 Error, $e";
      });
    });

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;
  }

  void _onBackgroundFetch() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // This is the fetch-event callback.
    print('[BackgroundFetch] Event received');
    setState(() {
      actErrors += "\n L142";
    });


    prefs.setInt(StartTime_KEY, startTime);
    prefs.setBool(IsRunning_KEY, isRunning);

    // IMPORTANT:  You must signal completion of your fetch task or the OS can punish your app
    // for taking too long in the background.
    BackgroundFetch.finish();
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: AppBar(
        title: Text('Timer'),
      ),
      body: Center(
        child: Container(
          child: Column(
            children: <Widget>[
              SizedBox(
                  width: MediaQuery.of(context).size.width, //screen width
                  height: 100.0,
                  child: RaisedButton(
                    color: startStopBtnColor,
                    onPressed: () {
                      startStopButtonClicked();
                    },
                    child: Text('$startStopBtnText',
                        style: TextStyle(fontSize: 40)),
                  )),
              RaisedButton(
                onPressed: () {resetButtonClicked();},
                child: Text(
                    'reset',
                    style: TextStyle(fontSize: 20)
                ),
              ),
              Container(
                // color: Colors.blue,
                width: MediaQuery.of(context).size.width, //screen width
                height: 200.0,
                child: FittedBox(
                    fit: BoxFit.contain,
                    child: Text(
                      "$actTimeMinutesSeconds",
                      textScaleFactor: 0.8,
                      style: TextStyle(
                          fontSize: 20.0,
                          letterSpacing: 2.0,
                          fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    )),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void startStopButtonClicked() {
    this.setState(() {
      if (!isRunning) {
        start();
        return; //jut to leave this function
      } else {
        stop();
      }
    });
  }

  void stop() async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      actErrors += "stop pressed \n";
    });

    //if(isRunning){
      setState(() {
        startStopBtnText = "Start";
        startStopBtnColor = Colors.green;
      });
      if (_timer != null) {
        _timer.cancel(); //stop timer if exist
      }
   // }
    isRunning=false;
    prefs.setBool(IsRunning_KEY, isRunning);
    int actTime = new DateTime.now().millisecondsSinceEpoch;
    actTime = (actTime / 1000).toInt();
    stopTime=actTime;
    startTime=stopTime-actTimerSeconds;
    prefs.setInt(StopTime_KEY, stopTime);
    prefs.setInt(StartTime_KEY, startTime);

  }

  void start() async {
    setState(() {
      actErrors += "Start pressed \n";
    });

    //if(!isRunning) {
      setState(() {
        startStopBtnText = "Stop";
        startStopBtnColor = Colors.red;
      });
      if(actTimerSeconds==0){
        int actTime = new DateTime.now().millisecondsSinceEpoch;
        actTime = (actTime / 1000).toInt();
        startTime=actTime;
      }
      startTimer(); //start a new timer
   // }
    isRunning=true;
  }


  void resetButtonClicked(){
    showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        // return object of type Dialog
        return AlertDialog(
          title: new Text("Reset Timer"),
          content: new Text("Do you really want to reset the  timer?\n"),
          actions: <Widget>[
            // usually buttons at the bottom of the dialog
            new FlatButton(
              child: new Text("Close"),
              onPressed: () {
                Navigator.of(context).pop(); //just close dialogwindow
              },
            ),
            // usually buttons at the bottom of the dialog
            new FlatButton(
              child: new Text("reset"),
              onPressed: () {
                actTimerSeconds=0;
                setState(() {
                  setActTimeMinutesSeconds(); //so there stand 00:00 when start this page
                });
                stop();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void startTimer() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    prefs.setInt("startTime", startTime);
    prefs.setBool(IsRunning_KEY, true);

    const oneSec = const Duration(seconds: 1);
    _timer = new Timer.periodic(
        oneSec,
        (Timer timer) => setState(() {
              actTimerSeconds++;
              setActTimeMinutesSeconds();
            }));
    /*print(actTimeMinutesSeconds);
      actTimerSeconds++;
      setActTimeMinutesSeconds();
      setState((){
        actTimeMinutesSeconds=setActTimeMinutesSeconds();
      });
      sleep(const Duration(seconds:1));
      startTimer();*/
  }

  void setActTimeMinutesSeconds() {
    if (actTimerSeconds == null) {
      actTimerSeconds = 0;
    }

    int minutes = (actTimerSeconds / 60).toInt();
    String minutesString = setFirst0(minutes);
    String secondsString = setFirst0(actTimerSeconds - (minutes * 60));

    actTimeMinutesSeconds = "$minutesString : $secondsString";
    //return actTimeMinutesSeconds;
  }

  String setFirst0(int number) {
    if (number < 10) {
      return "0$number";
    } else {
      return number.toString();
    }
  }
}

import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:background_fetch/background_fetch.dart';



/// This "Headless Task" is run when app is terminated.
void backgroundFetchHeadlessTask() async {
  print('[BackgroundFetch] Headless event received.');
  SharedPreferences prefs = await SharedPreferences.getInstance();

  int startTime;
  int sT = prefs.getInt('startTime');
  if (sT != null) {
    startTime = sT;
  }
  else{
    startTime=new DateTime.now().millisecond;
  }


  bool isRunning;
  bool iR = prefs.getBool('isRunning');
  if (iR != null) {
    isRunning = iR;
  }
  else{
    isRunning=false;
  }


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

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _stopwatchState createState() => _stopwatchState();
}

class _stopwatchState extends State<stopwatch> {
  int startTime;
  bool isRunning;

  int actTimerSeconds=0;
  String actTimeMinutesSeconds="";
  Timer _timer;

  String startStopBtnText="Start";
  ColorSwatch startStopBtnColor=Colors.green;


  _stopwatchState(){
    setActTimeMinutesSeconds(); //for 00:00 at first


    // Configure BackgroundFetch.
    BackgroundFetch.configure(BackgroundFetchConfig(
        minimumFetchInterval: 15,
        stopOnTerminate: false,
        enableHeadless: true,
        forceReload: false
    ), _onBackgroundFetch).then((int status) {
      print('[BackgroundFetch] SUCCESS: $status');


      actTimerSeconds=startTime=new DateTime.now().millisecond-startTime;

      setState(() {
        setActTimeMinutesSeconds();
      });

    }).catchError((Exception e) {
      print('[BackgroundFetch] ERROR: $e');
    });

  }

  void _onBackgroundFetch() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // This is the fetch-event callback.
    print('[BackgroundFetch] Event received');
    setState(() {

    });

    // Persist fetch events in SharedPreferences
    prefs.setInt("startTime", startTime);
    prefs.setBool("isRunning", isRunning);

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
                child:
                RaisedButton(
                  color: startStopBtnColor,
                  onPressed: () {startStopButtonClicked();},
                  child: Text(
                      '$startStopBtnText',
                      style: TextStyle(fontSize: 40)
                  ),
                )
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
                    style: TextStyle(fontSize: 20.0, letterSpacing: 2.0, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  )
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }

  void startStopButtonClicked(){
    this.setState((){
      if(startStopBtnText=="Start"){
        start();
        return; //jut to leave this function
      }
      else{
        stop();
      }
    });
  }
  void stop(){
    startStopBtnText="Start";
    startStopBtnColor=Colors.green;
    if(_timer !=null){
      _timer.cancel(); //stop timer if exist
    }
  }
  void start() async{
    startStopBtnText="Stop";
    startStopBtnColor=Colors.red;
    startTimer(); //start a new timer
  }

  void startTimer() async{
      const oneSec = const Duration(seconds: 1);
    _timer = new Timer.periodic(
        oneSec,
            (Timer timer) => setState(() {
                actTimerSeconds++;
                setActTimeMinutesSeconds();
          })
    );
      /*print(actTimeMinutesSeconds);
      actTimerSeconds++;
      setActTimeMinutesSeconds();
      setState((){
        actTimeMinutesSeconds=setActTimeMinutesSeconds();
      });
      sleep(const Duration(seconds:1));
      startTimer();*/
  }



  String setActTimeMinutesSeconds(){
    int minutes=(actTimerSeconds/60).toInt();
    String minutesStirng=setFirst0(minutes);
    String secondsString=setFirst0(actTimerSeconds-(minutes*60));

    actTimeMinutesSeconds="$minutesStirng : $secondsString";
    return actTimeMinutesSeconds;
  }
  String setFirst0(int number){
    if(number<10){
      return "0$number";
    }
    else{
      return number.toString();
    }
  }
}


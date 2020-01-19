// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:collection';
import 'package:flutter/painting.dart';
import 'package:vector_math/vector_math.dart' as Vector;
import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter_clock_helper/model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

import 'package:flutter/scheduler.dart' show timeDilation;

enum _Element {
  background,
  text,
}

final _lightTheme = {
  _Element.background: Colors.white,
  _Element.text: Colors.white,
};

final _darkTheme = {
  _Element.background: Colors.black,
  _Element.text: Colors.white,
};

final List<Color> _darkBG = [
  Color(0xff282729),
  Color(0xff2c2c2c),
  Color(0xff0a090a)
];

Map<String, GradientColor> background = new HashMap();

class GradientColor {
  String name;
  bool isLightTheme;
  Color color_1;
  Color color_2;

  GradientColor(
      {this.name,
      this.isLightTheme = true,
      this.color_1 = null,
      this.color_2 = null}) {
    if (color_1 == null) {
      color_1 = Color(0xff831062);
    }

    if (color_2 == null) {
      color_2 = Color(0xff831062);
    }
  }

  List<Color> get colorList {
    List<Color> list = new List();
    list.add(color_1);
    list.add(color_2);
    return list;
  }

}

class DigitalClock extends StatefulWidget {
  DigitalClock(this.model) {
    timeDilation = 1.0;
  }

  final ClockModel model;

  @override
  _DigitalClockState createState() => _DigitalClockState();
}

class _DigitalClockState extends State<DigitalClock>
    with TickerProviderStateMixin {
  DateTime _dateTime = DateTime.now();
  Timer _timer;

  AnimationController animationController;
  List<Offset> animList1 = [];

  @override
  void initState() {
    super.initState();

    animationController =
        AnimationController(vsync: this, duration: Duration(seconds: 2));

    animationController.addListener(() {
      animList1.clear();
      for (int i = -2;
          i <= MediaQuery.of(context).size.width.toInt() + 2;
          i++) {
        animList1.add(new Offset(
            i.toDouble(),
            sin((animationController.value * 360 - i) %
                        360 *
                        Vector.degrees2Radians) *
                    20 +
                MediaQuery.of(context).size.height.toInt() -
                60));

        animList1.add(new Offset(
            i.toDouble() + 50,
            sin((animationController.value * 360 - i) %
                        360 *
                        Vector.degrees2Radians) *
                    20 +
                MediaQuery.of(context).size.height.toInt() -
                80));
      }
    });

    animationController.repeat();

    widget.model.addListener(_updateModel);
    _updateTime();
    _updateModel();
    _initClock();
  }

  void _initClock() {
    background.clear();
    background["cloudy"] = new GradientColor(
        name: "cloudy", color_1: Color(0xff51a4db), color_2: Color(0xff73bae1));
    background["foggy"] = new GradientColor(
        name: "foggy", color_1: Color(0xffbc8db8), color_2: Color(0xff5e5e90));
    background["rainy"] = new GradientColor(
        name: "rainy", color_1: Color(0xff00d1f7), color_2: Color(0xff153e49));
    background["snowy"] = new GradientColor(
        name: "snowy", color_1: Color(0xff777b86), color_2: Color(0xffadb7be));
    background["sunny"] = new GradientColor(
        name: "sunny", color_1: Color(0xfffecb1c), color_2: Color(0xfffb2287));
    background["thunderstorm"] = new GradientColor(
        name: "thunderstorm",
        color_1: Color(0xff4065a4),
        color_2: Color(0xffc8a6a7));
    background["windy"] = new GradientColor(
        name: "windy", color_1: Color(0xff2addf6), color_2: Color(0xff0f80fa));
  }

  @override
  void didUpdateWidget(DigitalClock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.model != oldWidget.model) {
      oldWidget.model.removeListener(_updateModel);
      widget.model.addListener(_updateModel);
    }
  }

  @override
  void dispose() {
    animationController.dispose();
    _timer?.cancel();
    widget.model.removeListener(_updateModel);
    widget.model.dispose();

    super.dispose();
  }

  void _updateModel() {
    setState(() {
      // Cause the clock to rebuild when the model changes.
    });
  }

  void _updateTime() {
    setState(() {
      _dateTime = DateTime.now();
      // Update once per minute. If you want to update every second, use the
      // following code.
      /*_timer = Timer(
        Duration(minutes: 1) -
            Duration(seconds: _dateTime.second) -
            Duration(milliseconds: _dateTime.millisecond),
        _updateTime,
      );*/

      // Update once per second, but make sure to do it at the beginning of each
      // new second, so that the clock is accurate.
      _timer = Timer(
        Duration(seconds: 1) - Duration(milliseconds: _dateTime.millisecond),
        _updateTime,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    // Set landscape orientation
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    final isDayLight = Theme.of(context).brightness == Brightness.light;

    final location = widget.model.location;
    final todayWeather = widget.model.weatherString;
    final temperature = widget.model.temperatureString;

    final colors = isDayLight ? _lightTheme : _darkTheme;

    List<Color> gradientBackground =
        isDayLight ? background[todayWeather].colorList : _darkBG;

    final date = DateFormat('EEEE, MMMM y').format(_dateTime);
    final hour =
        DateFormat(widget.model.is24HourFormat ? 'HH:mm:ss' : 'hh:mm:ss')
            .format(_dateTime);

    final smallTextStyle = TextStyle(
        color: Colors.white,
        fontFamily: 'Montserrat',
        fontSize: 15,
        fontWeight: FontWeight.w500);

    final mediumTextStyle = TextStyle(
        color: Colors.white,
        fontFamily: 'Montserrat',
        fontSize: 25,
        fontWeight: FontWeight.w600);

    final fontSize = MediaQuery.of(context).size.width / 8;

    final largeTextStyle = TextStyle(
      color: colors[_Element.text],
      fontFamily: 'Montserrat',
      fontWeight: FontWeight.bold,
      fontSize: fontSize,
    );

    return Stack(
      children: <Widget>[
        Container(
          padding: EdgeInsets.all(5),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            // Box decoration takes a gradient
            gradient: LinearGradient(
              // Where the linear gradient begins and ends
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: gradientBackground,
            ),
          ),
          child: Column(
            children: <Widget>[
              Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Container(
                      padding: EdgeInsets.all(10),
                      alignment: Alignment.topLeft,
                      child: Image.asset(
                        "assets/images/" + todayWeather + ".png",
                        width: 45,
                        height: 45,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.all(10),
                      alignment: Alignment.topRight,
                      child: Row(children: <Widget>[
                        Image.asset(
                          "assets/images/temperature.png",
                          height: 30,
                          width: 30,
                        ),
                        Text(
                          temperature,
                          style: mediumTextStyle,
                        ),
                      ]),
                    )
                  ]),

              Container(
                  padding: EdgeInsets.all(5),
                  alignment: Alignment.center,
                  child: Column(mainAxisSize: MainAxisSize.max, children: [
                    Text(hour,
                        textAlign: TextAlign.center, style: largeTextStyle),
                    Text(date,
                        textAlign: TextAlign.center, style: smallTextStyle),
                    Container(
                      padding: EdgeInsets.all(2),
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Image.asset(
                              "assets/images/location.png",
                              height: 20,
                              width: 20,
                            ),
                            Text(
                              location,
                              style: smallTextStyle,
                            ),
                          ]),
                    ),

                  ])),
            ],
          ),
        ),
        Positioned.fill(
            child: Container(
                height: 20,
                alignment: Alignment.bottomCenter,
                child: AnimatedBuilder(
                  animation: CurvedAnimation(
                    parent: animationController,
                    curve: Curves.easeInOut,
                  ),
                  builder: (context, child) => new ClipPath(
                    child:
                        //set image as background in waves
                        /*Image.asset(
                          'images/demo5bg.jpg',
                          width: widget.size.width,
                          height: widget.size.height,
                          fit: BoxFit.cover,
                        )*/
                        Container(
                      width: MediaQuery.of(context).size.width,
                      height: MediaQuery.of(context).size.height,
                      color: Colors.white,
                    ),
                    clipper: WaveClipper(animationController.value, animList1),
                  ),
                ))),
      ],
    );
  }
}
class WaveClipper extends CustomClipper<Path> {
  final double animation;

  List<Offset> waveList1 = [];

  WaveClipper(this.animation, this.waveList1);

  @override
  Path getClip(Size size) {
    Path path = new Path();

    path.addPolygon(waveList1, false);

    path.lineTo(size.width, size.height);
    path.lineTo(0.0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(WaveClipper oldClipper) =>
      animation != oldClipper.animation;
}

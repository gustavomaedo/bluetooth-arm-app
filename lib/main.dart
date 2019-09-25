/*
 * AUTHOR     GUSTAVO MAEDO
 * COPYRIGHT  2019 HM
 *
 * MAIN
 */

import 'package:flutter/material.dart';
import 'RobotController.dart';

void main() {
  runApp(Robot());
}

ThemeData appTheme = new ThemeData(
  primarySwatch: Colors.lightBlue,
  brightness: Brightness.dark
);

class Robot extends StatefulWidget {
  @override
  RobotState createState() {
    return new RobotState();
  }
}

class RobotState extends State<Robot> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Yohan",
      home: RobotController(),
      theme: appTheme,
    );
  }
}
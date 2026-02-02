import 'package:flutter/material.dart';
import 'package:scouting_app/components/CheckBox.dart';
import 'package:scouting_app/components/CommentBox.dart';
import 'package:scouting_app/components/CounterShelf.dart';
import 'package:scouting_app/main.dart';

import '../../services/DataBase.dart';

class TeleOperated extends StatefulWidget {
  final MatchRecord matchRecord;
  const TeleOperated({super.key, required this.matchRecord});

  @override
  _TeleOperatedState createState() => _TeleOperatedState();
}

class _TeleOperatedState extends State<TeleOperated> {
  late int coralScoreL1;
  late int coralScoreL2;
  late int coralScoreL3;
  late int coralScoreL4;
  late int algaePickUp;
  late int algaeScoringProcessor;
  late int algaeScoringBarge;
  late bool defense;

  late TeleOpPoints teleOpPoints;

  @override
  void initState() {
    super.initState();
    // log(widget.matchRecord.toString());

    coralScoreL1 = widget.matchRecord.teleOpPoints.CoralScoringLevel1;
    coralScoreL2 = widget.matchRecord.teleOpPoints.CoralScoringLevel2;
    coralScoreL3 = widget.matchRecord.teleOpPoints.CoralScoringLevel3;
    coralScoreL4 = widget.matchRecord.teleOpPoints.CoralScoringLevel4;
    algaeScoringProcessor =
        widget.matchRecord.teleOpPoints.AlgaeScoringProcessor;
    algaeScoringBarge = widget.matchRecord.teleOpPoints.AlgaeScoringBarge;
    defense = widget.matchRecord.teleOpPoints.Defense;
    algaePickUp = widget.matchRecord.teleOpPoints.AlgaePickUp;

    teleOpPoints = TeleOpPoints(
      coralScoreL1,
      coralScoreL2,
      coralScoreL3,
      coralScoreL4,
      algaeScoringBarge,
      algaeScoringProcessor,
      algaePickUp,
      defense,
    );
    // log('TeleOp initialized: $teleOpPoints');
  }

  void UpdateData() {
    teleOpPoints = TeleOpPoints(
      coralScoreL1,
      coralScoreL2,
      coralScoreL3,
      coralScoreL4,
      algaeScoringBarge,
      algaeScoringProcessor,
      algaePickUp,
      defense,
    );
    widget.matchRecord.teleOpPoints.CoralScoringLevel1 = coralScoreL1;
    widget.matchRecord.teleOpPoints.CoralScoringLevel2 = coralScoreL2;
    widget.matchRecord.teleOpPoints.CoralScoringLevel3 = coralScoreL3;
    widget.matchRecord.teleOpPoints.CoralScoringLevel4 = coralScoreL4;
    widget.matchRecord.teleOpPoints.AlgaeScoringProcessor =
        algaeScoringProcessor;
    widget.matchRecord.teleOpPoints.AlgaeScoringBarge = algaeScoringBarge;
    widget.matchRecord.teleOpPoints.AlgaePickUp = algaePickUp;
    widget.matchRecord.teleOpPoints.Defense = defense;

    saveState();
  }

  void saveState() {
    LocalDataBase.putData('TeleOp', teleOpPoints.toJson());

    // log('TeleOp state saved: $teleOpPoints');
  }

  @override
  void dispose() {
    // Make sure data is saved when navigating away
    UpdateData();
    saveState();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // print(LocalDataBase.getData('Settings.apiKey'));
    return SingleChildScrollView(
        child: Column(
      children: [
          Align(
            alignment: Alignment.center,

          ),
         buildCheckBox("Defense", defense, (bool value) {
          setState(() {
            defense = value;
          });
        }),
      ],
    ));
  }
}

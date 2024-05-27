import 'dart:math' as math;
import 'package:carousel_slider/carousel_slider.dart';
import 'package:confetti/confetti.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:mrtdeg/Back%20End/splash.dart';
import 'package:web3dart/json_rpc.dart';
import 'blockchain.dart';
import 'winnerModel.dart';
import 'utils.dart';
import 'package:mrtdeg/UI/Container.dart';


class Winner extends StatefulWidget {
  @override
  _WinnerState createState() => _WinnerState();
}

class _WinnerState extends State<Winner> {
  Blockchain blockchain = Blockchain();
  late ConfettiController _controllerCenter;
  List<WinnerModel> groups = [WinnerModel("Loading", BigInt.zero, "Loading", "", 0.0)];
  bool? valid;
  bool showOverlay = false;
  int touchedIndex = -1;

  @override
  void initState() {
    super.initState();
    _controllerCenter = ConfettiController(duration: const Duration(seconds: 5));
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateGroups());
  }

  Future<void> _updateGroups() async {
    print("Fetching groups...");
    _showLoadingDialog("Getting results...", "");

    Future.delayed(const Duration(milliseconds: 500), () {
      blockchain.queryView("get_results", []).then((value) {
        Navigator.of(context).pop();
        print("Results fetched successfully: $value");
        setState(() {
          groups = [];
          BigInt totalVotes = BigInt.zero;

          // Calculate total votes
          for (int i = 0; i < value[0].length; i++) {
            totalVotes += BigInt.parse(value[1][i].toString());
          }

          // Add groups and calculate percentages
          for (int i = 0; i < value[0].length; i++) {
            String groupAddr = value[0][i].toString();
            BigInt votes = BigInt.parse(value[1][i].toString());
            String groupName = value[2][i].toString();
            String pictureUrl = value[3][i].toString();
            double percentage = (votes / totalVotes * 100).toDouble();

            groups.add(WinnerModel(groupAddr, votes, groupName, pictureUrl, percentage));
          }

          // Sort groups by votes in descending order
          groups.sort((a, b) => b.votes!.compareTo(a.votes!));
          valid = true;
          print("Groups updated and sorted. 'valid' set to true.");
        });
        _controllerCenter.play();
        Future.delayed(const Duration(seconds: 5), () {
          _controllerCenter.stop();
        });
      }).catchError((error) {
        Navigator.of(context).pop();
        print('Error fetching results: $error');
        String errorMessage = (error is RPCError) ? blockchain.translateError(error) : error.toString();
        if (error.toString().contains("invalid")) {
          errorMessage = "Invalid results!";
          setState(() {
            valid = false;
            print("Election results invalid due to tie. 'valid' set to false.");
          });
        }
        _showErrorDialog(errorMessage);
      });
    });
  }

  Future<void> _handleRefresh() async {
    return await Future.delayed(const Duration(seconds: 2));
  }

  @override
  Widget build(BuildContext context) {
    print("Building UI with 'valid' status as: $valid");

    List<Widget> buildValidContent() {
      return [
        Stack(
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _controllerCenter,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: true,
                numberOfParticles: 30,
                maxBlastForce: 20,
                minBlastForce: 10,
                emissionFrequency: 0.06,
                gravity: 0.2,
                particleDrag: 0.05,
                colors: [
                  Colors.green.withOpacity(0.7),
                  Colors.white.withOpacity(0.7),
                  Colors.red.withOpacity(0.7),
                ],
                createParticlePath: (size) {
                  final Path path = Path();
                  double radius = size.width / 5;
                  path.addPolygon([
                    Offset(radius, 0),
                    Offset(1.5 * radius, radius),
                    Offset(1.5 * radius, 2.5 * radius),
                    Offset(0.5 * radius, 2.5 * radius),
                    Offset(0.5 * radius, radius),
                  ], true);
                  return path;
                },
              ),
            ),
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: const Text(
                    " Winner ",
                    style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(height: 10),
                glassmorphicContainer(
                  context: context,
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Container(
                          height: 50,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(100),
                            child: Image.network(groups[0].pictureUrl!, fit: BoxFit.fill),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          alignment: Alignment.centerLeft,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Container(
                                alignment: Alignment.centerLeft,
                                child: Row(
                                  children: [
                                    Text("👑 ", style: TextStyle(fontSize: 25)),
                                    Expanded(
                                      child: Text(
                                        "${groups[0].groupName}",
                                        style: TextStyle(
                                          fontSize: 20,
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                alignment: Alignment.centerLeft,
                                child: Text("${groups[0].votes} votes & ${groups[0].percentage!.toStringAsFixed(0)}%",
                                    style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  height: 100,
                ),
                SizedBox(height: 10),
                Container(
                  alignment: Alignment.centerLeft,
                  child: Center(
                    child: Text(
                      "Ranked List",
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 10),
                ...List<Widget>.generate(groups.length, (index) {
                  return glassmorphicContainer(
                    context: context,
                    child: ListTile(
                      title: Text("${groups[index].groupName}", style: TextStyle(color: Colors.black)),
                      subtitle: Text(' ${groups[index].votes} votes          ${groups[index].percentage!.toStringAsFixed(0)}%'),
                      trailing: Container(
                        height: 60,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(100),
                          child: Image.network(groups[index].pictureUrl!, fit: BoxFit.fill),
                        ),
                      ),
                    ),
                    height: 100,
                  );
                }),
                SizedBox(height: 20),
                Container(
                  alignment: Alignment.centerLeft,
                  child: Center(
                    child: Text(
                      "Statistics",
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 10),
                glassmorphicContainer(
                  context: context,
                  child: CarouselSlider(
                    options: CarouselOptions(
                      height: 350,
                      viewportFraction: 1,
                      enlargeCenterPage: true,
                    ),
                    items: [
                      PieChart(
                        PieChartData(
                          pieTouchData: PieTouchData(
                            touchCallback: (FlTouchEvent event, pieTouchResponse) {
                              setState(() {
                                if (!event.isInterestedForInteractions ||
                                    pieTouchResponse == null ||
                                    pieTouchResponse.touchedSection == null) {
                                  touchedIndex = -1;
                                  return;
                                }
                                touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                              });
                            },
                          ),
                          borderData: FlBorderData(show: false),
                          sectionsSpace: 0,
                          centerSpaceRadius: 0,
                          sections: showingSections(),
                        ),
                      ),
                      BarChart(
                        BarChartData(
                          borderData: FlBorderData(
                            show: true,
                            border: Border.symmetric(
                              horizontal: BorderSide(
                                color: Colors.black,
                              ),
                            ),
                          ),
                          titlesData: FlTitlesData(
                            show: true,
                            leftTitles: AxisTitles(
                              drawBelowEverything: true,
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 30,
                                getTitlesWidget: (value, meta) {
                                  if (value % 1 == 0) {
                                    return Text(
                                      value.toInt().toString(),
                                      textAlign: TextAlign.left,
                                      style: TextStyle(color: Colors.black),
                                    );
                                  } else {
                                    return Container();
                                  }
                                },
                              ),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 36,
                                getTitlesWidget: (value, meta) {
                                  final index = value.toInt();
                                  return Container(
                                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                                    height: 50,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(100),
                                      child: Image.network(
                                        groups[index].pictureUrl!,
                                        fit: BoxFit.fill,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            rightTitles: const AxisTitles(),
                            topTitles: const AxisTitles(),
                          ),
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            getDrawingHorizontalLine: (value) => FlLine(
                              color: Colors.black,
                              strokeWidth: 1,
                            ),
                          ),
                          barGroups: groups.asMap().entries.map((entry) {
                            int index = entry.key;
                            WinnerModel candidate = entry.value;
                            return BarChartGroupData(
                              x: index,
                              barRods: [
                                BarChartRodData(
                                  toY: candidate.votes!.toDouble(),
                                  color: getColor(index),
                                  width: 6,
                                ),
                              ],
                              showingTooltipIndicators: touchedIndex == index ? [0] : [],
                            );
                          }).toList(),
                          barTouchData: BarTouchData(
                            enabled: true,
                            handleBuiltInTouches: false,
                            touchTooltipData: BarTouchTooltipData(
                              getTooltipItem: (
                                  BarChartGroupData group,
                                  int groupIndex,
                                  BarChartRodData rod,
                                  int rodIndex,
                                  ) {
                                return BarTooltipItem(
                                  rod.toY.toStringAsFixed(0) + ' votes',
                                  TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: rod.color,
                                    fontSize: 18,
                                    shadows: const [
                                      Shadow(
                                        color: Colors.black26,
                                        blurRadius: 12,
                                      )
                                    ],
                                  ),
                                );
                              },
                            ),
                            touchCallback: (event, response) {
                              if (event.isInterestedForInteractions &&
                                  response != null &&
                                  response.spot != null) {
                                setState(() {
                                  touchedIndex = response.spot!.touchedBarGroupIndex;
                                });
                              } else {
                                setState(() {
                                  touchedIndex = -1;
                                });
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  height: 400,
                ),
              ],
            ),
          ],
        ),
      ];
    }

    List<Widget> content;
    if (valid == false) {
      content = [
        Stack(
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _controllerCenter,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: true,
                numberOfParticles: 30,
                maxBlastForce: 20,
                minBlastForce: 10,
                emissionFrequency: 0.06,
                gravity: 0.2,
                particleDrag: 0.05,
                colors: [
                  Colors.green.withOpacity(0.7),
                  Colors.white.withOpacity(0.7),
                  Colors.red.withOpacity(0.7),
                ],
                createParticlePath: (size) {
                  final Path path = Path();
                  double radius = size.width / 5;
                  path.addPolygon([
                    Offset(radius, 0),
                    Offset(1.5 * radius, radius),
                    Offset(1.5 * radius, 2.5 * radius),
                    Offset(0.5 * radius, 2.5 * radius),
                    Offset(0.5 * radius, radius),
                  ], true);
                  return path;
                },
              ),
            ),
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 30.0),
                child: Column(
                  children: <Widget>[
                    Text(
                      "Invalid Elections",
                      style: TextStyle(fontSize: 40, color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "Elections are invalid!",
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 50),
                    // Center(
                    //   child: Lottie.asset(
                    //     'assets/invalid_elect.json',
                    //     height: 200,
                    //   ),
                    // ),
                    const SizedBox(height: 100),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Theme.of(context).colorScheme.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30.0),
                              side: BorderSide(
                                color: Theme.of(context).colorScheme.secondary,
                                width: 1.0,
                              ), // Border color and width
                            ),
                          ),
                          onPressed: () {
                            blockchain.logout();
                            setState(() {
                              Navigator.pushAndRemoveUntil(
                                context,
                                SlideRightRoute(page: SplashScreen()),
                                    (Route<dynamic> route) => false,
                              );
                            });
                          },
                          child: const Text("Log Out"),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ];
    } else if (valid == true) {
      content = buildValidContent();
    } else {
      content = [
        Center(
          child: Text(
            "",
            style: TextStyle(
              fontSize: 40,
              color: Theme.of(context).colorScheme.background,
            ),
          ),
        ),
      ];
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60.0),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
            child: AppBar(
              backgroundColor: Colors.transparent,
              title: Text('RESULTS', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
              elevation: 0,
              centerTitle: true,
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/background.png', // Replace with your background image asset
              fit: BoxFit.cover,
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [
                  Colors.white.withOpacity(0.6),
                  Colors.blue.withOpacity(0.6),
                ],
              ),
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LiquidPullToRefresh(
              onRefresh: _handleRefresh,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                child: ListView(
                  children: content,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> showingSections() {
    return groups.asMap().entries.map((entry) {
      int index = entry.key;
      WinnerModel candidate = entry.value;
      final isTouched = index == touchedIndex;
      final fontSize = isTouched ? 20.0 : 16.0;
      final radius = isTouched ? 130.0 : 120.0;
      final widgetSize = isTouched ? 75.0 : 50.0;
      const shadows = [Shadow(color: Colors.black, blurRadius: 2)];

      return PieChartSectionData(
        color: getColor(index),
        value: candidate.percentage,
        title: '${candidate.percentage!.toStringAsFixed(1)}%',
        radius: radius,
        titleStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: const Color(0xffffffff),
          shadows: shadows,
        ),
        titlePositionPercentageOffset: 0.5,
        badgeWidget: _Badge(
          candidate.pictureUrl!,
          size: widgetSize,
          borderColor: Theme.of(context).colorScheme.background,
        ),
        badgePositionPercentageOffset: 1,
      );
    }).toList();
  }

  Color getColor(int index) {
    switch (index % 5) {
      case 0:
        return Colors.cyan;
      case 1:
        return Color(0xFFFFC300);
      case 2:
        return Color(0xFF6E1BFF);
      case 3:
        return Color(0xFF2196F3);
      case 4:
        return Color(0xFFE80054);
      default:
        return Colors.green;
    }
  }

  void _showLoadingDialog(String title, String description) {
    AwesomeDialog(
      context: context,
      customHeader: CircularProgressIndicator(),
      dialogType: DialogType.info,
      headerAnimationLoop: false,
      animType: AnimType.bottomSlide,
      title: title,
      desc: description,
      dismissOnTouchOutside: false,
      dismissOnBackKeyPress: false,
      showCloseIcon: false,
    ).show();
  }

  void _showErrorDialog(String message) {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.error,
      headerAnimationLoop: false,
      animType: AnimType.bottomSlide,
      title: "Error",
      desc: message,
      btnOkOnPress: () {},
      btnOkColor: Theme.of(context).colorScheme.secondary,
    ).show();
  }
}

class _Badge extends StatelessWidget {
  final String imageUrl;
  final double size;
  final Color borderColor;

  const _Badge(
      this.imageUrl, {
        Key? key,
        required this.size,
        required this.borderColor,
      }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: (size / 2),
      backgroundColor: borderColor,
      child: CircleAvatar(
        radius: (size / 2) - 3,
        backgroundImage: NetworkImage(imageUrl),
        backgroundColor: Colors.transparent,
      ),
    );
  }
}

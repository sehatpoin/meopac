
import 'package:flutter/material.dart';
import 'package:flutter_joystick/flutter_joystick.dart';
import 'dart:async';
import 'dart:math';
import 'package:flutter/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
      .then((_) {
    runApp(PacmanApp());
  });
}

class PacmanApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pacman',
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.blue[800],
        scaffoldBackgroundColor: Colors.black,
      ),
      home: StartScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class StartScreen extends StatefulWidget {
  @override
  _StartScreenState createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  final TextEditingController _nameController = TextEditingController();
  bool _showInstructions = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'PACMAN',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.yellow,
                  shadows: [
                  Shadow(
                  blurRadius: 10,
                  color: Colors.yellowAccent,
                  offset: Offset(0, 0),),
                  ],
                ),
              ),
              SizedBox(height: 30),

              if (!_showInstructions)
                Container(
                  width: 250,
                  child: TextField(
                    controller: _nameController,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Player Name',
                      labelStyle: TextStyle(color: Colors.yellow),
                      border: OutlineInputBorder(),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.yellow),
                      ),
                    ),
                  ),
                ),

              SizedBox(height: 20),

              if (!_showInstructions)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.yellow,
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PacmanMaze(
                          playerName: _nameController.text.isEmpty
                              ? 'Player 1'
                              : _nameController.text,
                        ),
                      ),
                    );
                  },
                  child: Text(
                    'START GAME',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

              SizedBox(height: 10),

              TextButton(
                onPressed: () {
                  setState(() => _showInstructions = !_showInstructions);
                },
                child: Text(
                  _showInstructions ? 'BACK' : 'HOW TO PLAY',
                  style: TextStyle(color: Colors.white),
                ),
              ),

              if (_showInstructions)
                Container(
                  width: 300,
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.blue[900],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'HOW TO PLAY',
                        style: TextStyle(
                          color: Colors.yellow,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        '1. Use the joystick to move Pacman\n'
                            '2. Eat all dots to score points\n'
                            '3. Avoid ghosts (red/pink/cyan)\n'
                            '4. Big dots make ghosts vulnerable\n'
                            '5. Set high scores!',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class PacmanMaze extends StatefulWidget {
  final String playerName;

  PacmanMaze({required this.playerName});

  @override
  _PacmanMazeState createState() => _PacmanMazeState();
}

class _PacmanMazeState extends State<PacmanMaze> {
  final int rowCount = 30;
  final int colCount = 28;
  int playerRow = 1;
  int playerCol = 1;
  int prevRow = 1;
  int prevCol = 1;
  int score = 0;
  int lives = 3;
  bool isGameOver = false;
  bool isPaused = false;
  double _mouthAngle = 0.3;
  Timer? _animationTimer;
  Timer? _ghostTimer;
  bool _isInvulnerable = false;
  Timer? _invulnerabilityTimer;

  List<List<int>> initialLayout = [];
  List<List<int>> mazeLayout = [
    [1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1],
    [1,2,2,2,2,2,2,2,2,2,2,2,1,1,2,2,2,2,2,2,2,2,2,2,2,2,2,1],
    [1,2,1,1,1,1,2,1,1,1,1,2,1,1,2,1,1,1,1,2,1,1,1,1,2,1,2,1],
    [1,3,1,0,0,1,2,1,0,0,1,2,1,1,2,1,0,0,1,2,1,0,0,1,2,1,3,1],
    [1,2,1,1,1,1,2,1,1,1,1,2,1,1,2,1,1,1,1,2,1,1,1,1,2,1,2,1],
    [1,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,1],
    [1,2,1,1,1,1,2,1,1,1,1,2,1,1,2,1,1,1,1,2,1,1,1,1,2,1,2,1],
    [1,2,1,0,0,1,2,1,0,0,0,2,0,0,2,0,0,0,1,2,1,0,0,1,2,1,2,1],
    [1,2,1,1,1,1,2,1,1,1,1,1,1,1,1,1,1,1,1,2,1,1,1,1,2,1,2,1],
    [1,2,2,2,2,2,2,2,2,2,2,1,1,1,1,1,2,2,2,2,2,2,2,2,2,2,2,1],
    [1,2,1,1,1,1,2,1,1,1,2,1,1,1,1,1,2,1,1,1,2,1,1,1,1,2,1,1],
    [1,2,1,0,0,0,2,1,2,2,2,2,2,2,2,2,2,0,0,0,2,0,0,1,2,1,0,1],
    [1,2,1,1,1,1,2,1,1,1,2,1,1,1,1,1,2,1,1,1,2,1,1,1,2,1,1,1],
    [1,2,2,2,2,2,2,2,2,2,2,1,1,1,1,1,2,2,2,2,2,2,2,2,2,2,2,1],
    [1,1,1,1,1,1,2,1,1,1,2,1,1,0,0,1,2,1,1,1,2,1,1,1,1,1,1,1],
    [1,3,2,0,2,0,2,1,0,0,2,2,0,2,2,0,2,0,0,1,2,0,2,0,2,2,3,1],
    [1,1,1,1,1,1,2,1,1,1,2,1,1,1,1,1,2,1,1,1,2,1,1,1,1,1,1,1],
    [1,2,2,2,2,2,2,2,2,2,2,1,1,1,1,1,2,2,2,2,2,2,2,2,2,2,2,1],
    [1,2,1,1,1,1,2,1,1,1,2,1,1,1,1,1,2,1,1,1,2,1,1,1,1,2,1,1],
    [1,2,1,0,0,0,2,1,0,0,0,2,0,2,2,0,2,0,0,0,2,0,0,1,2,1,0,1],
    [1,2,1,1,1,1,2,1,1,1,2,1,1,1,1,1,2,1,1,1,2,1,1,1,2,1,1,1],
    [1,2,2,2,2,2,2,2,2,2,2,1,1,1,1,1,2,2,2,2,2,2,2,2,2,2,2,1],
    [1,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,1],
    [1,2,2,2,2,2,2,2,2,2,2,2,1,1,2,2,2,2,2,2,2,2,2,2,2,2,2,1],
    [1,2,1,1,1,1,1,1,1,1,1,2,1,1,2,1,1,1,1,1,1,1,1,1,1,1,2,1],
    [1,3,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,3,1],
    [1,0,1,1,1,0,1,1,1,1,1,1,1,0,1,1,1,1,1,1,0,1,1,1,1,1,0,1],
    [1,2,0,2,0,2,0,1,0,2,0,2,2,0,1,2,0,2,0,2,0,2,0,0,2,2,0,1],
    [1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1],
  ];

  List<Offset> ghostPositions = [
    Offset(1, 13),
    Offset(14, 20),
    Offset(26, 7),
  ];

  List<Offset> ghostDirections = [
    Offset(0, 1),
    Offset(0, -1),
    Offset(1, 0),
  ];

  @override
  void initState() {
    super.initState();
    initialLayout = mazeLayout.map((row) => [...row]).toList();
    _ghostTimer = Timer.periodic(Duration(milliseconds: 400), (timer) {
      if (!isGameOver && !isPaused) moveGhosts();
    });
    _animationTimer = Timer.periodic(Duration(milliseconds: 200), (timer) {
      if (!isPaused) {
        setState(() => _mouthAngle = _mouthAngle == 0.3 ? 0.0 : 0.3);
      }
    });
  }

  @override
  void dispose() {
    _ghostTimer?.cancel();
    _animationTimer?.cancel();
    _invulnerabilityTimer?.cancel();
    super.dispose();
  }

  void moveGhosts() {
    if (!mounted) return;
    setState(() {
      for (int i = 0; i < ghostPositions.length; i++) {
        int currentRow = ghostPositions[i].dy.toInt();
        int currentCol = ghostPositions[i].dx.toInt();

        List<Offset> possibleDirections = [
          Offset(0, -1), // up
          Offset(0, 1),  // down
          Offset(-1, 0), // left
          Offset(1, 0),  // right
        ];

        possibleDirections.removeWhere((dir) =>
        dir.dx == -ghostDirections[i].dx && dir.dy == -ghostDirections[i].dy);

        List<Offset> validMoves = possibleDirections.where((dir) {
          int newRow = currentRow + dir.dy.toInt();
          int newCol = currentCol + dir.dx.toInt();
          return (newRow >= 0 &&
              newRow < mazeLayout.length &&
              newCol >= 0 &&
              newCol < mazeLayout[0].length &&
              mazeLayout[newRow][newCol] != 1);
        }).toList();

        if (validMoves.isEmpty) {
          validMoves = [Offset(-ghostDirections[i].dx, -ghostDirections[i].dy)];
        }

        if (validMoves.isNotEmpty) {
          Offset newDirection;
          if (Random().nextDouble() < 0.3) {
            newDirection = validMoves[Random().nextInt(validMoves.length)];
          } else {
            Offset bestDirection = validMoves[0];
            double minDistance = double.infinity;

            for (var dir in validMoves) {
              int newRow = currentRow + dir.dy.toInt();
              int newCol = currentCol + dir.dx.toInt();
              double distance = sqrt(pow(playerRow - newRow, 2) + pow(playerCol - newCol, 2));

              if (distance < minDistance) {
                minDistance = distance;
                bestDirection = dir;
              }
            }
            newDirection = bestDirection;
          }

          ghostPositions[i] = Offset(
            currentCol.toDouble() + newDirection.dx,
            currentRow.toDouble() + newDirection.dy,
          );
          ghostDirections[i] = newDirection;
        }
      }
      checkCollisions();
    });
  }

  void checkCollisions() {
    if (_isInvulnerable) return;

    for (int i = 0; i < ghostPositions.length; i++) {
      double distance = sqrt(
          pow(ghostPositions[i].dx - playerCol, 2) +
              pow(ghostPositions[i].dy - playerRow, 2)
      );

      if (distance < 0.8) {
        handleGhostCollision();
        break;
      }
    }
  }

  void handleGhostCollision() {
    setState(() {
      lives--;
      _isInvulnerable = true;

      _invulnerabilityTimer?.cancel();
      _invulnerabilityTimer = Timer(Duration(seconds: 3), () {
        setState(() => _isInvulnerable = false);
      });

      if (lives <= 0) {
        isGameOver = true;
        showGameOverDialog();
      } else {
        playerRow = 1;
        playerCol = 1;
        ghostPositions = [
          Offset(1, 13),
          Offset(14, 20),
          Offset(26, 7),
        ];
      }
    });
  }

  void movePlayer(int dRow, int dCol) {
    if (isPaused || isGameOver) return;

    final newRow = playerRow + dRow;
    final newCol = playerCol + dCol;
    if (newRow >= 0 && newRow < mazeLayout.length &&
        newCol >= 0 && newCol < mazeLayout[0].length &&
        mazeLayout[newRow][newCol] != 1) {
      setState(() {
        prevRow = playerRow;
        prevCol = playerCol;
        playerRow = newRow;
        playerCol = newCol;

        if (mazeLayout[playerRow][playerCol] == 2) {
          mazeLayout[playerRow][playerCol] = 0;
          score += 10;
        } else if (mazeLayout[playerRow][playerCol] == 3) {
          mazeLayout[playerRow][playerCol] = 0;
          score += 50;
        }

        checkCollisions();
      });
    }
  }

  void showGameOverDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.black,
        title: Text("Game Over", style: TextStyle(color: Colors.redAccent)),
        content: Text("Score: $score", style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              restartGame();
            },
            child: Text("Restart", style: TextStyle(color: Colors.yellow)),
          ),
        ],
      ),
    );
  }

  void restartGame() {
    setState(() {
      playerRow = 1;
      playerCol = 1;
      prevRow = 1;
      prevCol = 1;
      score = 0;
      lives = 3;
      isGameOver = false;
      isPaused = false;
      _isInvulnerable = false;
      _invulnerabilityTimer?.cancel();
      mazeLayout = initialLayout.map((row) => [...row]).toList();
      ghostPositions = [
        Offset(4, 13),
        Offset(14, 20),
        Offset(26, 7),
      ];
      ghostDirections = [
        Offset(0, 1),
        Offset(0, -1),
        Offset(1, 0),
      ];
    });
  }

  void joystickMove(double x, double y) {
    if (isPaused) return;

    if (x.abs() > y.abs()) {
      if (x > 0.5) movePlayer(0, 1);
      else if (x < -0.5) movePlayer(0, -1);
    } else {
      if (y > 0.5) movePlayer(1, 0);
      else if (y < -0.5) movePlayer(-1, 0);
    }
  }

  Widget buildCell(int row, int col, int value) {
    bool isPacmanVisible = !_isInvulnerable || DateTime.now().millisecond % 200 < 100;

    if (row == playerRow && col == playerCol && isPacmanVisible) {
      return Container(
        color: Colors.black,
        child: Center(
          child: CustomPaint(
            painter: PacmanPainter(
              direction: _getPacmanDirection(),
              mouthAngle: _mouthAngle,
            ),
            size: Size(20, 20),
          ),
        ),
      );
    }

    for (int i = 0; i < ghostPositions.length; i++) {
      if (ghostPositions[i].dy.toInt() == row && ghostPositions[i].dx.toInt() == col) {
        return Container(
          color: Colors.black,
          child: Center(
            child: CustomPaint(
              painter: GhostPainter(
                color: [Colors.red, Colors.pink, Colors.cyan][i],
                direction: ghostDirections[i],
              ),
              size: Size(20, 20),
            ),
          ),
        );
      }
    }

    switch (value) {
    case 1:
    return Container(
    decoration: BoxDecoration(
    color: Colors.blue[900],
    border: Border.all(color: Colors.blueAccent, width: 2),
    boxShadow: [BoxShadow(blurRadius: 2, color: Colors.blue[700]!),
    ],
    ),);
    case 2:
    return Center(
    child: Container(
    width: 4,
    height: 4,
    decoration: BoxDecoration(
    color: Colors.white,
    shape: BoxShape.circle,
    ),
    ),
    );
    case 3:
    return Center(
    child: Container(
    width: 10,
    height: 10,
    decoration: BoxDecoration(
    color: Colors.white,
    shape: BoxShape.circle,
    ),
    ),
    );
    default:
    return Container(color: Colors.black);
    }
  }

  Offset _getPacmanDirection() {
    if (playerCol > prevCol) return Offset(1, 0);  // Right
    if (playerCol < prevCol) return Offset(-1, 0); // Left
    if (playerRow > prevRow) return Offset(0, 1);  // Down
    return Offset(0, -1);                          // Up
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Padding(
                  padding: EdgeInsets.all(8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          '${widget.playerName}',
                          style: TextStyle(color: Colors.white, fontSize: 16,fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        'Score: $score',
                        style: TextStyle(color: Colors.white, fontSize: 16,fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                Wrap(
                  spacing: 4,
                  children: List.generate(3, (index) =>
                      Padding(
                        padding: const EdgeInsets.all(6.0),
                        child: Icon(
                          Icons.favorite,
                          color: index < lives ? Colors.red : Colors.grey[700],
                          size: 20,
                        ),
                      ),
                  ),
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final cellSize = min(
                        constraints.maxWidth / colCount,
                        constraints.maxHeight / rowCount,
                      );
                      return Center(
                        child: Container(
                          width: cellSize * colCount,
                          height: cellSize * rowCount,
                          child: GridView.builder(
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: rowCount * colCount,
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: colCount,
                            ),
                            itemBuilder: (context, index) {
                              final row = index ~/ colCount;
                              final col = index % colCount;
                              final value = row < mazeLayout.length &&
                                  col < mazeLayout[row].length
                                  ? mazeLayout[row][col]
                                  : 0;
                              return buildCell(row, col, value);
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(
                    bottom: 20,
                    left: max(16, MediaQuery.of(context).size.width * 0.1),
                    right: max(16, MediaQuery.of(context).size.width * 0.1),
                  ),
                  child: SizedBox(
                    height: 100,
                    child: Joystick(
                      mode: JoystickMode.all,
                      listener: (details) => joystickMove(details.x, details.y),
                      base: JoystickBase(
                        size: 80,
                        color: Colors.grey.withOpacity(0.5),
                      ),
                      stick: JoystickStick(
                        size: 40,
                      //  color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              top: 28,
              right: 15,
              child: IconButton(
                icon: Icon(isPaused ? Icons.play_arrow : Icons.pause,
                    color: Colors.white),
                onPressed: () => setState(() => isPaused = !isPaused),
              ),
            ),
            Positioned(
              top: 28,
              left: 15,
              child: IconButton(
                icon: Icon(Icons.exit_to_app, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            if (isGameOver)
              Center(
                child: Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("GAME OVER",
                          style: TextStyle(color: Colors.red, fontSize: 24)),
                      SizedBox(height: 10),
                      Text("Score: $score",
                          style: TextStyle(color: Colors.white, fontSize: 20)),
                      SizedBox(height: 20),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.yellow,
                        ),
                        onPressed: restartGame,
                        child: Text("PLAY AGAIN",
                            style: TextStyle(color: Colors.black)),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class PacmanPainter extends CustomPainter {
  final Offset direction;
  final double mouthAngle;

  PacmanPainter({required this.direction, required this.mouthAngle});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.yellow;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    double startAngle = 0.0;
    double sweepAngle = 2 * pi - mouthAngle;

    if (direction.dx > 0) startAngle = 0.3 + mouthAngle / 2;
    else if (direction.dx < 0) startAngle = pi + 0.3 + mouthAngle / 2;
    else if (direction.dy > 0) startAngle = pi / 2 + 0.3 + mouthAngle / 2;
    else startAngle = 3 * pi / 2 + 0.3 + mouthAngle / 2;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      true,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class GhostPainter extends CustomPainter {
  final Color color;
  final Offset direction;

  GhostPainter({required this.color, required this.direction});

  @override
  void paint(Canvas canvas, Size size) {
    final bodyPaint = Paint()..color = color;
    final eyePaint = Paint()..color = Colors.white;
    final pupilPaint = Paint()..color = Colors.blue;

    // Draw ghost body
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(0, 0, size.width, size.height),
        bottomLeft: Radius.circular(10),
        bottomRight: Radius.circular(10),
      ),
      bodyPaint,
    );

    // Draw eyes
    final leftEyeCenter = Offset(size.width * 0.3, size.height * 0.4);
    final rightEyeCenter = Offset(size.width * 0.7, size.height * 0.4);

    canvas.drawCircle(leftEyeCenter, 6, eyePaint);
    canvas.drawCircle(rightEyeCenter, 6, eyePaint);

    // Draw pupils (looking in movement direction)
    canvas.drawCircle(
      Offset(
        leftEyeCenter.dx + direction.dx * 2,
        leftEyeCenter.dy + direction.dy * 2,
      ),
      3,
      pupilPaint,
    );
    canvas.drawCircle(
      Offset(
        rightEyeCenter.dx + direction.dx * 2,
        rightEyeCenter.dy + direction.dy * 2,
      ),
      3,
      pupilPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
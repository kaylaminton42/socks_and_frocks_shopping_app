import 'dart:async';
import 'package:flutter/material.dart';

// Example obstacle model.
class Obstacle {
  double x;        // Horizontal position (1.0 = far right, 0.0 = far left)
  double width;    // Fraction of screen width
  double height;   // Fraction of screen height
  final double y;  // The top position of the obstacle

  Obstacle({
    required this.x,
    required this.width,
    required this.height,
    required this.y,
  });
}

class RunnerGame extends StatefulWidget {
  const RunnerGame({Key? key}) : super(key: key);

  @override
  _RunnerGameState createState() => _RunnerGameState();
}

class _RunnerGameState extends State<RunnerGame> with SingleTickerProviderStateMixin {
  // Define the ground level as a fraction of the screen height.
  final double _groundLevel = 0.8;

  // Robot positioning: _robotY represents the top of the robot.
  double _robotX = 0.2;     
  late double _robotY;     
  double _robotSize = 0.16;  // Fraction of screen height for the robot's height

  // Jump mechanics
  double _velocity = 0.0;   
  double _gravity = 0.001;  
  bool _isGameOver = false;

  // Obstacles
  List<Obstacle> _obstacles = [];

  // Score
  double _score = 0.0;

  // Game loop timer
  Timer? _gameLoop;

  @override
  void initState() {
    super.initState();
    // Position the robot so its bottom aligns with the ground.
    _robotY = _groundLevel - _robotSize;

    // Create a first obstacle for demonstration.
    // Set its y so that its bottom is at the ground:
    double obstacleHeight = 0.075;
    _obstacles = [
      Obstacle(x: 1.0, width: 0.075, height: obstacleHeight, y: _groundLevel - obstacleHeight),
    ];

    // Start the game loop.
    startGame();
  }

  void startGame() {
    _isGameOver = false;
    _score = 0;

    // Clear obstacles and add an initial one with proper y-position.
    _obstacles.clear();
    double obstacleHeight = 0.075;
    _obstacles.add(
      Obstacle(x: 1.0, width: 0.075, height: obstacleHeight, y: _groundLevel - obstacleHeight),
    );

    // Start a periodic timer ~60 times per second.
    _gameLoop = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      updateGame();
    });
  }

  void updateGame() {
    if (_isGameOver) {
      _gameLoop?.cancel();
      return;
    }

    setState(() {
      // Update the robot's position based on velocity & gravity.
      _velocity += _gravity;
      _robotY += _velocity;

      // Keep the robot from falling below ground level (its bottom should not go past _groundLevel).
      if (_robotY > _groundLevel - _robotSize) {
        _robotY = _groundLevel - _robotSize;
        _velocity = 0;
      }

      // Move obstacles to the left.
      for (int i = 0; i < _obstacles.length; i++) {
        _obstacles[i].x -= 0.01;
      }

      // Remove obstacles that move off screen to the left.
      _obstacles.removeWhere((obs) => obs.x + obs.width < 0);

      // Randomly add new obstacles if the last one is far enough left.
      if (_obstacles.isNotEmpty) {
        final lastObs = _obstacles.last;
        if (lastObs.x < 0.2) {
          double obstacleHeight = 0.075;
          _obstacles.add(
            Obstacle(
              x: 1.0,
              width: 0.075,
              height: obstacleHeight,
              y: _groundLevel - obstacleHeight, // Align the bottom of the obstacle with the ground.
            ),
          );
        }
      }

      // Check collisions.
      checkCollision();

      // Update score (distance-based).
      _score += 0.2;
    });
  }

  void checkCollision() {
    // Calculate robot's bounding box.
    double robotLeft = _robotX;
    double robotRight = _robotX + 0.08; // approximate width
    double robotTop = _robotY;
    double robotBottom = _robotY + _robotSize;

    for (final obs in _obstacles) {
      double obsLeft = obs.x;
      double obsRight = obs.x + obs.width;
      double obsTop = obs.y;
      double obsBottom = obs.y + obs.height;

      bool overlapHorizontally = (robotLeft < obsRight) && (robotRight > obsLeft);
      bool overlapVertically = (robotTop < obsBottom) && (robotBottom > obsTop);

      if (overlapHorizontally && overlapVertically) {
        _isGameOver = true;
        break;
      }
    }
  }

  void jump() {
    // Allow jump if the robot is "on the ground."
    if (_robotY >= _groundLevel - _robotSize) {
      _velocity = -0.025;
    }
  }

  void resetGame() {
    setState(() {
      _robotY = _groundLevel - _robotSize;
      _velocity = 0;
      _isGameOver = false;
    });
    startGame();
  }

  @override
  void dispose() {
    _gameLoop?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Runner Game"),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: GestureDetector(
        onTap: () {
          if (!_isGameOver) {
            jump();
          }
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: [
                // Background.
                Container(
                  color: const Color(0xFF0FE3D5), // brand color.
                ),
                // Robot.
                Positioned(
                  left: constraints.maxWidth * _robotX,
                  top: constraints.maxHeight * _robotY,
                  child: SizedBox(
                    width: constraints.maxWidth * 0.22,
                    height: constraints.maxHeight * _robotSize,
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Image.asset(
                        'assets/robot.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                // Obstacles.
                ..._obstacles.map((obs) {
                  return Positioned(
                    left: constraints.maxWidth * obs.x,
                    top: constraints.maxHeight * obs.y,
                    child: Container(
                      width: constraints.maxWidth * obs.width,
                      height: constraints.maxHeight * obs.height,
                      decoration: BoxDecoration(
                        color: const Color(0xFF795CAF), // brand color.
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  );
                }).toList(),
                // Score text.
                Positioned(
                  top: 40,
                  left: 20,
                  child: Text(
                    "Score: ${_score.toInt()}",
                    style: const TextStyle(
                      fontSize: 24,
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // Game Over overlay.
                if (_isGameOver)
                  Center(
                    child: Container(
                      width: 200,
                      height: 150,
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Game Over!",
                            style: TextStyle(
                              fontSize: 24,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: resetGame,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.tertiary,
                              foregroundColor: Colors.black,
                            ),
                            child: const Text("Try Again"),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

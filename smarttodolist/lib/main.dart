import 'package:flutter/material.dart';
import 'todolist.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart To-Do',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.deepPurple),
      home: const StartPage(),
    );
  }
}

class StartPage extends StatefulWidget {
  const StartPage({super.key});

  @override
  State<StartPage> createState() => _StartPageState();
}

class _StartPageState extends State<StartPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _bounce;

  final List<String> miniTasks = [
    "Organize the everyday chaos",
    "Focus on the right things",
    "Achieve goals and finish projects",
    "Try it now, start a mini task!", //
  ];

  List<bool> completed = [false, false, false];

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _bounce = Tween<double>(
      begin: 0,
      end: -15,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    // Animate mini tasks auto-check
    Future.delayed(const Duration(seconds: 1), _animateTasks);
  }

  void _animateTasks() async {
    for (int i = 0; i < completed.length; i++) {
      await Future.delayed(const Duration(milliseconds: 800));
      setState(() {
        completed[i] = true;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6E9C8),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _bounce.value),
                    child: child,
                  );
                },
                child: const Text("🐱", style: TextStyle(fontSize: 100)),
              ),
              const SizedBox(height: 20),
              const Text(
                "Welcome to Smart To-Do!",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.brown,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),

              // Mini To-Do list
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: List.generate(miniTasks.length, (index) {
                    bool isCompleted = index < completed.length
                        ? completed[index]
                        : false;
                    return ListTile(
                      leading: Icon(
                        isCompleted
                            ? Icons.check_circle
                            : Icons.circle_outlined,
                        color: isCompleted ? Colors.green : Colors.grey,
                      ),
                      title: Text(
                        miniTasks[index],
                        style: TextStyle(
                          decoration: isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                          color: Colors.brown,
                        ),
                      ),
                    );
                  }),
                ),
              ),

              const SizedBox(height: 40),

              // Start button
              SizedBox(
                width: 200,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      PageRouteBuilder(
                        transitionDuration: const Duration(milliseconds: 700),
                        pageBuilder: (_, __, ___) => const ToDoPage(),
                        transitionsBuilder: (_, anim, __, child) =>
                            FadeTransition(opacity: anim, child: child),
                      ),
                    );
                  },
                  child: const Text(
                    "Start",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

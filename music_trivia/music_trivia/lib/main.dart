import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import 'package:html_unescape/html_unescape.dart';

// Simple Flutter 
// api - https://opentdb.com/api_config.php

void main() {
  runApp(const MyApp());
}

const gradient = [Color.fromARGB(255, 82, 85, 126),Color.fromARGB(255, 145, 139, 153)];
const textColor = Color.fromARGB(255, 39, 42, 44);
const menuColor = Color.fromARGB(255, 158, 159, 168);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Application Root
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Trivia',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: menuColor),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class QuizPage extends StatefulWidget {
  const QuizPage({super.key, required this.difficulty});

  final String difficulty;

    @override
  // ignore: library_private_types_in_public_api
  _QuizPageState createState() => _QuizPageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String selectedDifficulty = 'easy';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: menuColor.withAlpha(120),
        title: Text(widget.title),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.bottomCenter,
            colors: gradient,
          ),
        ),
        child: Stack(
          children: <Widget>[
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    'Welcome to Flutter music trivia!',
                    style: TextStyle(
                    fontSize: 42,
                    color: textColor,
                    fontWeight: FontWeight.bold
                    ),
                  ),
                ],
              ),
            ),
            Align(
              alignment: const Alignment(0, 0.2),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  DropdownButton<String>(
                    value: selectedDifficulty,
                    items: const <DropdownMenuItem<String>>[
                      DropdownMenuItem<String>(
                        value: 'easy',
                        child: Text('Easy'),
                      ),
                      DropdownMenuItem<String>(
                        value: 'medium',
                        child: Text('Medium'),
                      ),
                      DropdownMenuItem<String>(
                        value: 'hard',
                        child: Text('Hard'),
                      ),
                    ],
                    onChanged: (String? value) {
                      if (value == null) {
                        return;
                      }
                      setState(() {
                        selectedDifficulty = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  FloatingActionButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => QuizPage(
                            difficulty: selectedDifficulty,
                          ),
                        ),
                      );
                    },
                    tooltip: 'Start',
                    child: const Text('Start'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuizPageState extends State<QuizPage> {
  // API
  String get uri =>
      'https://opentdb.com/api.php?amount=50&category=12&difficulty=${widget.difficulty}';
  String question = '';
  String correctAnswer = '';
  String? loadError;

  int playerStreak = 0;

  List<String> incorrectAnswers = [];
  List<Map<String, dynamic>> questions = [];

  final Random random = Random();
  final HtmlUnescape unescape = HtmlUnescape();

  // loading to buffer app load to give API time to fetch data
  bool isLoading = true; 

  Future<void> makeGuess(String guess) async {
    final bool isCorrect = guess == correctAnswer;
    if (isCorrect) {
      // Correct guess, increase streak
      playerStreak++;
    } else {
      // Incorrect guess, reset streak back to zero.
      playerStreak = 0;
    }

    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(isCorrect ? 'Correct!' : 'Incorrect!'),
          content: Text(
            isCorrect
                ? 'You got the answer right! Your win streak has increased.'
                : 'You got the answer wrong! Your win streak has reset to zero.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );

    if (!mounted) {
      return;
    }

    setState(() {
      nextQuestion();
    });
  }

  @override
  void initState() {
    super.initState();
    _loadQuiz();
  }

  Future<void> _loadQuiz() async {
    await Future.delayed(const Duration(seconds: 2));
    try {
      await fetchData(uri);
    } catch (error) {
      loadError = error.toString();
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _retryLoad() async {
    setState(() {
      isLoading = true;
      loadError = null;
      question = '';
      correctAnswer = '';
      incorrectAnswers = [];
      questions = [];
    });
    await _loadQuiz();
  }

  // Grab data from Trivia API
  Future<void> fetchData(String uri) async {
    final response = await http.get(Uri.parse(uri));
    if (response.statusCode != 200) {
      throw Exception('Failed to load data (status ${response.statusCode})');
    }

    final Map<String, dynamic> payload = jsonDecode(response.body) as Map<String, dynamic>;
    final dynamic results = payload['results'];
    if (results is! List) {
      throw Exception('Failed to load data (invalid API format)');
    }

    questions = results.whereType<Map<String, dynamic>>().toList();
    if (questions.isEmpty) {
      throw Exception('No questions were returned by the API');
    }

    nextQuestion();
  }

  void nextQuestion() {
    if (questions.isNotEmpty) {
      int randomIndex = random.nextInt(questions.length);
      final Map<String, dynamic> selected = questions[randomIndex];

      // Get questions & answers from json, convert special chars using htmlunescape package
      question = unescape.convert(selected['question'] as String);
      correctAnswer = unescape.convert(selected['correct_answer'] as String);
      
      incorrectAnswers = List<String>.from(selected['incorrect_answers'] as List)
          .map((answer) => unescape.convert(answer))
          .toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Create a list of all answers for a question
    List<String> allAnswers = List<String>.from(incorrectAnswers);
    if (correctAnswer.isNotEmpty) {
      allAnswers.add(correctAnswer);
      allAnswers.shuffle(random);
    }

    // If API data is being retrieved, show Progress Indicator
    if(isLoading){
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: gradient,
            ),
          ),
          child: const Center(child: CircularProgressIndicator()),
        ),
      );
    }
    if (loadError != null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: menuColor.withAlpha(120),
          title: const Text('Quiz'),
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: gradient,
            ),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Text(
                    'Could not load trivia questions.',
                    style: TextStyle(
                      fontSize: 18,
                      color: textColor,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    loadError!,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _retryLoad,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    else{
      return Scaffold(
        appBar: AppBar(
          backgroundColor: menuColor.withAlpha(120),
          title: const Text('Quiz'),
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: gradient,
            ),
          ),
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    question,
                    style: const TextStyle(
                      fontSize: 20.0,
                      color: textColor,
                      fontWeight: FontWeight.bold
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  // Wrap avoids horizontal overflow for long answer text.
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: allAnswers.map((answer) => ElevatedButton(
                      onPressed: () => makeGuess(answer),
                      child: Text(answer, textAlign: TextAlign.center),
                    )).toList(),
                  ),
                  const SizedBox(height: 16),
                  Text('Current Streak - $playerStreak',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      );
    }
  }
}

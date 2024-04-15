import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import 'package:html_unescape/html_unescape.dart';

// simple flutter app built in order to learn the flutter framework and the dart programming language
// api - https://opentdb.com/api_config.php

void main() {
  // entrypoint for app
  runApp(const MyApp());
}

const gradient = [Color.fromARGB(255, 82, 85, 126),Color.fromARGB(255, 145, 139, 153)];
const textColor = Color.fromARGB(255, 39, 42, 44);
const menuColor = Color.fromARGB(255, 158, 159, 168);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // this widget is the root of your application (main theme, title, etc defined here).
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Trivia',
      theme: ThemeData(
        // application theme
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
  const QuizPage({super.key});

    @override
  // ignore: library_private_types_in_public_api
  _QuizPageState createState() => _QuizPageState();
}

class _MyHomePageState extends State<MyHomePage> {
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
              child: FloatingActionButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const QuizPage()),
                  );
                },
                tooltip: 'Start',
                child: const Text('Start'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class _QuizPageState extends State<QuizPage> {
  // api data & values used
  String uri = 'https://opentdb.com/api.php?amount=50&category=12';
  String question = '';
  String correctAnswer = '';
  int playerStreak = 0;
  List<String> incorrectAnswers = List.empty();
  List<dynamic> questions = [];
  Random random = Random();
  var unescape = HtmlUnescape();

  bool isLoading = true; // loading to buffer app load to give API time to fetch data

  void makeGuess(String guess) {
    if (guess == correctAnswer) {
      // correct guess, increment player count and show dialogue
      playerStreak++;
      // dialogue popup + stylings
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Correct!'),
            content: const Text('You got the answer right! Your win streak has increased.'),
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
    } 
    else {
      // incorrect guess, reset streak back to zero
      playerStreak = 0;
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Incorrect!'),
            content: const Text('You got the answer wrong! Your win steak has reset to zero.'),
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
    }
    // re-builds the page, and gets the next question
    setState(() {
      nextQuestion();
    });
  }

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () async {
      await fetchData(uri);
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    });
  }

  // function to grab data from trivia API
  Future fetchData(uri) async {
    try {
      final response = await http.get(Uri.parse(uri));
      if (response.statusCode == 200) {
        // if the server returns a 200 OK response, parse the JSON.
        questions = jsonDecode(response.body)['results'];
        nextQuestion();
      } else {
        throw Exception('Failed to load data');
      }
    } catch (error) {
      throw Exception('Failed to load data: $error');
    }
  }

  void nextQuestion() {
    if (questions.isNotEmpty) {
      int randomIndex = random.nextInt(questions.length);

      // get questions / answers from json, convert special chars using htmlunescape package
      question = unescape.convert(questions[randomIndex]['question']);
      correctAnswer = unescape.convert(questions[randomIndex]['correct_answer']);
      
      // gets incorrect answers from the questions list, and converts special chars using htmlunescape
      incorrectAnswers = List<String>.from(questions[randomIndex]['incorrect_answers'])
      .map((answer) => unescape.convert(answer))
      .toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    // creates a list of all answers for a question before loading them on the page
    List<String> allAnswers = List<String>.from(incorrectAnswers);
    if (correctAnswer != '') {
      allAnswers.add(correctAnswer);
      allAnswers.shuffle(random);
    }

    // if API data is still being fetched, display a loading circle to visualize program is loading
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
                ),
                // answer button padding & allignment
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: allAnswers.map((answer) => Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: ElevatedButton(
                      onPressed: () => makeGuess(answer),
                      child: Text(answer),
                    ),
                  )).toList(),
                ),
                Text('Current Streak - $playerStreak',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold
                  ),
                )
              ],
            ),
          ),
        ),
      );
    }
  }
}
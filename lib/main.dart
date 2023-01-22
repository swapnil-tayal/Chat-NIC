import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'model.dart';
import 'introduction_screen.dart';
import 'darkMode.dart';
import 'ChatPageCurie.dart';

bool show = true;
void main() async {

  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  show = prefs.getBool('ON_BOARDING') ?? true;
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'OPEN AI Chat NIC',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: IntroScreen(),
    );
  }
}


class FirstPage extends StatelessWidget{
  const FirstPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context){
    return Scaffold(
        body: Center(
          child: ElevatedButton (
            onPressed: () {
              Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (BuildContext context){
                        return const ChatPage();
                      }
                  )
              );
            },
            child: const Text('hello bye'),
          ),
        )
    );
  }
}

const backgroundColor = Color(0xffffffff);
const botBackgroundColor = Color(0xfff7f7f8);
const submitBackgroundColor = Color(0xff343541);
const screenBackgroundColor = Color(0xffffffff);

class ChatPage extends StatefulWidget{
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

Future<String> generateResponse(String prompt) async {
  const apiKey = "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";
  var url = Uri.https("api.openai.com", "/v1/completions");
  final response = await http.post(
      url,
      headers: {
        'Content-Type':'application/json',
        'Authorization':'Bearer $apiKey'
      },
      body: json.encode({
        'model':'text-davinci-003',
        'prompt':prompt,
        'temperature':0,
        'max_tokens':2000,
        'top_p':1,
        'frequency_penalty': 0.0,
        'presence_penalty': 0.0,
      })
  );

  Map<String, dynamic> newresponse = jsonDecode(response.body);

  var str = newresponse['choices'][0]['text'];
  // print(str);
  // return 'text';
  return str.substring(2, str.length);
}

class _ChatPageState extends State<ChatPage>{

  late bool isLoading;
  final TextEditingController _textController = TextEditingController();

  final _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];

  @override
  void initState(){
    super.initState();
    isLoading = false;
  }

  @override
  Widget build(BuildContext context){
    return SafeArea(
      child: Scaffold(

        appBar: AppBar(
          actions: <Widget>[
            IconButton(
              icon: const Icon(
                Icons.electric_bolt,  // add custom icons also
                color: Colors.white,
              ),
              onPressed: () {
                Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (BuildContext context){
                          return const ChatPageCurie();
                        }
                    )
                );
              },
            ),
            IconButton(
              icon: const Icon(
                Icons.nightlight_round,  // add custom icons also
                color: Colors.white,
              ),
              onPressed: () {
                Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (BuildContext context){
                          return const ChatPageDark();
                        }
                    )
                );
              },
            ),
          ],
          automaticallyImplyLeading: false,
          toolbarHeight: 75,
          title: const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              "CHAT NIC",
              maxLines: 2,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white),
            ),
          ),
          backgroundColor: submitBackgroundColor,
        ),
        backgroundColor: screenBackgroundColor,

        body: Column(
          children: [
            // chat body
            Expanded(
              child: _buildList(),
            ),
            Visibility(
              visible: isLoading,
              child: const Padding(
                padding: EdgeInsets.all(8.0),
                child: CircularProgressIndicator(
                  color: Colors.black,
                )
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(30.0),
              child:Row(
                children: [
                  _buildInput(),
                  _buildSumbit(),
                ],
              ),
            ),
          ],
        )
      ),
    );
  }

  Expanded _buildInput(){
    return Expanded(
      child: TextField(
        textCapitalization: TextCapitalization.sentences,
        style: const TextStyle(color: Colors.white),
        controller: _textController,
        decoration: const InputDecoration(
          hintText: 'Ask ME...',
          hintStyle: TextStyle(color: Color(0xffb3b8bc)),
          fillColor: submitBackgroundColor,
          filled: true,
          border: InputBorder.none,
          focusedBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          disabledBorder: InputBorder.none),
        ),
      );
  }


  Widget _buildSumbit(){
    return Visibility(
      visible: !isLoading,
      child: Container(
        color: submitBackgroundColor,
        child: IconButton(
          icon: const Icon(
              Icons.send_rounded,
              color: Color.fromRGBO(142, 142, 160, 1),
          ),
          onPressed: () async {
            // display user input
            setState(() {
              _messages.add(ChatMessage(
                text: _textController.text,
                chatMessageType: ChatMessageType.user,
              ));
              isLoading = true;
            });
            var input = _textController.text;
            _textController.clear();
            Future.delayed(const Duration(milliseconds: 50))
              .then((value) => _scrollDown());

            // call chat-bot api
            generateResponse(input).then((value){
              setState(() {
                isLoading = false;
                _messages.add(ChatMessage(
                  text: value, chatMessageType: ChatMessageType.bot
                ));
              });
            });
            _textController.clear();
            Future.delayed(const Duration(milliseconds: 50))
              .then((value) => _scrollDown());
          },
        )
      ),
    );
  }

  void _scrollDown(){
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  ListView _buildList(){
    return ListView.builder(
        itemCount: _messages.length,
        controller: _scrollController,
        itemBuilder: ((context, index){
          var message = _messages[index];
          return ChatMessageWidget(
            text: message.text,
            chatMessageType: message.chatMessageType,
          );
        }
      )
    );
  }
}

class ChatMessageWidget extends StatelessWidget{

  final String text;
  final ChatMessageType chatMessageType;
  const ChatMessageWidget(
      {super.key, required this.text, required this.chatMessageType}
  );

  @override
  Widget build(BuildContext context){
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 0),
      padding: const EdgeInsets.all(16),
      color: chatMessageType == ChatMessageType.bot
        ? botBackgroundColor
        : backgroundColor,
      child: Row(
        children: [
          chatMessageType == ChatMessageType.bot
            ? Container(
              margin: const EdgeInsets.only(right: 16),
              child: const CircleAvatar(
                backgroundColor: Color(0xff94d500),
                child: Icon(
                  Icons.rocket_launch_sharp,
                ),
              ),
            )
            : Container(
              margin: const EdgeInsets.only(right: 16),
              child: const CircleAvatar(
                child: Icon(Icons.person),
              ),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.all(
                      Radius.circular(8),
                    )
                  ),
                  child: Text(
                    text,
                    style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(color: Colors.black),
                  ),
                )
              ],
            )
          )
        ],
      ),
    );
  }
}
import 'package:aska/constant.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:aska/model.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget
{
  const MyApp({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context)
  {
    return const MaterialApp(
      home: ChatPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
 
const backgroundColor = Color(0xff343541);
const botBackgroundColor = Color(0xff444654);

class ChatPage extends StatefulWidget
{
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => ChatPageState();
}

class ChatPageState extends State<ChatPage>
{
  late bool isWaiting;
  TextEditingController _textController = TextEditingController();
  final _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];

  @override
  void initState() {
    super.initState();
    isWaiting = false;
  }

  Future<String> generateResponse(String prompt) async {
    final apikey = apiKey;
    var url = Uri.https("api.openai.com", "/v1/completions");
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization' : 'Bearer $apikey'
      },
      body: jsonEncode({
        'model' :  'text-davinci-003',
        'prompt' : prompt,
        'temperature' : 0,
        'max_tokens' : 2000,
        'top_p' : 1,
        'frequency_penalty' : 0.0,
        'presence_penalty' : 0.0
      })
    );
    Map<String,dynamic> newresponse = jsonDecode(response.body);
    return newresponse['choices'][0]['text'];
  }


  @override
  Widget build(BuildContext context)
  {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 70,
          title: const Padding(
            padding: EdgeInsets.all(6.0),
            child: Text(
              "Aska - ChatBot on the go",
              maxLines: 1,
              textAlign: TextAlign.center,
            ),
          ),
          backgroundColor: botBackgroundColor,
        ),
        backgroundColor: backgroundColor,
        body: Column(
          children: [
            // ChatBody
            Expanded(child: _buildList(),
            ),

            Visibility(
              visible: isWaiting,
              child: Padding(
                padding: const EdgeInsets.all(6.0),
                child: CircularProgressIndicator(
                  color: Colors.white, 
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(6.0),
              child: Row(
                children: [
                  //Input Field
                  _buildInput(),

                  //Submit button
                  _buildSubmit(),
                ],
              )
            )
          ],
        ),
      ),
    );
  }

  Expanded _buildInput()
  {
    return Expanded(
      child: TextField(
        textCapitalization: TextCapitalization.sentences,
        style: TextStyle(color: Colors.white),
        controller: _textController,
        decoration: InputDecoration(
          fillColor: botBackgroundColor,
          filled: true,
          border: InputBorder.none,
          focusedBorder: InputBorder.none,
          enabledBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          disabledBorder: InputBorder.none
        ),
      ),
    );
  }

  Widget _buildSubmit()
  {
    return Visibility(
      visible: !isWaiting,
       child: Container(
        child: IconButton(
          icon: Icon(
            Icons.send_rounded,
            color: Color.fromRGBO(142, 142, 160, 1)
          ),
          onPressed: () {

            // to display the user's input
            setState(() {
              _messages.add(ChatMessage(
                text: _textController.text,
                chatMessageType: ChatMessageType.user
              ));
              isWaiting = true;
            });
            var input = _textController.text;
            _textController.clear();
            Future.delayed(
              Duration(milliseconds: 50)).then((value) => _scrollDown());
            
            // call the api
            generateResponse(input).then((value) {
              setState(() {
                isWaiting = false;
                _messages.add(ChatMessage(
                  text: value, 
                  chatMessageType: ChatMessageType.bot
                ));
              });
            });
            _textController.clear();
            Future.delayed(Duration(milliseconds: 50))
                .then((value) => _scrollDown());
          },
        ),
      )
    );
  }

  void _scrollDown() {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent, 
      duration: Duration(milliseconds: 300), 
      curve: Curves.easeOut,
    );
  }

  ListView _buildList()
  {
    return ListView.builder(
      itemCount: _messages.length,
      controller: _scrollController,
      itemBuilder: ((context, index) {
        var message = _messages[index];
        return ChatMessageWidget(
          text: message.text,
          chatMessageType: message.chatMessageType,
        );
      }
    ));
  }
}

class ChatMessageWidget extends StatelessWidget {
  final String text;
  final ChatMessageType chatMessageType;
  const ChatMessageWidget(
    {super.key, required this.text, required this.chatMessageType});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10),
      padding: EdgeInsets.all(16),
      color: chatMessageType == ChatMessageType.bot
        ?botBackgroundColor
        :backgroundColor,
        child: Row(children: [
          chatMessageType == ChatMessageType.bot 
            ?Container(
              margin: EdgeInsets.only(right: 16),
              child: CircleAvatar(
                backgroundColor: Color.fromRGBO(255, 255, 255, 1),
                child: Image.asset(
                  'assets/images/openai-logo.png',
                  //color: Colors.white,
                  scale: 1.0 
                ),
              ),
            )
            : Container (
              margin: EdgeInsets.only(right: 16),
              child: CircleAvatar (
                child: Icon(Icons.person),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.all(
                        Radius.circular(8),
                      ),
                    ),
                    child: Text(
                      text, 
                      style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(color: Colors.white),
                    ),
                  )
                ],
              ))
        ])
    );
  }
}
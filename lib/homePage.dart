import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:unique_identifier/unique_identifier.dart';
import 'package:nfc_manager/nfc_manager.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title, required this.rollNumber,});
  final String title;
  final String rollNumber;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String? desiredParam;
  String _identifier = 'Unknown';
     int _nfcTagId = 0;
  final String apiUrl = "http://192.168.1.37:9081/api/v1/student/mark-attendance";
  bool isAttendanceMarked = false;
  TextEditingController rollNumberController = TextEditingController();
  ValueNotifier<dynamic> result = ValueNotifier(null);
  bool isActive = false;
  String stringValue = "";
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

   String errorData = "";



  @override
  void initState() {
    // initUniqueIdentifierState();
    WidgetsBinding.instance.addPostFrameCallback(_markAttendancePopUp);
    _tagRead();
    rollNumberController.text.toString();
    // initUniqueIdentifierState();
    print("permission");
    super.initState();
  }
  Future<void> _tagRead() async{
    NfcManager.instance.startSession(onDiscovered: (NfcTag tag) async {
      result.value = tag.data;
      List<int> payload = tag.data["ndef"]["cachedMessage"]["records"][0]["payload"];
      stringValue = utf8.decode(payload);
      stringValue = stringValue.replaceAll('\x00', '').trim();
      setState(() {
        isActive = true;
      });
      print("vandana ${result.value}");
      print("tagid*** ${stringValue}");

     initUniqueIdentifierState();
      NfcManager.instance.stopSession();
      Navigator.of(context).pop();
    },
      pollingOptions: {NfcPollingOption.iso14443},);
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Center(child: Text(widget.title)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(15),
        child:
        SingleChildScrollView(
          child: Column(
            children: <Widget>[
              Center(
                child: SizedBox(
                  height: MediaQuery.of(context).size.height*0.15,
                    width: MediaQuery.of(context).size.height*0.15,
                    child: Image.asset(
                      isAttendanceMarked
                        ? "assets/png/green_check.png"
                        : "assets/png/info.png",)),
              ),
              const SizedBox(height: 10,),
              InkWell(
                onTap: (){
                  setState(() {
                    _selectDate(context);
                  });
                },
                child:  const Center(
                  child: Text(
                    'view all attendance',
                    style: TextStyle(fontSize: 16,fontWeight: FontWeight.w400,color: Colors.blue),
                  ),
                ),
              ),
              const SizedBox(height: 20,),
              // isAttendanceMarked?
               Form(
                 key: _formKey,
                 child: Column(
                   children: [
                     const SizedBox(height: 20,),
                     Padding(
                       padding: const EdgeInsets.all(20),
                       child: TextFormField(
                         controller: rollNumberController,
                         decoration: const InputDecoration(
                           border: OutlineInputBorder(),
                           labelText: 'Roll Number',
                           // this is a workaround for async validations
                         ),
                         onChanged: (value) {
                           // clear submission error of email field
                           setState(() {
                             // isEmailAlreadyRegistered = false;
                           });
                         },
                         validator: (value){
                           if(value!.isEmpty){
                             return "this field can not empty";
                           }
                           else{
                             return null;
                           }
                         },
                       ),
                     ),
                     // Text('Error: ${errorData}'),
                   ],
                 ),
               ),
              ElevatedButton(
                onPressed:()async{
                  if (_formKey.currentState!.validate()) {
                    _processNFC();
                  }
                },
                child: Text("Mark Attendance"),
              ),
            ],
          ),
        )

    ));
  }
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2023, 1, 1),
      firstDate: DateTime(2022, 1, 1),
      lastDate: DateTime(2024, 12, 31),
    );

    if (picked != null && picked != DateTime.now()) {
      print('Selected date: $picked');
      // You can handle the selected date here
    }
  }


  Future<void> initUniqueIdentifierState() async {
    String identifier;
     // int nfcTagId;
    try {
        // nfcTagId =  DateTime.now().millisecondsSinceEpoch;
      identifier = (await UniqueIdentifier.serial)!;
      print("serial number");
      print(identifier.toString());
      // print(nfcTagId.toString());
      setState(() {
        // _nfcTagId = nfcTagId;
        _identifier = identifier;
      });
      _getRollNumber(_identifier);
    } on PlatformException {
      identifier = 'Failed to get Unique Identifier';
      // nfcTagId = -1;
    }

    if (!mounted) return;

    setState(() {
      // _nfcTagId = nfcTagId;
      _identifier = identifier;
    });
  }

  Future<void> _getRollNumber(String identifierID) async{
    try {
      print("stringValue $stringValue");
      final String fetchUrl = "http://192.168.1.37:9081/api/v1/student/get-roll-num?nfcTagId=$stringValue&deviceId=$_identifier";
       // const String fetchUrl = "http://192.168.1.39:9081/api/v1/student/get-roll-num?deviceId=";
      final response = await http.get(Uri.parse(fetchUrl));
      print("new url for getrollnumber");
      print(Uri.parse(fetchUrl));
      print(_identifier);
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        print("getrooldata");
        print(data.toString());
        handleGetRollNumberSuccessResponse(data);
      } else {
        final Map<String, dynamic> errorData = json.decode(response.body);
        handleGetRollNumberErrorResponse(errorData);
      }
    }catch(e){
      print(e);
    }
  }
  void handleGetRollNumberSuccessResponse(Map<String, dynamic> data) {
    print("Get Roll Number Success Response: $data");
    if (data.containsKey('status') && data['status'] == 200 && data.containsKey('message') && data['message'] == "No roll number exist!") {
      print('No roll number exists for the provided device ID.');
    } else if (data.containsKey('rollNumber')) {
      print("roll number****");
      print(rollNumberController.text);
      setState(() {
        rollNumberController.text = data['rollNumber'].toString();
      });
    }
  }
  void handleGetRollNumberErrorResponse(Map<String, dynamic> errorData){
    print("Get Roll Number Error Response: $errorData");
    if (errorData.containsKey('message')) {
      // Display the error message to the user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${errorData['message']}'),
          backgroundColor: Colors.red, // Customize the color
        ),
      );
    } else {
      // Handle other error conditions if needed
    }
  }
   _markAttendancePopUp(_)   {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // if (isActive=true) {
        //   Navigator.of(context).pop(); // Close the dialog
        // }
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            // Navigator.of(context).pop(); // Close the dialog when tapped outside
          },
          child: AlertDialog(
            title: Text("Warning!"),
            content: Text("Please tap on your NFC Tag."),
          ),
        );
      },
    );
  }
  void _processNFC() async {
    try {
      // Your existing NFC handling logic goes here
      // ...

      // After successfully handling NFC tag tap, mark the attendance
      await _markAttendance();
    } catch (error) {
      print("Error processing NFC: $error");
      // Handle error as needed
    }
  }
  Future<void> _markAttendance() async{
    print("Mark Attendance Data");
    try{
      // String? tagIdQueryParam = addQueryParam('tagID', nfcTagID);
      final response = await http.post(Uri.parse(apiUrl),
          headers: {
            'Content-Type': 'application/json',
          },
        body: jsonEncode({
          "nfcTagId":  _nfcTagId,
          "deviceId": _identifier,
          "roomName":"R5",
          "studentRollNumber":rollNumberController.text
          // int.parse(rollNumberController.text.toString()),
        }),
      );
      print("payload");
      print(apiUrl);
      print({
        "nfcTagId": _nfcTagId,
        "deviceId": _identifier,
        "roomName":"R5",
        "studentRollNumber":rollNumberController.text,
      });
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final Map<String, dynamic> data = json.decode(response.body);
        handleSuccessResponse(data);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Attendance marked successfully!'),
            backgroundColor: Colors.green, // You can customize the color
          ),
        );
      } else {
        final Map<String, dynamic> errorData = json.decode(response.body);
        handleErrorResponse(errorData);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to mark attendance. ${errorData['message']}'),
            backgroundColor: Colors.red, // You can customize the color
          ),
        );
      }
    } catch (error) {
      print("Error hello: $error");
    }
  }

  void handleSuccessResponse(Map<String, dynamic> data) {
    print("Success Response: $data");
    // _fetchAttendanceData();
    setState(() {
      rollNumberController.text = data['studentRollNumber'].toString();
      isAttendanceMarked = true;
    });
  }

  void handleErrorResponse(Map<String, dynamic> errorData) {
    print("Error Response: $errorData");
    if (errorData['status'] == 400 && errorData['message'] == 'Student already checked in.') {
      print('Student already checked in. Handle accordingly.');
      setState(() {
        rollNumberController.clear();
        isAttendanceMarked = false;
      });

    } else {
      print('Other error condition. Handle accordingly.');
    }
  }

}



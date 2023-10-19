import 'package:app_settings/app_settings.dart';
import 'package:avatar_glow/avatar_glow.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:siri_wave/siri_wave.dart';

import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

class homescreen extends StatefulWidget {
  homescreen({super.key});

  @override
  State<homescreen> createState() => _homescreenState();
}

class _homescreenState extends State<homescreen> {
  // bool _animate = false;

  bool _listening = false;

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _speechcontoller = TextEditingController();
  final stt.SpeechToText _speechtotext = stt.SpeechToText();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    checkPermissionStatus();
  }

  Future<bool> initialize() async {
    bool avialable = await _speechtotext.initialize(
        onStatus: (val) {
          print('onStatus: $val');
          if (val == "done") {
            setState(() {
              _listening = false;
            });
            showTopSnackBar(
                Overlay.of(context),
                const CustomSnackBar.error(
                  message: "Time Out !",
                ));
          }
        },
        onError: (val) => print('onError: $val'),
        debugLogging: true);
    print(avialable);
    return avialable;
  }

  Future<PermissionStatus> checkPermissionStatus() async {
    PermissionStatus permissionStatus = await Permission.microphone.status;
    return permissionStatus;
  }

  void permissions() async {
    await Permission.microphone.request();
  }

  void capture() async {
    bool avialable = await initialize();
    if (_listening) {
      _scrollController.animateTo(
        _scrollController.position.minScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
      if (avialable) {
        if (context.mounted) {
          showTopSnackBar(
              Overlay.of(context),
              const CustomSnackBar.info(
                message: "Start Speaking",
                backgroundColor: Color.fromRGBO(150, 129, 235, 1),
              ));
        }
        await _speechtotext.listen(
          onResult: (result) {
            _speechcontoller.text = _speechcontoller.text.isNotEmpty
                ? "${_speechcontoller.text + " " + result.recognizedWords}"
                : result.recognizedWords;
          },
        );
      }
    } else {
      _speechtotext.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          backgroundColor: Color.fromRGBO(101, 39, 190, 1),
          title: Text("Speech To Text  "),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: AvatarGlow(
          glowColor: Color.fromRGBO(101, 39, 190, 1),
          endRadius: 85,
          animate: _listening,
          duration: Duration(milliseconds: 2000),
          repeat: true,
          showTwoGlows: true,
          repeatPauseDuration: Duration(milliseconds: 100),

          // height: 100,
          // width: 100,
          child: Container(
            height: 70,
            width: 70,
            child: FloatingActionButton(
              backgroundColor: Color.fromRGBO(101, 39, 190, 1),
              onPressed: () async {
                PermissionStatus micpermission = await checkPermissionStatus();

                if (micpermission == PermissionStatus.permanentlyDenied) {
                  permissions();

                  if (context.mounted) {
                    showTopSnackBar(onTap: () {
                      AppSettings.openAppSettings(
                          type: AppSettingsType.settings);
                    },
                        Overlay.of(context),
                        const CustomSnackBar.error(
                          message:
                              "Microphone permission is Denined clik Here And Allow it",
                          backgroundColor: Color.fromRGBO(150, 129, 235, 1),
                        ));
                  }
                }

                if (micpermission == PermissionStatus.denied) {
                  permissions();
                }
                if (micpermission == PermissionStatus.granted) {
                  setState(() {
                    _listening = !_listening;
                  });

                  capture();
                }
              },
              child: const Icon(Icons.mic, size: 35),
            ),
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(
                left: 30, right: 30, top: 30, bottom: 150),
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                children: [
                  if (_listening)
                    SiriWaveform.ios9(
                      controller:
                          IOS9SiriWaveformController(amplitude: 1, speed: .15),
                      options: IOS9SiriWaveformOptions(
                        width: MediaQuery.of(context).size.width,
                        showSupportBar: false,
                      ),
                    ),
                  TextField(
                    style: const TextStyle(
                        fontSize: 32, fontWeight: FontWeight.w400),
                    decoration: const InputDecoration(
                        hintText: "Press\nMic Button\nAnd Start To\nspeak",
                        hintStyle: TextStyle(
                          fontSize: 35,
                          fontWeight: FontWeight.w400,
                          letterSpacing: .5,
                        ),
                        border: InputBorder.none),
                    maxLines: null,
                    controller: _speechcontoller,
                  ),
                ],
              ),
            ),
          ),
        ));
  }
}

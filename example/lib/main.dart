import 'package:fimber/fimber.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ble_lib_example/devices_list/devices_bloc_provider.dart';
import 'package:flutter_ble_lib_example/devices_list/devices_list_view.dart';

import 'device_details/device_detail_view.dart';
import 'device_details/devices_details_bloc_provider.dart';
import 'local_notifications.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Fimber.plantTree(DebugTree());

  debugPrint("ccddee started");
  Notifications.init().then((value) => {
    Notifications.showNotificationWithText("started").then((value) =>
    {
      Fimber.d("Notifications initialized async")
    })
  });
  runApp(MyApp());
}
/*
Future onDidReceiveLocalNotification(
    int id, String title, String body, String payload) async {
  // display a dialog with the notification details, tap ok to go to another page
  showDialog(
    context: context,
    builder: (BuildContext context) => CupertinoAlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        CupertinoDialogAction(
          isDefaultAction: true,
          child: Text('Ok'),
          onPressed: () async {
            Navigator.of(context, rootNavigator: true).pop();

          },
        )
      ],
    ),
  );
}
*/

Future selectNotification(String payload) async {
  if (payload != null) {
    debugPrint('notification payload: ' + payload);
  }
}

final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

class MyApp extends StatelessWidget {

  @override
  Widget build(BuildContext context) {

    return MaterialApp(
        title: 'FlutterBleLib example',
        theme: new ThemeData(
          primaryColor: new Color(0xFF0A3D91),
          accentColor: new Color(0xFFCC0000),
        ),
        initialRoute: "/",
        routes: <String, WidgetBuilder>{
          "/": (context) => DevicesBlocProvider(child: DevicesListScreen()),
          "/details": (context) => DeviceDetailsBlocProvider(child: DeviceDetailsView()),
        },
        navigatorObservers: [routeObserver],
      );
  }
}

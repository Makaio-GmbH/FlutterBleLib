import 'dart:async';

import 'package:fimber/fimber.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ble_lib_example/local_notifications.dart';
import 'package:flutter_background_geolocation/flutter_background_geolocation.dart' as bg;
import 'package:flutter_ble_lib_example/model/ble_device.dart';
import 'package:background_fetch/background_fetch.dart';
import 'devices_bloc.dart';
import 'devices_bloc_provider.dart';
import 'hex_painter.dart';


typedef DeviceTapListener = void Function();

class DevicesListScreen extends StatefulWidget {
  @override
  State<DevicesListScreen> createState() => DeviceListScreenState();
}

class DeviceListScreenState extends State<DevicesListScreen> {
  DevicesBloc _devicesBloc;
  StreamSubscription _appStateSubscription;

  @override
  void initState() {
    Notifications.register(context);

    _configureGeolocation();

    super.initState();
  }


  void _configureGeolocation() {
// 50.2399241,8.6093047,
    bg.BackgroundGeolocation.addGeofence(bg.Geofence(
        identifier: "Home",
        radius: 200,
        latitude: 50.2399241,
        longitude: 8.6093047,
        notifyOnEntry: true,
        notifyOnExit: true,
        extras: {
          "route_id": 1234
        }
    )).then((bool success) {
      print('[addGeofence] success');
    }).catchError((dynamic error) {
      print('[addGeofence] FAILURE: $error');
    });

    bg.BackgroundGeolocation.addGeofence(bg.Geofence(
        identifier: "Office",
        radius: 200,
        latitude: 50.2238097,
        longitude: 8.6192321,
        notifyOnEntry: true,
        notifyOnExit: true,
        extras: {
          "route_id": 1234
        }
    )).then((bool success) {
      print('[addGeofence] success');
    }).catchError((dynamic error) {
      print('[addGeofence] FAILURE: $error');
    });

// Step 1:  Configure BackgroundFetch as usual.
    BackgroundFetch.configure(BackgroundFetchConfig(
        minimumFetchInterval: 15
    ), (String taskId) async {
      // This is the fetch-event callback.
      print("[BackgroundFetch] taskId: $taskId");

      // Use a switch statement to route task-handling.
      switch (taskId) {
        case 'com.transistorsoft.customtask':
          print("Received custom task");
          break;
        default:
          print("Default fetch task");
      }
      // Finish, providing received taskId.
      BackgroundFetch.finish(taskId);
    });

// Step 2:  Schedule a custom "oneshot" task "com.transistorsoft.customtask" to execute 5000ms from now.
    BackgroundFetch.scheduleTask(TaskConfig(
        taskId: "com.transistorsoft.customtask",
        delay: 5000  // <-- milliseconds
    ));





    ////
    // 1.  Listen to events (See docs for all 12 available events).
    //

    // Fired whenever a location is recorded
    bg.BackgroundGeolocation.onLocation((bg.Location location) {
      print('[location] - $location');
    });

    // Fired whenever the plugin changes motion-state (stationary->moving and vice-versa)
    bg.BackgroundGeolocation.onMotionChange((bg.Location location) {
      print('[motionchange] - $location');
    });

    // Fired whenever the state of location-services changes.  Always fired at boot
    bg.BackgroundGeolocation.onProviderChange((bg.ProviderChangeEvent event) {
      print('[providerchange] - $event');
    });

    bg.BackgroundGeolocation.onHeartbeat((bg.HeartbeatEvent event) {
      print('[onHeartbeat] ${event}');

    });

    ////
    // 2.  Configure the plugin
    //
    bg.BackgroundGeolocation.ready(bg.Config(
        desiredAccuracy: bg.Config.DESIRED_ACCURACY_HIGH,
        distanceFilter: 10.0,
        stopOnTerminate: false,
        startOnBoot: true,
        debug: true,
        disableStopDetection: true,
        heartbeatInterval: 60,
        logLevel: bg.Config.LOG_LEVEL_VERBOSE
    )).then((bg.State state) {
      if (!state.enabled) {
        ////
        // 3.  Start the plugin.
        //
        bg.BackgroundGeolocation.start();
      }
    });
  }

  @override
  void didUpdateWidget(DevicesListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    Fimber.d("didUpdateWidget");
  }

  void _onPause() {
    Fimber.d("onPause");
    _appStateSubscription.cancel();
    _devicesBloc.dispose();
  }

  void _onResume() {
    Fimber.d("onResume");
    _devicesBloc.init();
    _appStateSubscription = _devicesBloc.pickedDevice.listen((bleDevice) async {
      Fimber.d("navigate to details");
      _onPause();
      await Navigator.pushNamed(context, "/details");
      _shouldRunOnResume = true;
      Fimber.d("back from details");
    });
  }

  bool _shouldRunOnResume = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    Fimber.d("DeviceListScreenState didChangeDependencies");
    if (_devicesBloc == null) {
      _devicesBloc = DevicesBlocProvider.of(context);
      if (_shouldRunOnResume) {
        _shouldRunOnResume = false;
        _onResume();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Fimber.d("build DeviceListScreenState");
    _devicesBloc.refresh();
    if (_shouldRunOnResume) {
      _shouldRunOnResume = false;
      _onResume();
    }
    return Scaffold(
      appBar: AppBar(
        title: Text('Bluetooth devices'),
      ),
      body: StreamBuilder<List<BleDevice>>(
        initialData: _devicesBloc.visibleDevices.value,
        stream: _devicesBloc.visibleDevices,
        builder: (context, snapshot) => RefreshIndicator(
          onRefresh: _devicesBloc.refresh,
          child: DevicesList(_devicesBloc, snapshot.data),
        ),
      ),
    );
  }

  @override
  void dispose() {
    Fimber.d("Dispose DeviceListScreenState");
    _onPause();
    super.dispose();
  }

  @override
  void deactivate() {
    print("deactivate");
    super.deactivate();
  }

  @override
  void reassemble() {
    Fimber.d("reassemble");
    super.reassemble();
  }
}

class DevicesList extends ListView {
  DevicesList(DevicesBloc devicesBloc, List<BleDevice> devices)
      : super.separated(
            separatorBuilder: (context, index) => Divider(
                  color: Colors.grey[300],
                  height: 0,
                  indent: 0,
                ),
            itemCount: devices.length,
            itemBuilder: (context, i) {
              Fimber.d("Build row for $i");
              return _buildRow(context, devices[i],
                  _createTapListener(devicesBloc, devices[i]));
            });

  static DeviceTapListener _createTapListener(
      DevicesBloc devicesBloc, BleDevice bleDevice) {
    return () {
      Fimber.d("clicked device: ${bleDevice.name}");
      devicesBloc.devicePicker.add(bleDevice);
    };
  }

  static Widget _buildAvatar(BuildContext context, BleDevice device) {
    switch (device.category) {
      case DeviceCategory.sensorTag:
        return CircleAvatar(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Image.asset('assets/ti_logo.png'),
            ),
            backgroundColor: Theme.of(context).accentColor);
      case DeviceCategory.hex:
        return CircleAvatar(
            child: CustomPaint(painter: HexPainter(), size: Size(20, 24)),
            backgroundColor: Colors.black);
      case DeviceCategory.other:
      default:
        return CircleAvatar(
            child: Icon(Icons.bluetooth),
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white);
    }
  }

  static Widget _buildRow(BuildContext context, BleDevice device,
      DeviceTapListener deviceTapListener) {
    return ListTile(
      leading: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: _buildAvatar(context, device),
      ),
      title: Text(device.name),
      trailing: Padding(
        padding: const EdgeInsets.only(top: 16),
        child: Icon(Icons.chevron_right, color: Colors.grey),
      ),
      subtitle: Column(
        children: <Widget>[
          Text(
            device.id.toString(),
            style: TextStyle(fontSize: 10),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          )
        ],
        crossAxisAlignment: CrossAxisAlignment.start,
      ),
      onTap: deviceTapListener,
      contentPadding: EdgeInsets.fromLTRB(16, 0, 16, 12),
    );
  }
}

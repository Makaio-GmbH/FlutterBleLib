import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:fimber/fimber.dart';
import 'package:flutter_ble_lib_example/model/ble_device.dart';
import 'package:flutter_ble_lib_example/repository/device_repository.dart';
import 'package:flutter_ble_lib/flutter_ble_lib.dart';
import 'package:blemulator/blemulator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rxdart/rxdart.dart';
import 'package:device_info/device_info.dart';

import '../local_notifications.dart';

class DevicesBloc {
  final List<BleDevice> bleDevices = <BleDevice>[];

  BehaviorSubject<List<BleDevice>> _visibleDevicesController =
      BehaviorSubject<List<BleDevice>>.seeded(<BleDevice>[]);

  StreamController<BleDevice> _devicePickerController =
      StreamController<BleDevice>();

  StreamSubscription<ScanResult> _scanSubscription;
  StreamSubscription _devicePickerSubscription;

  ValueObservable<List<BleDevice>> get visibleDevices =>
      _visibleDevicesController.stream;

  Sink<BleDevice> get devicePicker => _devicePickerController.sink;

  DeviceRepository _deviceRepository;
  BleManager _bleManager;
  PermissionStatus _locationPermissionStatus = PermissionStatus.undetermined;

  Stream<BleDevice> get pickedDevice => _deviceRepository.pickedDevice
      .skipWhile((bleDevice) => bleDevice == null);

  DevicesBloc(this._deviceRepository, this._bleManager);

  void _handlePickedDevice(BleDevice bleDevice) {
    _deviceRepository.pickDevice(bleDevice);
  }

  void dispose() {
    Fimber.d("cancel _devicePickerSubscription");
    _devicePickerSubscription.cancel();
    _visibleDevicesController.close();
    _devicePickerController.close();
    _scanSubscription?.cancel();
  }

  Future<void> _simulatePeripheralInSim() async
  {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

    var isSimulator = false;
/*
    if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      isSimulator = !androidInfo.isPhysicalDevice;
    } else if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      isSimulator = !iosInfo.isPhysicalDevice;
    }
*/
    if (isSimulator)
    {
      Blemulator blemulator = Blemulator();
      blemulator.addSimulatedPeripheral(SensorTag());
      blemulator.simulate();
    }
  }

  void init() {
    Fimber.d("Init devices bloc");
    bleDevices.clear();

    _simulatePeripheralInSim().then((_) =>
        _bleManager
            .createClient(
            restoreStateIdentifier: "example-restore-state-identifier",
            restoreStateAction: (peripherals) {
              peripherals?.forEach((peripheral) {
                Fimber.d("Restored peripheral: ${peripheral.name}");
              });
              this.init();
            })
            .catchError((e) => Fimber.d("Couldn't create BLE client", ex: e))
            .then((_) => _checkPermissions())
            .catchError((e) => Fimber.d("Permission check error", ex: e))
            .then((_) => _waitForBluetoothPoweredOn())
            .then((_) => _startScan()));



    if (_visibleDevicesController.isClosed) {
      _visibleDevicesController =
          BehaviorSubject<List<BleDevice>>.seeded(<BleDevice>[]);
    }

    if (_devicePickerController.isClosed) {
      _devicePickerController = StreamController<BleDevice>();
    }

    Fimber.d(" listen to _devicePickerController.stream");
    _devicePickerSubscription =
        _devicePickerController.stream.listen(_handlePickedDevice);
  }

  Future<void> _checkPermissions() async {

  }

  Future<void> _waitForBluetoothPoweredOn() async {
    Completer completer = Completer();
    StreamSubscription<BluetoothState> subscription;
    subscription = _bleManager
        .observeBluetoothState(emitCurrentValue: true)
        .listen((bluetoothState) async {
      if (bluetoothState == BluetoothState.POWERED_ON &&
          !completer.isCompleted) {
        await subscription.cancel();
        completer.complete();
      }
    });
    return completer.future;
  }

  void _startScan() {
    Fimber.d("Ble client created");
    _scanSubscription =
        _bleManager.startPeripheralScan(
            allowDuplicates: true,
            callbackType: CallbackType.allMatches,
            scanMode: ScanMode.lowLatency,
          uuids: ["FEAA"]

        ).listen((ScanResult scanResult) {
      var bleDevice = BleDevice(scanResult);


      Notifications.showNotification();

      if (
          !bleDevices.contains(bleDevice)) {
        if(scanResult.advertisementData.localName != null)
          scanResult.advertisementData.localName = "Unknown device";
        Fimber.d(
            'found new device ${scanResult.advertisementData.localName} ${scanResult.peripheral.identifier}');
        bleDevices.add(bleDevice);



        _visibleDevicesController.add(bleDevices.sublist(0));
      }
    });
  }

  Future<void> refresh() async {
    if(_scanSubscription != null)
      {
        _scanSubscription.cancel();
        await _bleManager.stopPeripheralScan();
        bleDevices.clear();
      }

    _visibleDevicesController.add(bleDevices.sublist(0));
    await _checkPermissions()
        .then((_) => _startScan())
        .catchError((e) => Fimber.d("Couldn't refresh", ex: e));
  }
}

class SensorTag extends SimulatedPeripheral {
  SensorTag(
      {String id = "4C:99:4C:34:DE:76",
        String name = "SensorTag",
        String localName = "SensorTag"})
      : super(
      name: name,
      id: id,
      advertisementInterval: Duration(milliseconds: 800),

      services: [
        SimulatedService(
            uuid: "F000AA00-0451-4000-B000-000000000000",
            isAdvertised: true,
            characteristics: [
              SimulatedCharacteristic(
                  uuid: "F000AA01-0451-4000-B000-000000000000",
                  value: Uint8List.fromList([101, 254, 64, 12]),
                  convenienceName: "IR Temperature Data"),
              SimulatedCharacteristic(
                  uuid: "F000AA02-0451-4000-B000-000000000000",
                  value: Uint8List.fromList([0]),
                  convenienceName: "IR Temperature Config"),
              SimulatedCharacteristic(
                  uuid: "F000AA03-0451-4000-B000-000000000000",
                  value: Uint8List.fromList([50]),
                  convenienceName: "IR Temperature Period"),
            ],
            convenienceName: "Temperature service")
      ]) {
    scanInfo.localName = localName;
    scanInfo.rssi = -40;
  }

  @override
  Future<int> rssi() async {
    // TODO: implement rssi
    return -45;
  }

  @override
  Future<bool> onConnectRequest() async {
    await Future.delayed(Duration(milliseconds: 200));
    return super.onConnectRequest();
  }
}

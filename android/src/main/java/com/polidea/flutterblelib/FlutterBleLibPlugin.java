package com.polidea.flutterblelib;


import android.content.Context;
import android.util.Log;

import com.polidea.flutterblelib.chanelhandler.BluetoothStateHandler;
import com.polidea.flutterblelib.chanelhandler.DeviceConnectionChangedHandler;
import com.polidea.flutterblelib.chanelhandler.ScanDevicesHandler;
import com.polidea.flutterblelib.listener.BluetoothStateChangeListener;
import com.polidea.flutterblelib.listener.DeviceConnectionChangeListener;
import com.polidea.flutterblelib.listener.Namespace;
import com.polidea.flutterblelib.listener.OnErrorAction;
import com.polidea.flutterblelib.listener.OnSuccessAction;

import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.Registrar;

public class FlutterBleLibPlugin implements MethodCallHandler {

    public static final String TAG = "FlutterBleLibPlugin";
    private ScanDevicesHandler scanDevicesHandler;
    private BluetoothStateHandler bluetoothStateHandler;
    private DeviceConnectionChangedHandler deviceConnectionChangedHandler;

    private BleHelper bleHelper;


    private FlutterBleLibPlugin(Context context) {
        bleHelper = new BleHelper(context);
        scanDevicesHandler = new ScanDevicesHandler();
        bluetoothStateHandler = new BluetoothStateHandler();
        deviceConnectionChangedHandler = new DeviceConnectionChangedHandler();
    }

    public static void registerWith(Registrar registrar) {
        final MethodChannel channel = new MethodChannel(registrar.messenger(), Namespace.flutter_ble_lib);
        final EventChannel scanDevicesChannel = new EventChannel(registrar.messenger(), Namespace.flutter_ble_lib_scanDevices);
        final EventChannel bluetoothStateChanel = new EventChannel(registrar.messenger(), Namespace.flutter_ble_lib_stateChange);
        final EventChannel deviceConnectionChangedChanel = new EventChannel(registrar.messenger(), Namespace.flutter_ble_lib_deviceConnectionChanged);
        final FlutterBleLibPlugin handler = new FlutterBleLibPlugin(registrar.activity().getApplicationContext());
        channel.setMethodCallHandler(handler);
        scanDevicesChannel.setStreamHandler(handler.scanDevicesHandler);
        bluetoothStateChanel.setStreamHandler(handler.bluetoothStateHandler);
        deviceConnectionChangedChanel.setStreamHandler(handler.deviceConnectionChangedHandler);
    }

    @Override
    public void onMethodCall(MethodCall call, final Result result) {
        switch (call.method) {
            case BleMethod.createClient: {
                bleHelper.createClient();
                bleHelper.registerBluetoothStateChangeListener(new BluetoothStateChangeListener() {
                    @Override
                    public void onSuccess(BleData.BluetoothStateMessage bluetoothStateMessage) {
                        bluetoothStateHandler.handleBluetoothState(bluetoothStateMessage);
                    }
                });
                bleHelper.registerDeviceConnectionChangeListener(new DeviceConnectionChangeListener() {
                    @Override
                    public void onSuccess(BleData.BleDeviceMessage bleDeviceMessage) {
                        deviceConnectionChangedHandler.handleBluetoothState(bleDeviceMessage);
                    }
                });
                return;
            }
            case BleMethod.destroyClient: {
                bleHelper.destroyClient();
                return;
            }
            case BleMethod.cancelTransaction: {
                bleHelper.cancelTransaction(call.arguments.toString());
                return;
            }
            case BleMethod.setLogLevel: {
                bleHelper.setLogLevel(BleData.LogLevelMessage.valueOf(call.arguments.toString()));
                return;
            }
            case BleMethod.logLevel: {
                bleHelper.logLevel(new OnSuccessAction<BleData.LogLevelMessage>() {
                    @Override
                    public void onSuccess(BleData.LogLevelMessage logLevelMessage) {
                        result.success(logLevelMessage.ordinal());
                    }
                });
                return;
            }
            case BleMethod.state: {
                bleHelper.state(new OnSuccessAction<BleData.BluetoothStateMessage>() {
                    @Override
                    public void onSuccess(BleData.BluetoothStateMessage success) {
                        result.success(success.ordinal());
                    }
                });
                return;
            }
            case BleMethod.startDeviceScan: {
                startDeviceScan(call, result);
                return;
            }
            case BleMethod.stopDeviceScan: {
                bleHelper.stopDeviceScan();
                return;
            }
            case BleMethod.requestMTUForDevice: {
                requestMTUForDevice(call, result);
                return;
            }
            case BleMethod.readRSSIForDevice: {
                readRSSIForDevice(call, result);
                return;
            }
            case BleMethod.cancelDeviceConnection: {
                cancelDeviceConnection(call, result);
                return;
            }
            case BleMethod.connectToDevice: {
                connectToDevice(call, result);
                return;
            }
            case BleMethod.isDeviceConnected: {
                isDeviceConnected(call, result);
                return;
            }
            case BleMethod.discoverAllServicesAndCharacteristicsForDevice: {
                discoverAllServicesAndCharacteristicsForDevice(call, result);
                return;
            }
            case BleMethod.servicesForDevice: {
                servicesForDevice(call, result);
                return;
            }
            case BleMethod.characteristicsForDevice: {
                characteristicsForDevice(call, result);
                return;
            }
            case BleMethod.characteristicsForService: {
                characteristicsForService(call, result);
                return;
            }
            case BleMethod.writeCharacteristicForDevice: {
                writeCharacteristicForDevice(call, result);
                return;
            }
            case BleMethod.writeCharacteristic: {
                writeCharacteristic(call, result);
                return;
            }
            case BleMethod.readCharacteristicForService: {
                readCharacteristicForService(call, result);
                return;
            }
            case BleMethod.readCharacteristicForDevice: {
                readCharacteristicForDevice(call, result);
                return;
            }
            case BleMethod.readCharacteristic: {
                readCharacteristic(call, result);
                return;
            }
            case BleMethod.monitorCharacteristicForDevice: {
                monitorCharacteristicForDevice(call, result);
                return;
            }
            case BleMethod.monitorCharacteristicForService: {
                monitorCharacteristicForService(call, result);
                return;
            }
            case BleMethod.monitorCharacteristic: {
                monitorCharacteristic(call, result);
                return;
            }
            default:
                result.notImplemented();

        }
    }

    private void discoverAllServicesAndCharacteristicsForDevice(MethodCall call, final Result result) {
        bleHelper.discoverAllServicesAndCharacteristicsForDevice(call.arguments.toString(),
                new OnSuccessAction<BleData.BleDeviceMessage>() {
                    @Override
                    public void onSuccess(BleData.BleDeviceMessage bleDeviceMessage) {
                        result.success(bleDeviceMessage.toByteArray());
                    }
                },
                new OnErrorAction() {
                    @Override
                    public void onError(Throwable t) {
                        result.error("Discover all services and characteristics for device error", t.getMessage(), t);
                    }
                }
        );
    }

    private void cancelDeviceConnection(MethodCall call, final Result result) {
        bleHelper.cancelDeviceConnection(call.arguments.toString(),
                new OnSuccessAction<BleData.BleDeviceMessage>() {
                    @Override
                    public void onSuccess(BleData.BleDeviceMessage bleDeviceMessage) {
                        result.success(bleDeviceMessage.toByteArray());
                    }
                },
                new OnErrorAction() {
                    @Override
                    public void onError(Throwable t) {
                        result.error("Request Mtu For Device error", t.getMessage(), t);
                    }
                }
        );

    }

    private void readRSSIForDevice(MethodCall call, final Result result) {

        final byte[] readRSSIForDeviceBytes = call.arguments();
        bleHelper.readRSSIForDevice(readRSSIForDeviceBytes,
                new OnSuccessAction<BleData.BleDeviceMessage>() {
                    @Override
                    public void onSuccess(BleData.BleDeviceMessage bleDeviceMessage) {
                        result.success(bleDeviceMessage.toByteArray());
                    }
                },
                new OnErrorAction() {
                    @Override
                    public void onError(Throwable t) {
                        result.error("Request Mtu For Device error", t.getMessage(), t);
                    }
                }
        );
    }

    private void requestMTUForDevice(MethodCall call, final Result result) {

        final byte[] mtuRequestTransactionMessageByte = call.arguments();
        bleHelper.requestMTUForDevice(mtuRequestTransactionMessageByte,
                new OnSuccessAction<BleData.BleDeviceMessage>() {
                    @Override
                    public void onSuccess(BleData.BleDeviceMessage bleDeviceMessage) {
                        result.success(bleDeviceMessage.toByteArray());
                    }
                },
                new OnErrorAction() {
                    @Override
                    public void onError(Throwable t) {
                        result.error("Request Mtu For Device error", t.getMessage(), t);
                    }
                }
        );
    }

    private void startDeviceScan(MethodCall call, final Result result) {
        final byte[] scanResultMessageByte = call.arguments();
        bleHelper.startDeviceScan(scanResultMessageByte,
                new OnSuccessAction<BleData.ScanResultMessage>() {
                    @Override
                    public void onSuccess(BleData.ScanResultMessage scanResultMessage) {
                        scanDevicesHandler.handleScanDevice(scanResultMessage);
                    }
                },
                new OnErrorAction() {
                    @Override
                    public void onError(Throwable t) {
                        result.error("Scan device error", t.getMessage(), t);
                    }
                }
        );
        result.success(null);
    }

    private void connectToDevice(final MethodCall call, final Result result) {
        final byte[] connectToDeviceDataMessageByte = call.arguments();
        bleHelper.connectToDevice(
                connectToDeviceDataMessageByte,
                new OnSuccessAction<BleData.BleDeviceMessage>() {
                    @Override
                    public void onSuccess(BleData.BleDeviceMessage connectedDeviceMessage) {
                        result.success(connectedDeviceMessage.toByteArray());
                    }
                },
                new OnErrorAction() {
                    @Override
                    public void onError(Throwable t) {
                        result.error("Error occours", t.getMessage(), t);
                    }
                }

        );
    }

    private void isDeviceConnected(MethodCall call, final Result result) {
        final String macAddress = call.arguments();
        bleHelper.isDeviceConnected(
                macAddress,
                new OnSuccessAction<Boolean>() {
                    @Override
                    public void onSuccess(Boolean success) {
                        result.success(success);
                    }
                },
                new OnErrorAction() {
                    @Override
                    public void onError(Throwable t) {
                        result.error("Error occurred", t.getMessage(), t);
                    }
                }
        );
    }

    private void servicesForDevice(MethodCall call, final Result result) {
        final String macAddress = call.arguments();
        bleHelper.servicesForDevice(
                macAddress,
                new OnSuccessAction<BleData.ServiceMessages>() {
                    @Override
                    public void onSuccess(BleData.ServiceMessages serviceMessages) {
                        result.success(serviceMessages.toByteArray());
                    }
                },
                new OnErrorAction() {
                    @Override
                    public void onError(Throwable t) {
                        result.error("Error occurred", t.getMessage(), t);
                    }
                }
        );
    }

    private void characteristicsForDevice(MethodCall call, final Result result) {

        final String macAddressByte = call.argument("deviceId");
        final String serviceUUID = call.argument("serviceUUID");
        bleHelper.characteristicsForDevice(macAddressByte,
                serviceUUID,
                new OnSuccessAction<BleData.CharacteristicMessages>() {
                    @Override
                    public void onSuccess(BleData.CharacteristicMessages characteristicMessages) {
                        result.success(characteristicMessages.toByteArray());
                    }
                },
                new OnErrorAction(){

                    @Override
                    public void onError(Throwable t) {
                        result.error("Error occurred", t.getMessage(), t);
                    }
                }
        );
    }

    private void characteristicsForService(MethodCall call, final Result result) {
        bleHelper.characteristicsForService((Integer)call.arguments(),
                new OnSuccessAction<BleData.CharacteristicMessages>() {
                    @Override
                    public void onSuccess(BleData.CharacteristicMessages characteristicMessages) {
                        result.success(characteristicMessages.toByteArray());
                    }
                },
                new OnErrorAction(){

                    @Override
                    public void onError(Throwable t) {
                        result.error("Error occurred", t.getMessage(), t);
                    }
                }
        );
    }

    private void writeCharacteristicForDevice(MethodCall call, final Result result) {
        //TODO
    }

    private void writeCharacteristic(MethodCall call, final Result result) {
        //TODO
    }

    private void readCharacteristicForDevice(MethodCall call, final Result result) {
        //TODO
    }

    private void readCharacteristicForService(MethodCall call, final Result result) {
        //TODO
    }

    private void readCharacteristic(MethodCall call, final Result result) {
        //TODO
    }

    private void monitorCharacteristicForDevice(MethodCall call, final Result result) {
        //TODO
    }

    private void monitorCharacteristicForService(MethodCall call, final Result result) {
        //TODO
    }

    private void monitorCharacteristic(MethodCall call, final Result result) {
        //TODO
    }

}
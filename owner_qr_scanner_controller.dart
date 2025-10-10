import 'dart:io' show Platform;
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:getx_architecture_2025/app/controllers/loading_controller.dart';

class OwnerQrScannerController extends GetxController {
  MobileScannerController? scannerController;
  RxString qrCode = ''.obs;
  RxBool isApproved = false.obs;
  Rx<Barcode?> barcode = Rx<Barcode?>(null);
  RxBool hasError = false.obs;
  RxBool isScanning = true.obs;
  RxString bookingId = ''.obs;
  RxBool showApprovalStatus = false.obs;
  RxBool isInitialized = false.obs;
  RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _initializeCamera();
  }

  // Initialize camera with permission check
  Future<void> _initializeCamera() async {
    try {
      if (Platform.isIOS) {
        await _initializeIOSCamera();
      } else {
        await _initializeAndroidCamera();
      }
    } catch (e) {
      print("Camera initialization error: $e");
      hasError.value = true;
      errorMessage.value = "Failed to initialize camera: $e";
      isInitialized.value = false;
    }
  }

  // iOS initialization - improved permission handling
  Future<void> _initializeIOSCamera() async {
    try {
      // Check current permission status
      var status = await Permission.camera.status;
      print("iOS Camera permission status: $status");

      // If permission is not granted, request it
      if (!status.isGranted) {
        status = await Permission.camera.request();
        print("iOS Camera permission request result: $status");
      }

      // Check if permission was granted
      if (status.isGranted) {
        // Create scanner controller
        scannerController = MobileScannerController(
          autoStart: false,
          detectionSpeed: DetectionSpeed.normal,
          facing: CameraFacing.back,
          torchEnabled: false,
        );

        isInitialized.value = true;
        hasError.value = false;
        errorMessage.value = '';

        // Start the scanner after a delay to ensure controller is ready
        await Future.delayed(Duration(milliseconds: 500));
        await scannerController?.start();
        
        print("iOS Camera initialized successfully");
      } else if (status.isPermanentlyDenied || status.isRestricted) {
        print("iOS camera permission permanently denied or restricted");
        hasError.value = true;
        errorMessage.value = "Camera permission is required. Please enable it in Settings.";
        isInitialized.value = false;
      } else {
        print("iOS camera permission denied");
        hasError.value = true;
        errorMessage.value = "Camera permission is required to scan QR codes.";
        isInitialized.value = false;
      }
    } catch (e) {
      print("iOS Camera initialization error: $e");
      hasError.value = true;
      errorMessage.value = "Failed to initialize camera: $e";
      isInitialized.value = false;
    }
  }

  // Android initialization - request permission explicitly
  Future<void> _initializeAndroidCamera() async {
    try {
      var status = await Permission.camera.status;
      print("Android Camera permission status: $status");

      // If denied, request permission
      if (status.isDenied) {
        status = await Permission.camera.request();
        print("Android Camera permission request result: $status");
      }

      // Check if permission was granted
      if (status.isGranted) {
        scannerController = MobileScannerController(
          autoStart: false,
          detectionSpeed: DetectionSpeed.normal,
          facing: CameraFacing.back,
          torchEnabled: false,
        );
        
        isInitialized.value = true;
        hasError.value = false;
        errorMessage.value = '';

        // Start the scanner after a delay
        await Future.delayed(Duration(milliseconds: 500));
        await scannerController?.start();
        
        print("Android Camera initialized successfully");
      } else if (status.isPermanentlyDenied) {
        print("Android camera permission permanently denied");
        hasError.value = true;
        errorMessage.value = "Camera permission is required. Please enable it in Settings.";
        isInitialized.value = false;
      } else {
        print("Android camera permission not granted");
        hasError.value = true;
        errorMessage.value = "Camera permission is required to scan QR codes.";
        isInitialized.value = false;
      }
    } catch (e) {
      print("Android Camera initialization error: $e");
      hasError.value = true;
      errorMessage.value = "Failed to initialize camera: $e";
      isInitialized.value = false;
    }
  }

  void handleBarcode(BarcodeCapture capture) {
    if (!isScanning.value || !isInitialized.value) return;

    if (capture.barcodes.isNotEmpty) {
      LoadingController.to.showLoading(message: 'Processing QR Code...');

      final scannedBarcode = capture.barcodes.first;
      barcode.value = scannedBarcode;
      qrCode.value = barcode.value?.displayValue ?? 'Invalid QR Code';
      checkStatus(qrCode.value);

      if (isApproved.value) {
        bookingId.value = qrCode.value;
      }

      LoadingController.to.hideLoading();

      showApprovalStatus.value = true;
      Future.delayed(const Duration(seconds: 2), () {
        showApprovalStatus.value = false;
      });
      isScanning.value = false;
    }
  }

  void checkStatus(String code) {
    if (code == '111') {
      isApproved.value = true;
    } else {
      isApproved.value = false;
    }
  }

  void resetForNextScan() {
    qrCode.value = '';
    bookingId.value = '';
    isApproved.value = false;
    showApprovalStatus.value = false;
    barcode.value = null;
  }

  void resetScanner() {
    resetForNextScan();
    isScanning.value = true;
  }

  void showBookingDetails() {
    Get.snackbar(
      'Booking Details',
      'Booking ID: ${bookingId.value}',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void toggleTorch() {
    scannerController?.toggleTorch();
  }

  // Method to retry permission after returning from settings
  Future<void> retryPermission() async {
    print("Retrying permission check");

    // Dispose old controller if exists
    if (scannerController != null) {
      await scannerController!.dispose();
      scannerController = null;
    }

    // Reset states
    isInitialized.value = false;
    hasError.value = false;
    errorMessage.value = '';

    // Reinitialize camera
    await _initializeCamera();
  }

  // Method to open settings
  Future<void> openSettings() async {
    await openAppSettings();
  }

  // Method to check if camera is available
  Future<bool> isCameraAvailable() async {
    try {
      if (Platform.isIOS) {
        var status = await Permission.camera.status;
        return status.isGranted;
      } else {
        var status = await Permission.camera.status;
        return status.isGranted;
      }
    } catch (e) {
      print("Error checking camera availability: $e");
      return false;
    }
  }

  // Method to restart scanner
  Future<void> restartScanner() async {
    if (scannerController != null) {
      await scannerController!.stop();
      await Future.delayed(Duration(milliseconds: 300));
      await scannerController!.start();
    }
  }

  @override
  void onClose() {
    scannerController?.dispose();
    super.onClose();
  }
}
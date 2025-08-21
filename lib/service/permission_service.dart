import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

class PermissionService {
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;
  PermissionService._internal();

  /// Check if storage permissions are granted
  Future<bool> hasStoragePermission() async {
    if (Platform.isAndroid) {
      if (await _isAndroid13OrHigher()) {
        // For Android 13+, we need READ_MEDIA_* permissions
        final photosStatus = await Permission.photos.status;
        final videosStatus = await Permission.videos.status;
        final audioStatus = await Permission.audio.status;

        return photosStatus.isGranted &&
            videosStatus.isGranted &&
            audioStatus.isGranted;
      } else {
        // For Android 12 and below, we need storage permissions
        final storageStatus = await Permission.storage.status;
        return storageStatus.isGranted;
      }
    }
    return true; // iOS doesn't need explicit storage permissions for app documents
  }

  /// Request storage permissions
  Future<bool> requestStoragePermission(BuildContext context) async {
    if (Platform.isAndroid) {
      if (await _isAndroid13OrHigher()) {
        // Request media permissions for Android 13+
        final photosStatus = await Permission.photos.request();
        final videosStatus = await Permission.videos.request();
        final audioStatus = await Permission.audio.request();

        if (!photosStatus.isGranted ||
            !videosStatus.isGranted ||
            !audioStatus.isGranted) {
          if (await arePermissionsPermanentlyDenied()) {
            showSettingsDialog(context);
          } else {
            _showPermissionDeniedDialog(context, 'Media Access');
          }
          return false;
        }
      } else {
        // Request storage permission for Android 12 and below
        final storageStatus = await Permission.storage.request();
        if (!storageStatus.isGranted) {
          if (await arePermissionsPermanentlyDenied()) {
            showSettingsDialog(context);
          } else {
            _showPermissionDeniedDialog(context, 'Storage');
          }
          return false;
        }
      }
    }
    return true;
  }

  /// Show permission explanation before requesting
  Future<bool> showPermissionExplanation(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  Icon(Icons.folder_open, color: Colors.blue, size: 28),
                  SizedBox(width: 12),
                  Text(
                    'Permission Required',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'This app needs access to your device storage to:',
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: 16),
                  _buildPermissionItem('• Generate and save PDF bills'),
                  _buildPermissionItem('• Store invoices for future reference'),
                  _buildPermissionItem('• Share bills with customers'),
                  SizedBox(height: 16),
                  Text(
                    'Your data is stored locally and never shared with third parties.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(
                    'Cancel',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text('Continue', style: TextStyle(fontSize: 16)),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  Widget _buildPermissionItem(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Text(text, style: TextStyle(fontSize: 14)),
    );
  }

  /// Check if Android version is 13 or higher (API 33+)
  Future<bool> _isAndroid13OrHigher() async {
    if (Platform.isAndroid) {
      try {
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        return androidInfo.version.sdkInt >= 33;
      } catch (e) {
        // Fallback to storage permission for older versions
        return false;
      }
    }
    return false;
  }

  /// Check if we should show permission rationale
  Future<bool> shouldShowPermissionRationale() async {
    if (Platform.isAndroid) {
      if (await _isAndroid13OrHigher()) {
        return await Permission.photos.shouldShowRequestRationale ||
            await Permission.videos.shouldShowRequestRationale ||
            await Permission.audio.shouldShowRequestRationale;
      } else {
        return await Permission.storage.shouldShowRequestRationale;
      }
    }
    return false;
  }

  /// Request storage permissions with rationale if needed
  Future<bool> requestStoragePermissionWithRationale(
    BuildContext context,
  ) async {
    if (Platform.isAndroid) {
      // Check if we should show rationale
      if (await shouldShowPermissionRationale()) {
        final shouldContinue = await showPermissionExplanation(context);
        if (!shouldContinue) {
          return false;
        }
      }

      return await requestStoragePermission(context);
    }
    return true;
  }

  /// Show dialog when permission is denied
  void _showPermissionDeniedDialog(
    BuildContext context,
    String permissionType,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
              SizedBox(width: 12),
              Text(
                'Permission Required',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$permissionType permission is required to generate and save PDF bills.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 16),
              Text(
                'Please grant the permission in your device settings to continue.',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text('Open Settings', style: TextStyle(fontSize: 16)),
            ),
          ],
        );
      },
    );
  }

  /// Show a simple permission denied snackbar
  void showPermissionDeniedSnackBar(
    BuildContext context,
    String permissionType,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.white),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                '$permissionType permission denied. Please grant permission in settings.',
              ),
            ),
          ],
        ),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        action: SnackBarAction(
          label: 'Settings',
          textColor: Colors.white,
          onPressed: () => openAppSettings(),
        ),
        duration: Duration(seconds: 5),
      ),
    );
  }

  /// Handle permission error and show appropriate message
  void handlePermissionError(BuildContext context, String error) {
    if (error.contains('permission')) {
      showPermissionDeniedSnackBar(context, 'Storage');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 12),
              Expanded(child: Text('Error: $error')),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: Duration(seconds: 4),
        ),
      );
    }
  }

  /// Check if permissions are permanently denied
  Future<bool> arePermissionsPermanentlyDenied() async {
    if (Platform.isAndroid) {
      if (await _isAndroid13OrHigher()) {
        return await Permission.photos.isPermanentlyDenied ||
            await Permission.videos.isPermanentlyDenied ||
            await Permission.audio.isPermanentlyDenied;
      } else {
        return await Permission.storage.isPermanentlyDenied;
      }
    }
    return false;
  }

  /// Show settings dialog for permanently denied permissions
  void showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(Icons.settings, color: Colors.orange, size: 28),
              SizedBox(width: 12),
              Text(
                'Permission Required',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Storage permissions have been permanently denied.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 16),
              Text(
                'To use PDF generation features, please enable storage permissions in your device settings.',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text('Open Settings', style: TextStyle(fontSize: 16)),
            ),
          ],
        );
      },
    );
  }

  /// Check if running on Android
  bool get isAndroid => Platform.isAndroid;

  /// Check if running on iOS
  bool get isIOS => Platform.isIOS;

  /// Get current permission status as a string
  Future<String> getPermissionStatusString() async {
    if (Platform.isAndroid) {
      if (await _isAndroid13OrHigher()) {
        final photosStatus = await Permission.photos.status;
        final videosStatus = await Permission.videos.status;
        final audioStatus = await Permission.audio.status;

        if (photosStatus.isGranted &&
            videosStatus.isGranted &&
            audioStatus.isGranted) {
          return 'Granted';
        } else if (photosStatus.isDenied ||
            videosStatus.isDenied ||
            audioStatus.isDenied) {
          return 'Denied';
        } else if (photosStatus.isPermanentlyDenied ||
            videosStatus.isPermanentlyDenied ||
            audioStatus.isPermanentlyDenied) {
          return 'Permanently Denied';
        } else {
          return 'Unknown';
        }
      } else {
        final storageStatus = await Permission.storage.status;
        return storageStatus.toString().split('.').last;
      }
    }
    return 'Not Applicable';
  }

  /// Request all required permissions at once
  Future<bool> requestAllPermissions(BuildContext context) async {
    if (Platform.isAndroid) {
      if (await _isAndroid13OrHigher()) {
        // Request all media permissions at once
        Map<Permission, PermissionStatus> statuses =
            await [
              Permission.photos,
              Permission.videos,
              Permission.audio,
            ].request();

        // Check if all permissions are granted
        bool allGranted = statuses.values.every((status) => status.isGranted);

        if (!allGranted) {
          // Check if any are permanently denied
          bool anyPermanentlyDenied = statuses.values.any(
            (status) => status.isPermanentlyDenied,
          );

          if (anyPermanentlyDenied) {
            showSettingsDialog(context);
          } else {
            _showPermissionDeniedDialog(context, 'Media Access');
          }
          return false;
        }
      } else {
        // Request storage permission
        final storageStatus = await Permission.storage.request();
        if (!storageStatus.isGranted) {
          if (await arePermissionsPermanentlyDenied()) {
            showSettingsDialog(context);
          } else {
            _showPermissionDeniedDialog(context, 'Storage');
          }
          return false;
        }
      }
    }
    return true;
  }

  /// Check if all required permissions are granted
  Future<bool> areAllPermissionsGranted() async {
    if (Platform.isAndroid) {
      if (await _isAndroid13OrHigher()) {
        final photosStatus = await Permission.photos.status;
        final videosStatus = await Permission.videos.status;
        final audioStatus = await Permission.audio.status;

        return photosStatus.isGranted &&
            videosStatus.isGranted &&
            audioStatus.isGranted;
      } else {
        final storageStatus = await Permission.storage.status;
        return storageStatus.isGranted;
      }
    }
    return true; // iOS doesn't need explicit storage permissions
  }
}

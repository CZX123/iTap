// import 'package:flutter/material.dart';
// import 'group_data.dart';
// import 'package:qr_mobile_vision/qr_camera.dart';
// import 'package:qr_mobile_vision/qr_mobile_vision.dart';

// class ScanCodePage extends StatelessWidget {
//   final GroupDetails groupDetails;
//   final void Function(
//     BuildContext context,
//     bool takenWithWifi,
//     String code,
//   ) takeAttendance;

//   const ScanCodePage({
//     Key key,
//     @required this.groupDetails,
//     @required this.takeAttendance,
//   }) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Scan Code for ${groupDetails.groupName}'),
//       ),
//       body: Center(
//         child: QrCamera(
//           notStartedBuilder: (context) {
//             return Icon(
//               Icons.camera_alt,
//               size: 64,
//               color: Theme.of(context).disabledColor,
//             );
//           },
//           formats: [BarcodeFormats.QR_CODE],
//           qrCodeCallback: (code) {
//             print(code);
//           },
//         ),
//       ),
//     );
//   }
// }

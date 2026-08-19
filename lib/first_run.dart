// import 'package:arabic_lexicons/data.dart';
import 'package:flutter/material.dart';
// import 'package:url_launcher/url_launcher.dart';

const String overViewURL =
    'https://wizsk.github.io/apps/arabic_lexicons.html#video';

// bool firstRunPopupShown = false;
// bool shouldShowFirstPopup() => !firstRunPopupShown && appConf.firstRun;

// Future<void> _showWatchVideoDialog(BuildContext context) async {
//   if (!shouldShowFirstPopup()) return;

//   firstRunPopupShown = true;

//   bool watched = false;
//   // const msg =
//   //     '⚠️ Please watch the walkthrough video to know how to use the app\n\n'
//   //     'Tap "Open" to start watching';

//   const msg =
//       // 'Thanks for downloading the app.\n\n'
//       '⚠️ Please watch the walkthrough video first.\n\n'
//       'It only takes a moment and will save you time by showing exactly how to use the app properly.\n\n'
//       'Tap "Open" to start watching.';

//   await showDialog(
//     barrierDismissible: false,
//     context: context,
//     builder: (ctx) {
//       return StatefulBuilder(
//         builder: (ctx, setState) {
//           return AlertDialog(
//             scrollable: true,
//             constraints: BoxConstraints(maxWidth: 600),
//             title: const Text('Welcome!'),
//             content: Column(
//               mainAxisSize: MainAxisSize.min,
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 const Text(msg),

//                 const SizedBox(height: 8),

//                 InkWell(
//                   onTap: () => setState(() => watched = !watched),
//                   child: Padding(
//                     padding: const EdgeInsets.symmetric(vertical: 12.0),
//                     // .copyWith(left: 8),
//                     child: Row(
//                       crossAxisAlignment: CrossAxisAlignment.center,
//                       children: [
//                         SizedBox(
//                           width: 18,
//                           height: 18,
//                           child: Checkbox(
//                             value: watched,
//                             onChanged: (val) {
//                               setState(() => watched = val ?? false);
//                             },
//                             materialTapTargetSize:
//                                 MaterialTapTargetSize.shrinkWrap,
//                             visualDensity: VisualDensity.compact,
//                           ),
//                         ),
//                         const SizedBox(width: 8),
//                         const Expanded(
//                           child: Text(
//                             'Yes, I have watched it',
//                             // style: TextStyle(fontSize: 14),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//             actions: [
//               TextButton(
//                 onPressed: () {
//                   Navigator.of(ctx).pop();
//                   if (watched) appConf.saveFirstRun(false);
//                 },
//                 child: const Text('Close'),
//               ),

//               FilledButton(
//                 onPressed: () {
//                   launchUrl(Uri.parse(overViewURL));
//                 },
//                 child: Text('Open'),
//               ),
//             ],
//           );
//         },
//       );
//     },
//   );
// }

Future<void> showFirstRunPopup(BuildContext context) async {}

// Future<void> showFirstRunPopup(BuildContext context) async {
//   if (!shouldShowFirstPopup()) return;
//   return _showWatchVideoDialog(context);
// }

void showFirstRunPopupPostFrame(BuildContext context) {}
// void showFirstRunPopupPostFrame(BuildContext context) {
//   if (!shouldShowFirstPopup()) return;

//   WidgetsBinding.instance.addPostFrameCallback((_) async {
//     showFirstRunPopup(context);
//   });
// }

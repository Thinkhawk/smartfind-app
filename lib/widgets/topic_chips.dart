// import 'package:flutter/material.dart';
//
// class TopicChips extends StatelessWidget {
//   const TopicChips({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     // TODO: Get topics from backend
//     final topics = ['Work', 'Personal', 'Research', 'Finance'];
//
//     return SizedBox(
//       height: 50,
//       child: ListView.builder(
//         scrollDirection: Axis.horizontal,
//         padding: const EdgeInsets.symmetric(horizontal: 16),
//         itemCount: topics.length,
//         itemBuilder: (context, index) {
//           return Padding(
//             padding: const EdgeInsets.only(right: 8),
//             child: FilterChip(
//               label: Text(topics[index]),
//               onSelected: (selected) {
//                 // TODO: Filter by topic
//               },
//             ),
//           );
//         },
//       ),
//     );
//   }
// }

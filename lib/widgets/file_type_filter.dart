// import 'package:flutter/material.dart';
//
// class FileTypeFilter extends StatelessWidget {
//   const FileTypeFilter({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     final fileTypes = [
//       {'label': 'All', 'icon': Icons.folder_open},
//       {'label': 'PDF', 'icon': Icons.picture_as_pdf},
//       {'label': 'Docs', 'icon': Icons.description},
//       {'label': 'Images', 'icon': Icons.image},
//       {'label': 'Sheets', 'icon': Icons.table_chart},
//     ];
//
//     return SizedBox(
//       height: 56,
//       child: ListView.builder(
//         scrollDirection: Axis.horizontal,
//         padding: const EdgeInsets.symmetric(horizontal: 16),
//         itemCount: fileTypes.length,
//         itemBuilder: (context, index) {
//           final type = fileTypes[index];
//           return Padding(
//             padding: const EdgeInsets.only(right: 8),
//             child: FilterChip(
//               avatar: Icon(type['icon'] as IconData, size: 18),
//               label: Text(type['label'] as String),
//               selected: index == 0, // Default 'All' selected
//               onSelected: (selected) {
//                 // TODO: Filter by type
//               },
//             ),
//           );
//         },
//       ),
//     );
//   }
// }

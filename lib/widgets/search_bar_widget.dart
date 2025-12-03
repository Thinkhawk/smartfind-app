// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../providers/search_provider.dart';
// import '../providers/file_provider.dart';
//
// class SearchBarWidget extends StatefulWidget {
//   const SearchBarWidget({super.key});
//
//   @override
//   State<SearchBarWidget> createState() => _SearchBarWidgetState();
// }
//
// class _SearchBarWidgetState extends State<SearchBarWidget> {
//   final TextEditingController _controller = TextEditingController();
//
//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.all(16),
//       child: TextField(
//         controller: _controller,
//         decoration: InputDecoration(
//           hintText: 'Search documents...',
//           prefixIcon: const Icon(Icons.search),
//           suffixIcon: _controller.text.isNotEmpty
//               ? IconButton(
//             icon: const Icon(Icons.clear),
//             onPressed: () {
//               _controller.clear();
//               context.read<SearchProvider>().clearSearch();
//             },
//           )
//               : null,
//           border: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(12),
//           ),
//         ),
//         onChanged: (value) {
//           final searchProvider = context.read<SearchProvider>();
//           final fileProvider = context.read<FileProvider>();
//           searchProvider.updateQuery(value);
//           searchProvider.search(fileProvider.documents);
//         },
//       ),
//     );
//   }
// }

// ignore_for_file: avoid_print

// tool/convert_json.dart
// Script to convert old JSON format to new format
import 'dart:convert';
import 'dart:io';

Future<void> main(List<String> args) async {
  if (args.length < 2) {
    print('Usage: dart tool/convert_json.dart <input_file> <output_file> [version]');
    print('Example: dart tool/convert_json.dart assets/data/database/SDA_Hymnal.json assets/data/database/SDA_Hymnal_new.json hymnal');
    exit(1);
  }

  final inputFile = args[0];
  final outputFile = args[1];
  final version = args.length > 2 ? args[2] : 'hymnal';

  print('Converting $inputFile to $outputFile...');
  
  final file = File(inputFile);
  if (!await file.exists()) {
    print('Error: Input file does not exist: $inputFile');
    exit(1);
  }

  final content = await file.readAsString();
  final jsonData = json.decode(content) as Map<String, dynamic>;
  
  // Check if it's already in new format
  if (jsonData.containsKey('hymns') || (jsonData is List)) {
    print('File appears to already be in new format');
    exit(0);
  }

  // Extract items from old format: resources.array[].item[]
  final List<dynamic> arrays = jsonData['resources']?['array'] ?? [];
  final List<String> items = [];
  
  for (var array in arrays) {
    if (array is Map<String, dynamic> && array['item'] != null) {
      final List<dynamic> itemList = array['item'];
      for (var item in itemList) {
        if (item is String) {
          items.add(item);
        }
      }
    }
  }

  // Convert to new format
  final List<Map<String, dynamic>> hymns = [];
  int hymnNumber = 1;
  
  // Process items in pairs (title, lyrics)
  for (int i = 0; i < items.length; i += 2) {
    final titleItem = items[i].trim();
    if (titleItem.isEmpty) continue;
    
    final lyricsItem = (i + 1 < items.length) ? items[i + 1].trim() : '';
    
    // Clean up title
    String title = titleItem
        .replaceAll(RegExp(r'^\d+\.\s*'), '')
        .replaceAll(RegExp(r'^\d+\s+'), '')
        .trim();
    
    if (title.isEmpty) {
      title = 'Hymn $hymnNumber';
    }
    
    String lyrics = lyricsItem.isNotEmpty ? lyricsItem : title;
    if (lyrics.contains('\\n')) {
      lyrics = lyrics.replaceAll('\\n', '\n');
    }
    
    // Generate placeholder sheet_music and audio paths
    final sheetMusic = <String>[
      '${hymnNumber}_1.png',
      if (lyrics.length > 500) '${hymnNumber}_2.png',
    ];
    
    final audio = 'audio/$hymnNumber.mp3';
    
    final hymn = <String, dynamic>{
      'number': hymnNumber++,
      'title': title,
      'lyrics': lyrics,
      if (version == 'hymnal') 'category': null,
      'sheet_music': sheetMusic,
      'audio': audio,
    };
    
    hymns.add(hymn);
  }
  
  // Create new format JSON
  final newJson = {
    'hymns': hymns,
    'version': version,
    'total': hymns.length,
  };
  
  // Write to output file
  final output = File(outputFile);
  const encoder = JsonEncoder.withIndent('  ');
  await output.writeAsString(encoder.convert(newJson));
  
  print('Conversion complete! Converted ${hymns.length} hymns.');
  print('Output written to: $outputFile');
}






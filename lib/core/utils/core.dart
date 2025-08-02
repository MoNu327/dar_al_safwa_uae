List<String> parseStringToList(String response) {
  return response
      .replaceAll(RegExp(r'[\[\]]'), '') // Remove square brackets
      .split(',') // Split by commas
      .map((e) => e.trim()) // Trim spaces
      .where((e) => e.isNotEmpty) // Remove empty values
      .toList();
}

String capitalizeFirstLetter(String text) {
  if (text.isEmpty) return text;
  return text[0].toUpperCase() + text.substring(1);
}

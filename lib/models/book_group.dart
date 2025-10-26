class BookGroup {
  String id; // unique identifier
  String name;
  Map<String, int> books; // e.g. { "Genesis": 50, "Exodus": 40 }

  BookGroup({required this.id, required this.name, required this.books});
}

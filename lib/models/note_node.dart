class NoteNode {
  final String title;
  final String path;
  final bool isDirectory;
  final List<NoteNode> children;

  NoteNode({
    required this.title,
    required this.path,
    required this.isDirectory,
    this.children = const [],
  });
}

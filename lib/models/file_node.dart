class FileNode {
  final String title;
  final String path;
  final bool isDirectory;
  final List<FileNode> children;

  FileNode({
    required this.title,
    required this.path,
    required this.isDirectory,
    this.children = const [],
  });
}

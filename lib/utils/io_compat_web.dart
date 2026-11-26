class Platform {
  static bool get isAndroid => false;
  static bool get isIOS => false;
  static bool get isWindows => false;
  static bool get isMacOS => false;
  static bool get isLinux => false;
  static String get pathSeparator => '/';
  static String get resolvedExecutable => '';
}

class Directory {
  final String path;
  Directory(this.path);
  Future<bool> exists() async => false;
  Future<Directory> create({bool recursive = false}) async => this;
}

class File {
  final String path;
  File(this.path);
  bool existsSync() => false;
  Future<bool> exists() async => false;
  Future<String> readAsString() async => '';
  Future<File> writeAsString(String contents) async => this;
  Future<File> writeAsBytes(List<int> bytes) async => this;
}

class Process {
  Future<int> get exitCode async => 0;
  bool kill() => true;
  static Future<Process> start(String executable, List<String> arguments,
      {bool runInShell = false}) async {
    return Process();
  }
}

void exit(int code) {}

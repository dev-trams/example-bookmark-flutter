import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const App());
}

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => BookmarkProvider(),
      child: const MaterialApp(
        home: BookmarkPage(),
      ),
    );
  }
}

//UI
class BookmarkPage extends StatefulWidget {
  const BookmarkPage({super.key});

  @override
  State<BookmarkPage> createState() => _BookmarkPageState();
}

class _BookmarkPageState extends State<BookmarkPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<BookmarkProvider>(
        builder: (context, value, child) {
          return ListView.builder(
            itemCount: value.bookmarks.length,
            itemBuilder: (context, index) {
              final bookmark = value.bookmarks[index];
              return ListTile(
                title: Text(bookmark.title),
                leading: Checkbox(
                    value: bookmark.checked,
                    onChanged: (checked) => value.changeBookmarkChecked(
                        bookmark.id, !bookmark.checked)),
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    value.removeBookmark(bookmark.id);
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final bookmark = BookMark(
            id: DateTime.now().toString(),
            title: '북마크 ${DateTime.now()}',
            checked: false,
          );
          Provider.of<BookmarkProvider>(context, listen: false)
              .addBookmark(bookmark);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

//Provider Controller
class BookmarkProvider with ChangeNotifier {
  List<BookMark> _bookmarks = [];

  List<BookMark> get bookmarks => _bookmarks;

  BookmarkProvider() {
    loadBookmarks();
  }

  void saveBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    final String encodeData = json.encode(_bookmarks
        .map((e) => {'id': e.id, 'title': e.title, 'checked': e.checked})
        .toList());
    prefs.setString('bookmarks', encodeData);
  }

  void loadBookmarks() async {
    print('저장된 데이터 수집 시작');
    final prefs = await SharedPreferences.getInstance();
    print('prefs instance 수집: $prefs');
    final String? bookmarksString = prefs.getString('bookmarks');
    print('bookmarksString 수집: $bookmarksString');
    if (bookmarksString != null) {
      final List<dynamic> bookmarkJson = json.decode(bookmarksString);
      _bookmarks = bookmarkJson
          .map((e) => BookMark(
                id: e['id'],
                title: e['title'],
                checked: e['checked'],
              ))
          .toList();
      notifyListeners();
      print('저장된 데이터 통합 종료');
    }
  }

  void addBookmark(BookMark bookMark) {
    _bookmarks.add(bookMark);
    saveBookmarks();
    notifyListeners();
  }

  void changeBookmarkChecked(String id, bool checked) {
    final bookmarkIndex = _bookmarks.indexWhere((element) => element.id == id);
    final bookmarkTitle =
        _bookmarks.where((element) => element.id == id).first.title;
    if (bookmarkIndex != -1) {
      _bookmarks[bookmarkIndex] =
          BookMark(id: id, title: bookmarkTitle, checked: checked);
      saveBookmarks();

      notifyListeners();
    }
  }

  void removeBookmark(String id) {
    _bookmarks.removeWhere((bookmark) => bookmark.id == id);
    saveBookmarks();
    notifyListeners();
  }
}

// 데이터 모델
class BookMark {
  final String id;
  final String title;
  final bool checked;
  BookMark({required this.id, required this.title, required this.checked});
}

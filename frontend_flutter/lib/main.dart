import 'dart:async';
import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'package:flutter/material.dart';

void main() {
  runApp(const BookSpaceApp());
}

class Book {
  const Book({
    this.id,
    this.readingListId,
    this.userId,
    this.progress = 0,
    this.readingStatus = 'to_read',
    required this.title,
    required this.author,
    required this.year,
    required this.rating,
    required this.genre,
    required this.imageUrl,
    this.description,
  });

  final int? id;
  final int? readingListId;
  final String? userId;
  final int progress;
  final String readingStatus;
  final String title;
  final String author;
  final String year;
  final double rating;
  final String genre;
  final String imageUrl;
  final String? description;

  Map<String, dynamic> toJson() => {
        'id': id,
        'readingListId': readingListId,
        'userId': userId,
        'progress': progress,
        'readingStatus': readingStatus,
        'title': title,
        'author': author,
        'year': year,
        'rating': rating,
        'genre': genre,
        'imageUrl': imageUrl,
        'description': description,
      };

  factory Book.fromJson(Map<String, dynamic> json) => Book(
        id: _readInt(json['id']),
        readingListId: _readInt(json['readingListId'] ?? json['reading_list_id']),
        userId: json['userId'] as String? ?? json['user_id'] as String?,
        progress: _readInt(json['progress']) ?? 0,
        readingStatus: (json['readingStatus'] ?? json['reading_status'] ?? 'to_read') as String,
        title: json['title'] as String,
        author: json['author'] as String,
        year: (json['year'] ?? '') as String,
        rating: _readRating(json['rating']),
        genre: json['genre'] as String? ?? 'All',
        imageUrl: (json['imageUrl'] ?? json['image_url'] ?? json['img'] ?? '') as String,
        description: json['description'] as String?,
      );

  Book copyWith({
    int? id,
    int? readingListId,
    String? userId,
    int? progress,
    String? readingStatus,
    String? title,
    String? author,
    String? year,
    double? rating,
    String? genre,
    String? imageUrl,
    String? description,
  }) {
    return Book(
      id: id ?? this.id,
      readingListId: readingListId ?? this.readingListId,
      userId: userId ?? this.userId,
      progress: progress ?? this.progress,
      readingStatus: readingStatus ?? this.readingStatus,
      title: title ?? this.title,
      author: author ?? this.author,
      year: year ?? this.year,
      rating: rating ?? this.rating,
      genre: genre ?? this.genre,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
    );
  }
}

class BookReview {
  const BookReview({
    this.id,
    this.bookId,
    this.bookTitle,
    required this.user,
    required this.stars,
    required this.text,
  });

  final int? id;
  final int? bookId;
  final String? bookTitle;
  final String user;
  final int stars;
  final String text;

  Map<String, dynamic> toJson() => {
        'id': id,
        'bookId': bookId,
        'bookTitle': bookTitle,
        'user': user,
        'stars': stars,
        'text': text,
      };

  factory BookReview.fromJson(Map<String, dynamic> json) => BookReview(
        id: _readInt(json['id']),
        bookId: _readInt(json['bookId'] ?? json['book_id']),
        bookTitle: json['bookTitle'] as String? ?? json['book_title'] as String?,
        user: (json['user'] ?? json['user_id'] ?? '') as String,
        stars: _readStars(json['stars'] ?? json['rating']),
        text: (json['text'] ?? json['content'] ?? '') as String,
      );

  BookReview copyWith({
    int? id,
    int? bookId,
    String? bookTitle,
    String? user,
    int? stars,
    String? text,
  }) {
    return BookReview(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      bookTitle: bookTitle ?? this.bookTitle,
      user: user ?? this.user,
      stars: stars ?? this.stars,
      text: text ?? this.text,
    );
  }
}

enum BookSection { home, toRead, myBooks, highest, newBooks, genre, login, signup, reset }

const authApiBase = 'http://127.0.0.1:8000';
const bookApiBase = 'http://127.0.0.1:8001';

class BookSpaceApp extends StatefulWidget {
  const BookSpaceApp({super.key});

  @override
  State<BookSpaceApp> createState() => _BookSpaceAppState();
}

class _BookSpaceAppState extends State<BookSpaceApp> {
  bool _darkMode = false;

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF6C5CE7);

    return MaterialApp(
      title: 'BookSpace',
      debugShowCheckedModeBanner: false,
      themeMode: _darkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: seed),
        scaffoldBackgroundColor: const Color(0xFFF5F6FA),
        fontFamily: 'Arial',
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: seed,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF121417),
        fontFamily: 'Arial',
      ),
      home: BookSpaceHome(
        darkMode: _darkMode,
        onToggleTheme: () => setState(() => _darkMode = !_darkMode),
      ),
    );
  }
}

class BookSpaceHome extends StatefulWidget {
  const BookSpaceHome({
    required this.darkMode,
    required this.onToggleTheme,
    super.key,
  });

  final bool darkMode;
  final VoidCallback onToggleTheme;

  @override
  State<BookSpaceHome> createState() => _BookSpaceHomeState();
}

class _BookSpaceHomeState extends State<BookSpaceHome> {
  BookSection _section = BookSection.home;
  String _search = '';
  String _genre = 'All';
  String _currentUser = html.window.localStorage['currentUser'] ?? '';
  bool _loggedIn = html.window.localStorage['token'] != null;
  Map<String, List<Book>> _myBooks = {};
  Map<String, List<Book>> _toReadBooks = {};
  List<Book> _catalogBooks = [];
  Map<String, List<BookReview>> _reviews = {};

  final _loginUsername = TextEditingController();
  final _loginPassword = TextEditingController();
  final _signupUsername = TextEditingController();
  final _signupEmail = TextEditingController();
  final _signupPassword = TextEditingController();
  final _resetUsername = TextEditingController();
  final _resetPassword = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadLocalState();
    final saved = html.window.localStorage['activeSection'];
    if (saved != null) {
      _section = BookSection.values.firstWhere(
        (item) => item.name == saved,
        orElse: () => BookSection.home,
      );
    }
    if (_loggedIn) {
      unawaited(_loadRemoteLibrary());
    }
  }

  @override
  void dispose() {
    _loginUsername.dispose();
    _loginPassword.dispose();
    _signupUsername.dispose();
    _signupEmail.dispose();
    _signupPassword.dispose();
    _resetUsername.dispose();
    _resetPassword.dispose();
    super.dispose();
  }

  void _loadLocalState() {
    final savedBooks = jsonDecode(html.window.localStorage['myBooks'] ?? '{}')
        as Map<String, dynamic>;
    final savedToRead = jsonDecode(html.window.localStorage['toReadBooks'] ?? '{}')
        as Map<String, dynamic>;
    final savedCatalog = jsonDecode(html.window.localStorage['catalogBooks'] ?? '[]')
        as List<dynamic>;
    final savedReviews = jsonDecode(html.window.localStorage['reviews'] ?? '{}')
        as Map<String, dynamic>;

    _myBooks = savedBooks.map(
      (user, books) => MapEntry(
        user,
        (books as List<dynamic>)
            .map((book) => Book.fromJson(book as Map<String, dynamic>))
            .toList(),
      ),
    );
    _reviews = savedReviews.map(
      (title, reviews) => MapEntry(
        title,
        (reviews as List<dynamic>)
            .map((review) => BookReview.fromJson(review as Map<String, dynamic>))
            .toList(),
      ),
    );
    _toReadBooks = savedToRead.map(
      (user, books) => MapEntry(
        user,
        (books as List<dynamic>)
            .map((book) => Book.fromJson(book as Map<String, dynamic>))
            .toList(),
      ),
    );
    _catalogBooks = savedCatalog
        .map((book) => Book.fromJson(book as Map<String, dynamic>))
        .toList();
  }

  void _persistMyBooks() {
    html.window.localStorage['myBooks'] = jsonEncode(_myBooks);
  }

  void _persistReviews() {
    html.window.localStorage['reviews'] = jsonEncode(_reviews);
  }

  void _persistToReadBooks() {
    html.window.localStorage['toReadBooks'] = jsonEncode(_toReadBooks);
  }

  void _persistCatalogBooks() {
    html.window.localStorage['catalogBooks'] = jsonEncode(_catalogBooks);
  }

  String? get _token => html.window.localStorage['token'];

  List<Book> get _allCatalogBooks =>
      _uniqueBooks([...trendingBooks, ...highestRatedBooks, ...newBooks, ..._catalogBooks]);

  List<BookReview> _reviewsForBook(Book book) => _reviews[book.title] ?? const [];

  int _reviewCount(Book book) => _reviewsForBook(book).length;

  double _bookRating(Book book) {
    final reviews = _reviewsForBook(book);
    if (reviews.isEmpty) {
      return 0;
    }
    final sum = reviews.fold<int>(0, (total, review) => total + review.stars);
    return sum / reviews.length;
  }

  List<Book> get _highestRatedRanking {
    final books = [..._allCatalogBooks];
    books.sort((a, b) {
      final score = _bookRating(b).compareTo(_bookRating(a));
      if (score != 0) {
        return score;
      }
      return _reviewCount(b).compareTo(_reviewCount(a));
    });
    return books.take(10).toList();
  }

  List<Book> get _newBooks2026 =>
      _allCatalogBooks.where((book) => book.year.trim() == '2026').toList();

  void _showSection(BookSection section) {
    setState(() => _section = section);
    html.window.localStorage['activeSection'] = section.name;
  }

  List<Book> _filterBooks(List<Book> books) {
    final query = _search.trim().toLowerCase();
    if (query.isEmpty) {
      return books;
    }

    return books.where((book) {
      final text = '${book.title} ${book.author} ${book.year} ${book.genre}'
          .toLowerCase();
      return text.contains(query);
    }).toList();
  }

  Future<void> _postJson({
    required String url,
    required Map<String, dynamic> body,
    required void Function(Map<String, dynamic> data) onSuccess,
    required String successMessage,
    required String fallbackError,
  }) async {
    try {
      final response = await html.HttpRequest.request(
        url,
        method: 'POST',
        requestHeaders: {'Content-Type': 'application/json'},
        sendData: jsonEncode(body),
      );
      final data = response.responseText?.isNotEmpty == true
          ? jsonDecode(response.responseText!) as Map<String, dynamic>
          : <String, dynamic>{};

      if ((response.status ?? 0) < 200 || (response.status ?? 0) >= 300) {
        _snack((data['detail'] as String?) ?? fallbackError, error: true);
        return;
      }

      onSuccess(data);
      _snack(successMessage);
    } on html.ProgressEvent catch (_) {
      _snack(fallbackError, error: true);
    } catch (_) {
      _snack('Server error', error: true);
    }
  }

  Future<dynamic> _requestJson(
    String url, {
    String method = 'GET',
    Map<String, dynamic>? body,
    bool auth = false,
  }) async {
    try {
      final headers = <String, String>{};
      if (body != null) {
        headers['Content-Type'] = 'application/json';
      }
      if (auth && _token != null) {
        headers['Authorization'] = 'Bearer $_token';
      }

      final response = await html.HttpRequest.request(
        url,
        method: method,
        requestHeaders: headers,
        sendData: body == null ? null : jsonEncode(body),
      );
      final data = response.responseText?.isNotEmpty == true
          ? jsonDecode(response.responseText!)
          : null;
      if ((response.status ?? 0) < 200 || (response.status ?? 0) >= 300) {
        if (data is Map<String, dynamic>) {
          throw Exception(_errorMessage(data, 'Request failed'));
        }
        throw Exception('Request failed');
      }
      return data;
    } on html.ProgressEvent catch (_) {
      throw Exception('Book Service is offline. Start backend on http://127.0.0.1:8001.');
    } on FormatException {
      throw Exception('Invalid server response');
    }
  }

  String _errorMessage(Map<String, dynamic> data, String fallback) {
    final detail = data['detail'];
    if (detail is String) {
      return detail;
    }
    if (detail is Map<String, dynamic>) {
      return (detail['message'] as String?) ?? fallback;
    }
    return fallback;
  }

  Future<void> _loadRemoteLibrary() async {
    if (!_loggedIn || _currentUser.isEmpty) {
      return;
    }
    try {
      final readData = await _requestJson(
        '$bookApiBase/books?user=${Uri.encodeComponent(_currentUser)}&status=read',
      );
      final toReadData = await _requestJson('$bookApiBase/reading-list', auth: true);
      final catalogData = await _requestJson('$bookApiBase/books?status=catalog');
      dynamic reviewData;
      try {
        reviewData = await _requestJson('$bookApiBase/reviews');
      } catch (_) {}

      setState(() {
        if (readData is List<dynamic>) {
          _myBooks[_currentUser] = readData
              .map((item) => Book.fromJson(item as Map<String, dynamic>))
              .toList();
        }
        if (toReadData is List<dynamic>) {
          _toReadBooks[_currentUser] = toReadData
              .map((item) => Book.fromJson(item as Map<String, dynamic>))
              .toList();
        }
        if (catalogData is List<dynamic>) {
          _catalogBooks = catalogData
              .map((item) => Book.fromJson(item as Map<String, dynamic>))
              .toList();
        }
        if (reviewData is List<dynamic>) {
          final nextReviews = <String, List<BookReview>>{};
          for (final item in reviewData) {
            final review = BookReview.fromJson(item as Map<String, dynamic>);
            final title = review.bookTitle;
            if (title != null && title.isNotEmpty) {
              nextReviews.putIfAbsent(title, () => []).add(review);
            }
          }
          _reviews = {..._reviews, ...nextReviews};
        }
      });
      _persistMyBooks();
      _persistToReadBooks();
      _persistCatalogBooks();
      _persistReviews();
    } catch (_) {}
  }

  Future<void> _login() async {
    final username = _loginUsername.text.trim();
    final password = _loginPassword.text;

    await _postJson(
      url: '$authApiBase/auth/login',
      body: {'username': username, 'password': password},
      successMessage: 'Logged in',
      fallbackError: 'Wrong login',
      onSuccess: (data) {
        html.window.localStorage['token'] = data['access_token'] as String;
        html.window.localStorage['currentUser'] = username;
        setState(() {
          _loggedIn = true;
          _currentUser = username;
          _loginUsername.clear();
          _loginPassword.clear();
          _section = BookSection.home;
        });
        unawaited(_loadRemoteLibrary());
      },
    );
  }

  Future<void> _register() async {
    await _postJson(
      url: '$authApiBase/auth/register',
      body: {
        'username': _signupUsername.text.trim(),
        'email': _signupEmail.text.trim(),
        'password': _signupPassword.text,
      },
      successMessage: 'Account created',
      fallbackError: 'Registration failed',
      onSuccess: (_) {
        setState(() {
          _signupUsername.clear();
          _signupEmail.clear();
          _signupPassword.clear();
          _section = BookSection.login;
        });
      },
    );
  }

  Future<void> _resetUserPassword() async {
    await _postJson(
      url: '$authApiBase/auth/reset-password',
      body: {
        'username': _resetUsername.text.trim(),
        'new_password': _resetPassword.text,
      },
      successMessage: 'Password changed',
      fallbackError: 'Reset failed',
      onSuccess: (_) {
        setState(() {
          _resetUsername.clear();
          _resetPassword.clear();
          _section = BookSection.login;
        });
      },
    );
  }

  void _logout() {
    html.window.localStorage.remove('token');
    html.window.localStorage.remove('currentUser');
    setState(() {
      _loggedIn = false;
      _currentUser = '';
      _section = BookSection.home;
    });
    _snack('Logged out');
  }

  Map<String, dynamic> _bookPayload(Book book) => {
        'title': book.title,
        'author': book.author,
        'description': book.description,
        'year': book.year,
        'rating': 0,
        'genre': book.genre,
        'image_url': book.imageUrl,
        'status': 'read',
      };

  Future<Book> _ensureRemoteBook(Book book, {String status = 'read'}) async {
    final payload = _bookPayload(book);
    payload['status'] = status;
    final data = await _requestJson(
      '$bookApiBase/books',
      method: 'POST',
      auth: true,
      body: payload,
    );
    return Book.fromJson(data as Map<String, dynamic>);
  }

  Future<void> _addToMyBooks(Book book) async {
    if (!_loggedIn) {
      _snack('Login to save books', error: true);
      return;
    }

    final books = _myBooks.putIfAbsent(_currentUser, () => []);
    if (books.any((saved) => saved.title == book.title)) {
      _snack('Already in your library', error: true);
      return;
    }

    try {
      final saved = await _ensureRemoteBook(book, status: 'read');
      setState(() => books.add(saved));
      _persistMyBooks();
      _snack('Added to My Read Books');
    } catch (error) {
      final msg = error.toString().replaceFirst('Exception: ', '');
      setState(() => books.add(book.copyWith(progress: 100, readingStatus: 'read')));
      _persistMyBooks();
      _snack(msg.startsWith('Book Service is offline')
          ? 'Saved locally because Book Service is offline.'
          : msg, error: true);
    }
  }

  Future<void> _removeFromMyBooks(Book book) async {
    final books = _myBooks[_currentUser];
    if (books == null) {
      return;
    }

    setState(() {
      books.removeWhere((saved) => saved.title == book.title);
    });
    _persistMyBooks();
    if (!_loggedIn) {
      _snack('Moved back to unread');
      return;
    }
    final toRead = _toReadBooks.putIfAbsent(_currentUser, () => []);
    final fallback = book.copyWith(progress: 0, readingStatus: 'to_read');
    if (!toRead.any((item) => item.title == book.title)) {
      setState(() => toRead.add(fallback));
      _persistToReadBooks();
    }
    try {
      final remote = await _ensureRemoteBook(book, status: 'to_read');
      final data = await _requestJson(
        '$bookApiBase/reading-list',
        method: 'POST',
        auth: true,
        body: {'book_id': remote.id, 'progress': 0, 'status': 'to_read'},
      );
      final item = Book.fromJson(data as Map<String, dynamic>);
      setState(() {
        final idx = toRead.indexWhere((i) => i.title == book.title);
        if (idx != -1) {
          toRead[idx] = item;
        }
      });
      _persistToReadBooks();
    } catch (_) {}
    _snack('Moved back to To Read');
  }

  Future<void> _addToRead(Book book) async {
    if (!_loggedIn) {
      _snack('Login to save books', error: true);
      return;
    }
    final books = _toReadBooks.putIfAbsent(_currentUser, () => []);
    if (books.any((saved) => saved.title == book.title)) {
      _snack('Already in To Read', error: true);
      return;
    }
    try {
      final remote = await _ensureRemoteBook(book, status: 'to_read');
      final data = await _requestJson(
        '$bookApiBase/reading-list',
        method: 'POST',
        auth: true,
        body: {'book_id': remote.id, 'progress': 0, 'status': 'to_read'},
      );
      setState(() => books.add(Book.fromJson(data as Map<String, dynamic>)));
      _persistToReadBooks();
      _snack('Added to To Read');
    } catch (error) {
      final msg = error.toString().replaceFirst('Exception: ', '');
      setState(() => books.add(book.copyWith(progress: 0, readingStatus: 'to_read')));
      _persistToReadBooks();
      _snack(msg.startsWith('Book Service is offline')
          ? 'Saved locally because Book Service is offline.'
          : msg, error: true);
    }
  }

  Future<void> _updateReadingProgress(Book book, int progress) async {
    final listId = book.readingListId;
    setState(() {
      final books = _toReadBooks[_currentUser] ?? [];
      final idx = books.indexWhere((item) =>
          (listId != null && item.readingListId == listId) ||
          (listId == null && item.title == book.title));
      if (idx != -1) {
        books[idx] = books[idx].copyWith(
          progress: progress,
          readingStatus: progress > 0 ? 'started' : 'to_read',
        );
      }
    });
    _persistToReadBooks();
    if (listId == null || book.id == null) {
      return;
    }
    try {
      await _requestJson(
        '$bookApiBase/reading-list/$listId',
        method: 'PUT',
        auth: true,
        body: {'book_id': book.id, 'progress': progress, 'status': progress > 0 ? 'started' : 'to_read'},
      );
    } catch (_) {}
  }

  Future<void> _markAlreadyRead(Book book) async {
    final readBooks = _myBooks.putIfAbsent(_currentUser, () => []);
    final toReadBooks = _toReadBooks.putIfAbsent(_currentUser, () => []);
    setState(() {
      if (!readBooks.any((saved) => saved.title == book.title)) {
        readBooks.add(book.copyWith(progress: 100, readingStatus: 'read'));
      }
      toReadBooks.removeWhere((item) =>
          item.readingListId == book.readingListId ||
          (book.readingListId == null && item.title == book.title));
    });
    _persistMyBooks();
    _persistToReadBooks();
    try {
      final readBook = await _ensureRemoteBook(book.copyWith(progress: 100, readingStatus: 'read'), status: 'read');
      if (book.readingListId != null) {
        await _requestJson('$bookApiBase/reading-list/${book.readingListId}', method: 'DELETE', auth: true);
      }
      setState(() {
        final idx = readBooks.indexWhere((b) => b.title == readBook.title);
        if (idx != -1) {
          readBooks[idx] = readBook.copyWith(progress: 100, readingStatus: 'read');
        }
      });
      _persistMyBooks();
    } catch (_) {}
    _snack('Moved to My Read Books');
  }

  Future<void> _saveReview(Book book, int stars, String text, {BookReview? existing}) async {
    if (!_loggedIn) {
      _snack('Login first', error: true);
      return;
    }
    try {
      final saved = await _ensureRemoteBook(book);
      if (saved.id == null) {
        _snack('Book is not saved in API', error: true);
        return;
      }
      final data = await _requestJson(
        existing?.id == null ? '$bookApiBase/reviews' : '$bookApiBase/reviews/${existing!.id}',
        method: existing?.id == null ? 'POST' : 'PUT',
        auth: true,
        body: {'book_id': saved.id, 'rating': stars, 'content': text},
      );
      final review = BookReview.fromJson(data as Map<String, dynamic>);
      final list = _reviews.putIfAbsent(book.title, () => []);
      setState(() {
        final idx = list.indexWhere((item) => item.id == existing?.id);
        if (idx == -1) {
          list.add(review);
        } else {
          list[idx] = review;
        }
      });
      _persistReviews();
      _snack(existing == null ? 'Review added' : 'Review updated');
    } catch (error) {
      _snack(error.toString().replaceFirst('Exception: ', ''), error: true);
    }
  }

  Future<void> _deleteReview(Book book, BookReview review) async {
    try {
      if (review.id != null) {
        await _requestJson('$bookApiBase/reviews/${review.id}', method: 'DELETE', auth: true);
      }
      final list = _reviews.putIfAbsent(book.title, () => []);
      setState(() => list.removeWhere((item) => item.id == review.id || item.text == review.text));
      _persistReviews();
      _snack('Review deleted');
    } catch (error) {
      _snack(error.toString().replaceFirst('Exception: ', ''), error: true);
    }
  }

  void _snack(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? const Color(0xFFD63031) : const Color(0xFF00B894),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = switch (_section) {
      BookSection.home => _homeView(),
      BookSection.toRead => _toReadView(),
      BookSection.myBooks => _myBooksView(),
      BookSection.highest => _bookGridView(
          title: 'Highest Rated Books Ranking',
          books: _highestRatedRanking,
        ),
      BookSection.newBooks => _bookGridView(
          title: 'New Books (2026)',
          books: _newBooks2026,
        ),
      BookSection.genre => _bookGridView(
          title: '$_genre Books',
          books: _genre == 'All'
              ? _allCatalogBooks
              : _allCatalogBooks.where((book) => book.genre == _genre).toList(),
        ),
      BookSection.login => _authCard(
          title: 'Welcome back',
          fields: [
            _field(_loginUsername, 'Username', Icons.person_outline),
            _field(_loginPassword, 'Password', Icons.lock_outline, obscure: true),
          ],
          action: 'Login',
          onAction: _login,
          secondary: TextButton(
            onPressed: () => _showSection(BookSection.reset),
            child: const Text('Forgot password?'),
          ),
        ),
      BookSection.signup => _authCard(
          title: 'Create account',
          fields: [
            _field(_signupUsername, 'Username', Icons.person_outline),
            _field(_signupEmail, 'Email', Icons.mail_outline),
            _field(_signupPassword, 'Password', Icons.lock_outline, obscure: true),
          ],
          action: 'Sign Up',
          onAction: _register,
          secondary: TextButton(
            onPressed: () => _showSection(BookSection.login),
            child: const Text('Already have an account? Login'),
          ),
        ),
      BookSection.reset => _authCard(
          title: 'Reset Password',
          fields: [
            _field(_resetUsername, 'Username', Icons.person_outline),
            _field(_resetPassword, 'New password', Icons.lock_reset, obscure: true),
          ],
          action: 'Reset password',
          onAction: _resetUserPassword,
          secondary: TextButton.icon(
            onPressed: () => _showSection(BookSection.login),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Back to login'),
          ),
        ),
    };

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 88,
        titleSpacing: 24,
        title: Wrap(
          spacing: 16,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _brand(),
            _navButton('Home', Icons.home_outlined, BookSection.home),
            _navButton('To Read', Icons.bookmark_border, BookSection.toRead),
            _navButton('My Read Books', Icons.menu_book_outlined, BookSection.myBooks),
            _navButton('Highest Rated', Icons.star_outline, BookSection.highest),
            _navButton('New', Icons.local_fire_department_outlined, BookSection.newBooks),
            _genreMenu(),
            if (_loggedIn)
              FilledButton.icon(
                onPressed: () => _showBookFormDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Add Book'),
              ),
          ],
        ),
        actions: [
          SizedBox(
            width: 260,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: SearchBar(
                leading: const Icon(Icons.search),
                hintText: 'Search books...',
                onChanged: (value) => setState(() => _search = value),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Toggle dark mode',
            onPressed: widget.onToggleTheme,
            icon: Icon(widget.darkMode ? Icons.light_mode : Icons.dark_mode),
          ),
          if (_loggedIn)
            TextButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
            )
          else ...[
            TextButton(
              onPressed: () => _showSection(BookSection.login),
              child: const Text('Login'),
            ),
            FilledButton.tonal(
              onPressed: () => _showSection(BookSection.signup),
              child: const Text('Sign Up'),
            ),
          ],
          const SizedBox(width: 16),
        ],
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: content,
        ),
      ),
    );
  }

  Widget _brand() {
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        colors: [Color(0xFF6C5CE7), Color(0xFF00CEC9)],
      ).createShader(bounds),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_stories, color: Colors.white),
          SizedBox(width: 8),
          Text(
            'BookSpace',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 28,
            ),
          ),
        ],
      ),
    );
  }

  Widget _navButton(String label, IconData icon, BookSection section) {
    final selected = _section == section;
    return TextButton.icon(
      onPressed: () => _showSection(section),
      icon: Icon(icon, size: 19),
      label: Text(label),
      style: TextButton.styleFrom(
        foregroundColor: selected ? const Color(0xFF6C5CE7) : null,
      ),
    );
  }

  Widget _genreMenu() {
    return PopupMenuButton<String>(
      tooltip: 'Genre',
      onSelected: (genre) {
        setState(() {
          _genre = genre;
          _section = BookSection.genre;
        });
      },
      itemBuilder: (context) => genres
          .map((genre) => PopupMenuItem(
                value: genre,
                child: Text(genre),
              ))
          .toList(),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.category_outlined),
            SizedBox(width: 8),
            Text('Genre'),
          ],
        ),
      ),
    );
  }

  Widget _homeView() {
    return SingleChildScrollView(
      key: const ValueKey('home'),
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6C5CE7), Color(0xFF00CEC9)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final narrow = constraints.maxWidth < 720;
                return Flex(
                  direction: narrow ? Axis.vertical : Axis.horizontal,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Find your next adventure',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 42,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Discover amazing books and track your reading',
                            style: TextStyle(color: Colors.white, fontSize: 18),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: narrow ? 0 : 24, height: narrow ? 28 : 0),
                    _heroCovers(),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Trending Books!',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 18),
          _booksWrap(_filterBooks(_allCatalogBooks)),
        ],
      ),
    );
  }

  Widget _heroCovers() {
    return SizedBox(
      width: 280,
      height: 180,
      child: Stack(
        children: [
          for (var i = 0; i < 5; i++)
            Positioned(
              left: 28.0 + i * 38,
              top: i.isEven ? 0 : 18,
              child: Transform.rotate(
                angle: (i - 2) * 0.08,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    trendingBooks[i].imageUrl,
                    width: 86,
                    height: 132,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _coverFallback(),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _bookGridView({required String title, required List<Book> books}) {
    return SingleChildScrollView(
      key: ValueKey(title),
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
          const SizedBox(height: 18),
          _booksWrap(_filterBooks(books)),
        ],
      ),
    );
  }

  Widget _toReadView() {
    if (!_loggedIn) {
      return Center(
        key: const ValueKey('to-read-logged-out'),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.local_library_outlined, size: 56),
                  const SizedBox(height: 16),
                  const Text(
                    'Your reading list is waiting',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Login to plan what you want to read next.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: () => _showSection(BookSection.login),
                    child: const Text('Login to continue'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final books = _filterBooks(_toReadBooks[_currentUser] ?? []);
    return SingleChildScrollView(
      key: const ValueKey('to-read'),
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('To Read', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
          const SizedBox(height: 18),
          if (books.isEmpty)
            const Text('No books in your reading list yet.')
          else
            Wrap(
              spacing: 20,
              runSpacing: 20,
              children: books
                  .map<Widget>(
                    (book) => ToReadCard(
                      book: book,
                      onTap: () => _showBookDialog(book),
                      onProgressChanged: (value) {
                        unawaited(_updateReadingProgress(book, value.round()));
                      },
                      onAlreadyRead: () => unawaited(_markAlreadyRead(book)),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _myBooksView() {
    if (!_loggedIn) {
      return Center(
        key: const ValueKey('my-books-logged-out'),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.local_library_outlined, size: 56),
                  const SizedBox(height: 16),
                  const Text(
                    'Your library is waiting',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Start building your personal book collection and track what you love.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: () => _showSection(BookSection.login),
                    child: const Text('Login to continue'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final books = _filterBooks(_myBooks[_currentUser] ?? []);
    return SingleChildScrollView(
      key: const ValueKey('my-books'),
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('My Read Books', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
          const SizedBox(height: 18),
          if (books.isEmpty)
            const Text('No read books saved yet.')
          else
            _booksWrap(books, showActions: false),
        ],
      ),
    );
  }

  Widget _authCard({
    required String title,
    required List<Widget> fields,
    required String action,
    required FutureOr<void> Function() onAction,
    Widget? secondary,
  }) {
    return Center(
      key: ValueKey(title),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 390),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 16),
                ...fields,
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: onAction,
                    child: Text(action),
                  ),
                ),
                if (secondary != null) ...[
                  const SizedBox(height: 8),
                  secondary,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool obscure = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _booksWrap(List<Book> books, {bool showActions = true}) {
    return Wrap(
      spacing: 20,
      runSpacing: 20,
      children: books
          .map(
            (book) {
              final alreadyRead =
                  (_myBooks[_currentUser] ?? []).any((saved) => saved.title == book.title);
              final alreadyToRead =
                  (_toReadBooks[_currentUser] ?? []).any((saved) => saved.title == book.title);
              return BookCard(
                book: book,
                rating: _bookRating(book),
                reviewCount: _reviewCount(book),
                onTap: () => _showBookDialog(book),
                onAddToMyReadBooks:
                    showActions && !alreadyRead ? () => unawaited(_addToMyBooks(book)) : null,
                onAddToReadList:
                    showActions && !alreadyToRead ? () => unawaited(_addToRead(book)) : null,
                onEdit: book.userId == _currentUser ? () => _showBookFormDialog(book: book) : null,
                onDelete: book.userId == _currentUser ? () => unawaited(_deleteCatalogBook(book)) : null,
                myReadBooksLabel: alreadyRead ? 'Read' : 'Add to My Read Books',
                toReadListLabel: alreadyToRead ? 'In To Read' : 'Add to To Read List',
              );
            },
          )
          .toList(),
    );
  }

  Future<void> _saveCatalogBook(Book book, {Book? existing}) async {
    if (!_loggedIn) {
      _snack('Login first', error: true);
      return;
    }
    try {
      final payload = _bookPayload(book)..['status'] = 'catalog';
      final data = await _requestJson(
        existing?.id == null ? '$bookApiBase/books' : '$bookApiBase/books/${existing!.id}',
        method: existing?.id == null ? 'POST' : 'PUT',
        auth: true,
        body: payload,
      );
      final saved = Book.fromJson(data as Map<String, dynamic>);
      _upsertCatalogBook(saved);
      _snack(existing == null ? 'Book added' : 'Book updated');
    } catch (error) {
      final local = book.copyWith(id: existing?.id, userId: _currentUser);
      _upsertCatalogBook(local, existing: existing);
      _snack(error.toString().replaceFirst('Exception: ', ''), error: true);
    }
  }

  void _upsertCatalogBook(Book book, {Book? existing}) {
    setState(() {
      final index = _catalogBooks.indexWhere((item) =>
          (book.id != null && item.id == book.id) ||
          (existing != null && item.title == existing.title && item.author == existing.author));
      if (index == -1) {
        _catalogBooks.add(book.copyWith(userId: book.userId ?? _currentUser));
      } else {
        _catalogBooks[index] = book.copyWith(userId: book.userId ?? _currentUser);
      }
    });
    _persistCatalogBooks();
  }

  Future<void> _deleteCatalogBook(Book book) async {
    try {
      if (book.id != null) {
        await _requestJson('$bookApiBase/books/${book.id}', method: 'DELETE', auth: true);
      }
    } catch (_) {}
    setState(() {
      _catalogBooks.removeWhere((item) =>
          (book.id != null && item.id == book.id) ||
          (item.title == book.title && item.author == book.author));
    });
    _persistCatalogBooks();
    _snack('Book deleted');
  }

  void _showBookFormDialog({Book? book}) {
    if (!_loggedIn) {
      _snack('Login first', error: true);
      return;
    }
    final titleController = TextEditingController(text: book?.title ?? '');
    final authorController = TextEditingController(text: book?.author ?? '');
    final yearController = TextEditingController(text: book?.year ?? '');
    final coverController = TextEditingController(text: book?.imageUrl ?? '');
    final descriptionController = TextEditingController(text: book?.description ?? '');
    var selectedGenre = genres.contains(book?.genre) && book?.genre != 'All'
        ? book!.genre
        : genres.firstWhere((g) => g != 'All');

    showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(book == null ? 'Add Book' : 'Edit Book'),
          content: SizedBox(
            width: 460,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  TextField(controller: authorController, decoration: const InputDecoration(labelText: 'Author', border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  TextField(controller: yearController, decoration: const InputDecoration(labelText: 'Publication year', border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedGenre,
                    decoration: const InputDecoration(labelText: 'Genre', border: OutlineInputBorder()),
                    items: genres.where((g) => g != 'All').map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => selectedGenre = value);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descriptionController,
                    minLines: 3,
                    maxLines: 5,
                    decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: coverController,
                    decoration: const InputDecoration(labelText: 'Cover image link', border: OutlineInputBorder()),
                    onChanged: (_) => setDialogState(() {}),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      onPressed: () => _pickCoverImage(coverController, setDialogState),
                      icon: const Icon(Icons.image_outlined),
                      label: const Text('Choose cover image'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                final title = titleController.text.trim();
                final author = authorController.text.trim();
                final year = yearController.text.trim();
                final cover = coverController.text.trim();
                final description = descriptionController.text.trim();
                if (title.isEmpty || author.isEmpty || year.isEmpty || cover.isEmpty) {
                  _snack('Fill title, author, year and cover', error: true);
                  return;
                }
                Navigator.pop(context);
                unawaited(_saveCatalogBook(
                  Book(
                    id: book?.id,
                    userId: book?.userId ?? _currentUser,
                    title: title,
                    author: author,
                    year: year,
                    rating: 0,
                    genre: selectedGenre,
                    imageUrl: cover,
                    description: description.isEmpty ? null : description,
                  ),
                  existing: book,
                ));
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickCoverImage(TextEditingController controller, StateSetter setDialogState) async {
    final input = html.FileUploadInputElement()..accept = 'image/*';
    input.click();
    await input.onChange.first;
    final file = input.files?.first;
    if (file == null) {
      return;
    }
    final reader = html.FileReader();
    reader.readAsDataUrl(file);
    await reader.onLoad.first;
    controller.text = reader.result as String? ?? '';
    setDialogState(() {});
  }

  void _showBookDialog(Book book) {
    final alreadyAdded =
        (_myBooks[_currentUser] ?? []).any((saved) => saved.title == book.title);
    final alreadyToRead =
        (_toReadBooks[_currentUser] ?? []).any((saved) => saved.title == book.title);

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final size = MediaQuery.sizeOf(dialogContext);
        final narrow = size.width < 720;

        final cover = ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.network(
            book.imageUrl,
            width: narrow ? 160 : 210,
            height: narrow ? 236 : 310,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _coverFallback(
              width: narrow ? 160 : 210,
              height: narrow ? 236 : 310,
            ),
          ),
        );

        final details = ConstrainedBox(
          constraints: BoxConstraints(maxWidth: narrow ? double.infinity : 410),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      book.title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.pop(dialogContext),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(book.author),
              Text(book.year),
              const SizedBox(height: 8),
              _ratingStars(_bookRating(book), count: _reviewCount(book)),
              const SizedBox(height: 16),
              Text(book.description ?? 'No description available.'),
              const SizedBox(height: 20),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(dialogContext);
                      if (alreadyAdded) {
                        unawaited(_removeFromMyBooks(book));
                      } else {
                        unawaited(_addToMyBooks(book));
                      }
                    },
                    icon: Icon(
                      alreadyAdded ? Icons.check_circle_outline : Icons.bookmark_add_outlined,
                    ),
                    label: Text(alreadyAdded ? 'Read' : 'Add to My Read Books'),
                  ),
                  OutlinedButton.icon(
                    onPressed: alreadyToRead
                        ? null
                        : () {
                            Navigator.pop(dialogContext);
                            unawaited(_addToRead(book));
                          },
                    icon: const Icon(Icons.playlist_add),
                    label: Text(alreadyToRead ? 'In To Read' : 'Add to To Read List'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _showReviewDialog(book),
                    icon: const Icon(Icons.rate_review_outlined),
                    label: const Text('Add Review'),
                  ),
                  TextButton.icon(
                    onPressed: () => _showReviewsDialog(book),
                    icon: const Icon(Icons.reviews_outlined),
                    label: const Text('Reviews'),
                  ),
                ],
              ),
            ],
          ),
        );

        return Dialog(
          clipBehavior: Clip.antiAlias,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 720,
              maxHeight: size.height * 0.88,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: narrow
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(child: cover),
                        const SizedBox(height: 20),
                        details,
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        cover,
                        const SizedBox(width: 24),
                        Flexible(child: details),
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }

  void _showReviewDialog(Book book, {BookReview? review}) {
    final controller = TextEditingController(text: review?.text ?? '');
    var stars = review?.stars ?? 5;

    showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(review == null ? 'Add Review' : 'Edit Review'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  initialValue: stars,
                  decoration: const InputDecoration(labelText: 'Rating'),
                  items: [1, 2, 3, 4, 5]
                      .map((value) => DropdownMenuItem(
                            value: value,
                            child: Text(_manualStars(value)),
                          ))
                      .toList(),
                  onChanged: (value) => setDialogState(() => stars = value ?? 5),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  minLines: 3,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Review',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                unawaited(_saveReview(book, stars, controller.text.trim(), existing: review));
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showReviewsDialog(Book book) async {
    var reviews = _reviews[book.title] ?? [];
    try {
      final savedBook = _loggedIn ? await _ensureRemoteBook(book) : book;
      if (savedBook.id != null) {
        final data = await _requestJson('$bookApiBase/reviews/book/${savedBook.id}');
        if (data is List<dynamic>) {
          reviews = data
              .map((item) => BookReview.fromJson(item as Map<String, dynamic>))
              .toList();
          setState(() => _reviews[book.title] = reviews);
          _persistReviews();
        }
      }
    } catch (_) {}

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('User Reviews'),
        content: SizedBox(
          width: 460,
          child: reviews.isEmpty
              ? const Text('No reviews yet.')
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: reviews
                      .map(
                        (review) {
                          final own = review.user == _currentUser;
                          return ListTile(
                            leading: const Icon(Icons.person_outline),
                            title: Text('@${review.user}'),
                            subtitle: Text('${_manualStars(review.stars)}\n${review.text}'),
                            trailing: own
                                ? PopupMenuButton<String>(
                                    onSelected: (value) {
                                      Navigator.pop(context);
                                      if (value == 'edit') {
                                        _showReviewDialog(book, review: review);
                                      } else if (value == 'delete') {
                                        unawaited(_deleteReview(book, review));
                                      }
                                    },
                                    itemBuilder: (context) => const [
                                      PopupMenuItem(value: 'edit', child: Text('Edit')),
                                      PopupMenuItem(value: 'delete', child: Text('Delete')),
                                    ],
                                  )
                                : null,
                          );
                        },
                      )
                      .toList(),
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class ToReadCard extends StatelessWidget {
  const ToReadCard({
    required this.book,
    required this.onTap,
    required this.onProgressChanged,
    required this.onAlreadyRead,
    super.key,
  });

  final Book book;
  final VoidCallback onTap;
  final ValueChanged<double> onProgressChanged;
  final VoidCallback onAlreadyRead;

  @override
  Widget build(BuildContext context) {
    final progress = book.progress.clamp(0, 100).toDouble();

    return SizedBox(
      width: 230,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.network(
                book.imageUrl,
                width: 230,
                height: 300,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _coverFallback(width: 230, height: 300),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 52,
                      child: Text(
                        book.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    Text(book.author, maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.auto_stories_outlined, size: 18),
                        const SizedBox(width: 6),
                        Text('${progress.round()}%'),
                      ],
                    ),
                    Slider(
                      value: progress,
                      min: 0,
                      max: 100,
                      divisions: 20,
                      label: '${progress.round()}%',
                      onChanged: onProgressChanged,
                    ),
                    const SizedBox(height: 4),
                    FilledButton.icon(
                      onPressed: onAlreadyRead,
                      icon: const Icon(Icons.check),
                      label: const Text('Read'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BookCard extends StatelessWidget {
  const BookCard({
    required this.book,
    required this.onTap,
    required this.rating,
    required this.reviewCount,
    this.onAddToMyReadBooks,
    this.onAddToReadList,
    this.onEdit,
    this.onDelete,
    this.myReadBooksLabel = 'Add to My Read Books',
    this.toReadListLabel = 'Add to To Read List',
    super.key,
  });

  final Book book;
  final VoidCallback onTap;
  final double rating;
  final int reviewCount;
  final VoidCallback? onAddToMyReadBooks;
  final VoidCallback? onAddToReadList;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final String myReadBooksLabel;
  final String toReadListLabel;

  @override
  Widget build(BuildContext context) {
    final showActions = onAddToMyReadBooks != null || onAddToReadList != null;
    return SizedBox(
      width: 220,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: onTap,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Image.network(
                    book.imageUrl,
                    width: 220,
                    height: 300,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _coverFallback(width: 220, height: 300),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 56,
                                child: Text(
                                  book.title,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.w800),
                                ),
                              ),
                            ),
                            if (onEdit != null || onDelete != null)
                              PopupMenuButton<String>(
                                onSelected: (value) {
                                  if (value == 'edit') onEdit?.call();
                                  if (value == 'delete') onDelete?.call();
                                },
                                itemBuilder: (context) => [
                                  if (onEdit != null)
                                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                                  if (onDelete != null)
                                    const PopupMenuItem(value: 'delete', child: Text('Delete')),
                                ],
                                icon: const Icon(Icons.more_vert),
                              ),
                          ],
                        ),
                        Text(book.author, maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text(book.year),
                        const SizedBox(height: 6),
                        _ratingStars(rating, size: 14, count: reviewCount),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (showActions)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: onAddToMyReadBooks,
                        icon: const Icon(Icons.bookmark_add_outlined),
                        label: FittedBox(fit: BoxFit.scaleDown, child: Text(myReadBooksLabel)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: onAddToReadList,
                        icon: const Icon(Icons.playlist_add),
                        label: FittedBox(fit: BoxFit.scaleDown, child: Text(toReadListLabel)),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

Widget _coverFallback({double width = 86, double height = 132}) {
  return Container(
    width: width,
    height: height,
    color: const Color(0xFFE6E8EF),
    alignment: Alignment.center,
    child: const Icon(Icons.menu_book_outlined),
  );
}

Widget _ratingStars(double rating, {double size = 18, int count = 0}) {
  final full = rating.floor().clamp(0, 5).toInt();
  final half = rating - full >= 0.25 && full < 5;
  final empty = 5 - full - (half ? 1 : 0);
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      for (var i = 0; i < full; i++)
        Icon(Icons.star, color: const Color(0xFFFFB300), size: size),
      if (half) Icon(Icons.star_half, color: const Color(0xFFFFB300), size: size),
      for (var i = 0; i < empty; i++)
        Icon(Icons.star_border, color: const Color(0xFFFFB300), size: size),
      const SizedBox(width: 4),
      Text(
        '${rating.toStringAsFixed(rating.truncateToDouble() == rating ? 0 : 2)} ($count)',
        style: TextStyle(color: const Color(0xFFFFB300), fontSize: size),
      ),
    ],
  );
}

String _manualStars(int rating) => '${'\u2605' * rating}${'\u2606' * (5 - rating)}';

double _readRating(Object? value) {
  if (value is num) {
    return value.toDouble();
  }
  final match = value.toString().replaceAll(',', '.').contains(RegExp(r'\d'))
      ? RegExp(r'\d+(\.\d+)?').firstMatch(value.toString())
      : null;
  return double.tryParse(match?.group(0) ?? '') ?? 0;
}

int _readStars(Object? value) {
  if (value is int) {
    return value.clamp(1, 5).toInt();
  }
  final text = value.toString();
  final filled = '\u2605'.allMatches(text).length + '\u2B50'.allMatches(text).length;
  return filled.clamp(1, 5).toInt();
}

int? _readInt(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString() ?? '');
}

List<Book> _uniqueBooks(List<Book> books) {
  final map = <String, Book>{};
  for (final book in books) {
    final key = '${book.title.toLowerCase()}|${book.author.toLowerCase()}';
    map[key] = book;
  }
  return map.values.toList();
}

const genres = [
  'Fantasy',
  'Romance',
  'Thriller',
  'Classic',
  'Self-help',
  'Mystery',
  'Drama',
  'Historical',
  'Young Adult',
  'Sci-Fi',
  'All',
];

const trendingBooks = [
  Book(
    title: 'The Hobbit',
    author: 'J.R.R. Tolkien',
    year: '1937',
    rating: 4.7,
    genre: 'Fantasy',
    imageUrl: 'https://d28hgpri8am2if.cloudfront.net/book_images/onix/cvr9781608873869/the-hobbit-9781608873869_hr.jpg',
    description: 'A classic fantasy adventure about Bilbo Baggins, a reluctant hero who joins dwarves on a dangerous quest to reclaim treasure.',
  ),
  Book(
    title: 'Atomic Habits',
    author: 'James Clear',
    year: '2018',
    rating: 4.8,
    genre: 'Self-help',
    imageUrl: 'https://tse2.mm.bing.net/th/id/OIP.8OBj3zwUeZAwpvWyoht2gQHaLL?r=0&rs=1&pid=ImgDetMain&o=7&rm=3',
    description: 'A practical guide to building better habits through small, consistent changes.',
  ),
  Book(
    title: 'Harry Potter',
    author: 'J.K. Rowling',
    year: '1997',
    rating: 4.8,
    genre: 'Fantasy',
    imageUrl: 'https://contentful.harrypotter.com/usf1vwtuqyxm/2DCs73x6P8seNobQ9zBSbO/1a5dfd6ed5fc0ed9545370470fc3d74c/English_Harry_Potter_1_Epub_9781781100219.jpg',
    description: 'A young wizard discovers his identity and begins a magical journey at Hogwarts.',
  ),
  Book(
    title: 'The Alchemist',
    author: 'Paulo Coelho',
    year: '1988',
    rating: 4.6,
    genre: 'Fantasy',
    imageUrl: 'https://tse1.mm.bing.net/th/id/OIP._Z09kGkAdrMKJsz-Zu4LJwHaKj?r=0&rs=1&pid=ImgDetMain&o=7&rm=3',
    description: 'A philosophical adventure about following dreams and listening to the language of the world.',
  ),
  Book(
    title: 'The Midnight Library',
    author: 'Matt Haig',
    year: '2020',
    rating: 4.6,
    genre: 'Romance',
    imageUrl: 'https://tse1.mm.bing.net/th/id/OIP.MnRbJxKbLwqWRQhuBB2gOAHaLM?r=0&rs=1&pid=ImgDetMain&o=7&rm=3',
    description: 'A reflective story about regret, choices, and discovering the value of life.',
  ),
  Book(
    title: 'Extinguish the Heat Runda Piąta',
    author: 'P.S. Herytiera [Pizgacz]',
    year: '2023',
    rating: 4.6,
    genre: 'Young Adult',
    imageUrl: 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRhE1E7j6ToW2FnweWDlHv_GyVhLAuxrz9_gg&s',
    description: 'A young adult romance with intense emotions, conflict, and complicated relationships.',
  ),
  Book(
    title: 'MR Mercedes',
    author: 'Stephen King',
    year: '2014',
    rating: 4.7,
    genre: 'Thriller',
    imageUrl: 'https://tse2.mm.bing.net/th/id/OIP.ExW4bO7MheuFLwlZFSXalQHaLQ?r=0&rs=1&pid=ImgDetMain&o=7&rm=3',
    description: 'A retired detective hunts a killer in a dark and tense crime thriller.',
  ),
  Book(
    title: 'Romeo and Juliet',
    author: 'William Shakespeare',
    year: '1590',
    rating: 4.8,
    genre: 'Romance',
    imageUrl: 'https://tse4.mm.bing.net/th/id/OIP.Xc1XYL63RDJqa_hDW50DFAHaLL?r=0&rs=1&pid=ImgDetMain&o=7&rm=3',
    description: 'A tragic romance about two lovers divided by family conflict.',
  ),
  Book(
    title: 'Keeping 13',
    author: 'Chloe Walsh',
    year: '2018',
    rating: 4.6,
    genre: 'Young Adult',
    imageUrl: 'https://m.media-amazon.com/images/I/81O-cSGFB5L._SL1500_.jpg',
    description: 'A heartfelt young adult romance about loyalty, healing, and growing up.',
  ),
  Book(
    title: 'A Court of Thorns and Roses',
    author: 'Sarah J. Maas',
    year: '2015',
    rating: 4.9,
    genre: 'Fantasy',
    imageUrl: 'https://tse2.mm.bing.net/th/id/OIP.ZITZrfWzWGZKtDJ4luKVBwHaLZ?r=0&rs=1&pid=ImgDetMain&o=7&rm=3',
    description: 'A fantasy romance involving fae courts, danger, magic, and transformation.',
  ),
  Book(
    title: 'Fourth Wing',
    author: 'Rebecca Yarros',
    year: '2023',
    rating: 4.6,
    genre: 'Fantasy',
    imageUrl: 'https://tse2.mm.bing.net/th/id/OIP.0RSIhedBzjgzcxErEWSwTgAAAA?r=0&rs=1&pid=ImgDetMain&o=7&rm=3',
    description: 'A brutal dragon-riding academy where survival depends on strength, courage, and alliances.',
  ),
  Book(
    title: 'Behawiorysta',
    author: 'Remigiusz Mróz',
    year: '2016',
    rating: 4.6,
    genre: 'Mystery',
    imageUrl: 'https://tse4.mm.bing.net/th/id/OIP.3wBboGPJdqDU1DfKn44-dQHaLP?r=0&rs=1&pid=ImgDetMain&o=7&rm=3',
    description: 'A Polish mystery thriller about manipulation, investigation, and psychological tension.',
  ),
  Book(
    title: 'Pride and Prejudice',
    author: 'Jane Austen',
    year: '1813',
    rating: 4.5,
    genre: 'Romance',
    imageUrl: 'https://m.media-amazon.com/images/I/61dU08giPmL._SL1360_.jpg',
    description: 'A classic romance of manners, pride, misunderstanding, and emotional growth.',
  ),
  Book(
    title: 'The Divine Comedy',
    author: 'Dante',
    year: '1308',
    rating: 4.8,
    genre: 'Classic',
    imageUrl: 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRNmE0kNDkvBKgsUMJq69A9h1T6lE-qRL24XA&s',
    description: 'A poetic journey through Hell, Purgatory, and Paradise.',
  ),
  Book(
    title: 'Dear Debbie',
    author: 'Freida McFadden',
    year: '2026',
    rating: 3.98,
    genre: 'Mystery',
    imageUrl: 'https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1774686324i/238365535.jpg',
    description: 'A mystery built around secrets, obsession, and the consequences of hidden pasts.',
  ),
  Book(
    title: 'The Idiot',
    author: 'Fyodor Dostoevsky',
    year: '1869',
    rating: 4.6,
    genre: 'Classic',
    imageUrl: 'https://m.media-amazon.com/images/I/71f4AcK4YkL._AC_UF1000,1000_QL80_.jpg',
    description: 'A psychological classic about innocence, morality, and society.',
  ),
];

const highestRatedBooks = [
  Book(
    title: '#1 Words of Radiance (The Stormlight Archive, #2)',
    author: 'Brandon Sanderson',
    year: '2014',
    rating: 4.76,
    genre: 'Fantasy',
    imageUrl: 'https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1728768241i/17332218.jpg',
    description: 'An epic fantasy filled with war, magic, and complex characters fighting for survival and honor.',
  ),
  Book(
    title: '#2 Harry Potter and the Deathly Hallows',
    author: 'J.K. Rowling',
    year: '2007',
    rating: 4.62,
    genre: 'Fantasy',
    imageUrl: 'https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1663805647i/136251.jpg',
    description: 'The final battle between good and evil as Harry faces his destiny and the truth about his past.',
  ),
  Book(
    title: '#3 Fourth Wing',
    author: 'Rebecca Yarros',
    year: '2023',
    rating: 4.6,
    genre: 'Fantasy',
    imageUrl: 'https://tse2.mm.bing.net/th/id/OIP.0RSIhedBzjgzcxErEWSwTgAAAA?r=0&rs=1&pid=ImgDetMain&o=7&rm=3',
    description: 'A brutal dragon-riding academy where survival depends on strength, courage, and alliances.',
  ),
  Book(
    title: '#4 Crooked Kingdom (Six of Crows, #2)',
    author: 'Leigh Bardugo',
    year: '2016',
    rating: 4.58,
    genre: 'Fantasy',
    imageUrl: 'https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1456172607i/22299763.jpg',
    description: 'A high-stakes heist story where loyalty, revenge, and strategy collide in a dangerous world.',
  ),
  Book(
    title: '#5 A Court of Mist and Fury (A Court of Thorns and Roses, #2)',
    author: 'Sarah J. Maas',
    year: '2016',
    rating: 4.71,
    genre: 'Fantasy',
    imageUrl: 'https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1620325671i/50659468.jpg',
    description: 'A darker and emotional continuation of a fantasy romance filled with power, trauma, and transformation.',
  ),
  Book(
    title: '#6 The Return of the King',
    author: 'J.R.R. Tolkien',
    year: '1955',
    rating: 4.58,
    genre: 'Fantasy',
    imageUrl: 'https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1654216226i/61215384.jpg',
    description: 'The epic conclusion of a legendary journey where the fate of Middle-earth is decided.',
  ),
  Book(
    title: '#7 The House of Hades',
    author: 'Rick Riordan',
    year: '2013',
    rating: 4.64,
    genre: 'Fantasy',
    imageUrl: 'https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1464201430i/12127810.jpg',
    description: 'Heroes face their greatest challenges in a mythological world where survival is never guaranteed.',
  ),
  Book(
    title: '#8 Kingdom of Ash',
    author: 'Sarah J. Maas',
    year: '2018',
    rating: 4.71,
    genre: 'Fantasy',
    imageUrl: 'https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1673567331i/76715522.jpg',
    description: 'An epic finale of sacrifice, war, and destiny in a richly built fantasy universe.',
  ),
  Book(
    title: '#9 The Nightingale',
    author: 'Kristin Hannah',
    year: '2015',
    rating: 4.65,
    genre: 'Thriller',
    imageUrl: 'https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1681839850i/21853621.jpg',
    description: 'A powerful story of two sisters in Nazi-occupied France, courage, sacrifice, and survival.',
  ),
  Book(
    title: '#10 Light Bringer',
    author: 'Pierce Brown',
    year: '2023',
    rating: 4.77,
    genre: 'Sci-Fi',
    imageUrl: 'https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1667655583i/29227774.jpg',
    description: 'A gripping sci-fi story of rebellion, power, and the fight for freedom in a brutal society.',
  ),
];

const newBooks = [
  Book(
    title: 'Dear Debbie',
    author: 'Freida McFadden',
    year: '2026',
    rating: 3.98,
    genre: 'Thriller',
    imageUrl: 'https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1774686324i/238365535.jpg',
    description: 'A mystery built around secrets, obsession, and the consequences of hidden pasts.',
  ),
  Book(
    title: 'My Husband\'s Wife',
    author: 'Alice Feeney',
    year: '2026',
    rating: 3.98,
    genre: 'Thriller',
    imageUrl: 'https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1747668611i/231127462.jpg',
    description: 'A suspenseful story of marriage, deception, and dangerous truths.',
  ),
  Book(
    title: 'The Night We Met (Say You\'ll Remember Me, #2)',
    author: 'Abby Jimenez',
    year: '2026',
    rating: 4.09,
    genre: 'Romance',
    imageUrl: 'https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1755786976i/231801371.jpg',
    description: 'A heartfelt romance about second chances, healing, and unforgettable connections.',
  ),
  Book(
    title: 'Yesteryear',
    author: 'Caro Claire Burke',
    year: '2026',
    rating: 3.17,
    genre: 'Fantasy',
    imageUrl: 'https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1753932705i/238226942.jpg',
    description: 'A nostalgic journey through memory, identity, and the choices that shape our lives.',
  ),
  Book(
    title: 'Half His Age',
    author: 'Jennette McCurdy',
    year: '2026',
    rating: 3.31,
    genre: 'Thriller',
    imageUrl: 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQVSsxzVntocdzDRfjD6aMLrQqyEUbv_yqpwQ&s',
    description: 'A bold story exploring relationships, age differences, and expectations.',
  ),
  Book(
    title: 'Anatomy of an Alibi',
    author: 'Ashley Elston',
    year: '2026',
    rating: 3.82,
    genre: 'Thriller',
    imageUrl: 'https://m.media-amazon.com/images/I/81xA2938-FL._AC_UF1000,1000_QL80_.jpg',
    description: 'A fast-paced mystery where lies and manipulation blur the line between truth and deception.',
  ),
  Book(
    title: 'It\'s Not Her',
    author: 'Mary Kubica',
    year: '2026',
    rating: 3.98,
    genre: 'Thriller',
    imageUrl: 'https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1751999126i/230443142.jpg',
    description: 'A tense psychological thriller about identity, trust, and a dangerous misunderstanding.',
  ),
  Book(
    title: 'Woman Down',
    author: 'Colleen Hoover',
    year: '2026',
    rating: 3.98,
    genre: 'Romance',
    imageUrl: 'https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1757522888i/241458703.jpg',
    description: 'An emotional story about resilience, heartbreak, and finding strength after loss.',
  ),
  Book(
    title: 'In Her Own League',
    author: 'Liz Tomforde',
    year: '2026',
    rating: 4.37,
    genre: 'Romance',
    imageUrl: 'https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1763062347i/230926478.jpg',
    description: 'A romance about ambition, independence, and proving your worth.',
  ),
  Book(
    title: 'This Story Might Save Your Life',
    author: 'Tiffany Crum',
    year: '2026',
    rating: 3.99,
    genre: 'Thriller',
    imageUrl: 'https://m.media-amazon.com/images/S/compressed.photo.goodreads.com/books/1748929782i/231126887.jpg',
    description: 'An uplifting story about self-discovery, healing, and finding purpose.',
  ),
];

import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import '../models/expense.dart';

class DatabaseService {
  static Database? _database;
  static bool _initialized = false;
  static bool _isInitializing = false;
  static Completer<Database>? _initCompleter;
  static StreamController<List<Expense>>? _expenseStreamController;
  static Timer? _watchTimer;
  static DateTime? _lastFetch;
  static const _minFetchInterval = Duration(milliseconds: 100);
  static DateTimeRange? _currentDateRange;

  static Future<void> ensureInitialized() async {
    if (!_initialized && !_isInitializing) {
      await initialize();
    }
  }

  static Future<Database> get database async {
    await ensureInitialized();
    return _database!;
  }

  static Future<void> initialize() async {
    if (_initialized) {
      debugPrint('Database already initialized');
      return;
    }

    if (_isInitializing) {
      if (_initCompleter != null) {
        debugPrint('Database initialization in progress, waiting for completion...');
        await _initCompleter!.future;
        return;
      }
    }

    _isInitializing = true;
    _initCompleter = Completer<Database>();

    try {
      debugPrint('Starting database initialization...');
      _database = await _initDatabase();
      _initialized = true;
      _initCompleter?.complete(_database);
      debugPrint('Database initialization completed successfully');
    } catch (e, stackTrace) {
      debugPrint('Error during database initialization: $e');
      debugPrint('Stack trace: $stackTrace');
      _initialized = false;
      _database = null;
      _initCompleter?.completeError(e, stackTrace);
      rethrow;
    } finally {
      _isInitializing = false;
      _initCompleter = null;
    }
  }

  static Future<Database> _initDatabase() async {
    debugPrint('Getting database path...');
    
    String path;
    if (Platform.isWindows || Platform.isLinux) {
      final appDir = await getApplicationDocumentsDirectory();
      path = join(appDir.path, 'expenses.db');
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    } else {
      final dbPath = await sqflite.getDatabasesPath();
      path = join(dbPath, 'expenses.db');
      databaseFactory = sqflite.databaseFactory;
    }
    
    debugPrint('Database path: $path');
    await Directory(dirname(path)).create(recursive: true);

    debugPrint('Opening database...');
    return await databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (Database db, int version) async {
          debugPrint('Creating database tables...');
          await db.transaction((txn) async {
            await txn.execute('''
              CREATE TABLE IF NOT EXISTS expenses(
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                amount REAL NOT NULL,
                category TEXT NOT NULL,
                description TEXT,
                date TEXT NOT NULL,
                type INTEGER NOT NULL
              )
            ''');
            
            debugPrint('Creating indexes...');
            await txn.execute('CREATE INDEX IF NOT EXISTS idx_amount ON expenses(amount)');
            await txn.execute('CREATE INDEX IF NOT EXISTS idx_category ON expenses(category)');
            await txn.execute('CREATE INDEX IF NOT EXISTS idx_date ON expenses(date)');
          });
          debugPrint('Database tables and indexes created successfully');
        },
        onOpen: (db) {
          debugPrint('Database opened successfully');
        },
      ),
    );
  }

  static Future<void> addExpense(Expense expense) async {
    if (!_initialized) {
      debugPrint('Database not initialized, initializing now...');
      await initialize();
    }
    
    try {
      final db = await database;
      await db.transaction((txn) async {
        await txn.insert('expenses', expense.toMap());
      });
      _notifyListeners();
    } catch (e, stackTrace) {
      debugPrint('Error adding expense: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  static Future<void> _notifyListeners() async {
    if (_expenseStreamController != null && !_expenseStreamController!.isClosed) {
      final now = DateTime.now();
      if (_lastFetch == null || now.difference(_lastFetch!) >= _minFetchInterval) {
        _lastFetch = now;
        await _fetchAndEmitExpenses();
      }
    }
  }

  static Stream<List<Expense>> watchExpensesByDateRange(
    DateTime start,
    DateTime end,
  ) {
    debugPrint('Setting up expense stream for date range: ${start.toIso8601String()} to ${end.toIso8601String()}');
    
    _currentDateRange = DateTimeRange(start: start, end: end);
    
    if (_expenseStreamController != null) {
      debugPrint('Closing existing expense stream');
      _expenseStreamController!.close();
    }
    _expenseStreamController = StreamController<List<Expense>>();
    
    _watchTimer?.cancel();
    
    // Initial fetch
    _fetchAndEmitExpenses();
    
    // Set up periodic updates with a more reasonable interval
    _watchTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _fetchAndEmitExpenses();
    });
    
    return _expenseStreamController!.stream;
  }

  static Future<void> _fetchAndEmitExpenses() async {
    if (_expenseStreamController != null && !_expenseStreamController!.isClosed) {
      try {
        if (!_initialized) {
          debugPrint('Database not initialized, initializing now...');
          await initialize();
        }
        
        final db = await database;
        final results = await db.query(
          'expenses',
          where: 'date >= ? AND date <= ?',
          whereArgs: [
            _currentDateRange?.start.toIso8601String(),
            _currentDateRange?.end.toIso8601String(),
          ],
          orderBy: 'date DESC',
        );
        
        final expenses = results.map((map) => Expense.fromMap(map)).toList();
        if (!_expenseStreamController!.isClosed) {
          _expenseStreamController!.add(expenses);
        }
      } catch (e, stackTrace) {
        debugPrint('Error watching expenses: $e');
        debugPrint('Stack trace: $stackTrace');
        if (!_expenseStreamController!.isClosed) {
          _expenseStreamController!.addError(e, stackTrace);
        }
      }
    }
  }

  static Future<void> deleteExpense(int id) async {
    if (!_initialized) {
      debugPrint('Database not initialized, initializing now...');
      await initialize();
    }
    
    try {
      final db = await database;
      await db.transaction((txn) async {
        await txn.delete(
          'expenses',
          where: 'id = ?',
          whereArgs: [id],
        );
      });
      _notifyListeners();
    } catch (e, stackTrace) {
      debugPrint('Error deleting expense: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  static Future<void> dispose() async {
    debugPrint('Disposing database service');
    _watchTimer?.cancel();
    await _expenseStreamController?.close();
    await _database?.close();
    _database = null;
    _initialized = false;
    _isInitializing = false;
    _lastFetch = null;
  }
}
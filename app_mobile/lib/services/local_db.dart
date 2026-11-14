import 'dart:convert';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/conta_model.dart';

class LocalDb {
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'iceibank_offline.db');

    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE contas_cache (
            agencia INTEGER,
            id INTEGER,
            titular TEXT,
            saldo REAL,
            vetorAtual TEXT,
            provisorio INTEGER,
            PRIMARY KEY (agencia, id)
          )
        ''');

        await db.execute('''
          CREATE TABLE operacoes_pendentes (
            dbId INTEGER PRIMARY KEY AUTOINCREMENT,
            agenciaId INTEGER,
            contaId INTEGER,
            tipo TEXT,
            valor REAL,
            vetorConhecido TEXT,
            criadoEm TEXT
          )
        ''');
      },
    );
    return _db!;
  }

  static Future<void> salvarConta(ContaModel conta) async {
    final db = await database;
    await db.insert(
      'contas_cache',
      {
        'agencia': conta.agencia,
        'id': conta.id,
        'titular': conta.titular,
        'saldo': conta.saldo,
        'vetorAtual': jsonEncode(conta.vetorAtual),
        'provisorio': conta.provisorio ? 1 : 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<ContaModel?> lerConta(int agencia, int idConta) async {
    final db = await database;
    final rows = await db.query(
      'contas_cache',
      where: 'agencia = ? AND id = ?',
      whereArgs: [agencia, idConta],
    );
    if (rows.isEmpty) return null;
    final row = rows.first;
    return ContaModel(
      id: row['id'] as int,
      agencia: row['agencia'] as int,
      titular: row['titular'] as String,
      saldo: (row['saldo'] as num).toDouble(),
      vetorAtual: List<int>.from(jsonDecode(row['vetorAtual'] as String)),
      provisorio: (row['provisorio'] as int) == 1,
    );
  }

  static Future<void> inserirOperacaoPendente(OperacaoPendente op) async {
    final db = await database;
    await db.insert('operacoes_pendentes', {
      'agenciaId': op.agenciaId,
      'contaId': op.contaId,
      'tipo': op.tipo,
      'valor': op.valor,
      'vetorConhecido': jsonEncode(op.vetorConhecido),
      'criadoEm': op.criadoEm,
    });
  }

  static Future<List<OperacaoPendente>> listarOperacoesPendentes() async {
    final db = await database;
    final rows = await db.query('operacoes_pendentes', orderBy: 'dbId ASC');
    return rows.map((row) {
      return OperacaoPendente(
        dbId: row['dbId'] as int,
        agenciaId: row['agenciaId'] as int,
        contaId: row['contaId'] as int,
        tipo: row['tipo'] as String,
        valor: (row['valor'] as num).toDouble(),
        vetorConhecido:
            List<int>.from(jsonDecode(row['vetorConhecido'] as String)),
        criadoEm: row['criadoEm'] as String,
      );
    }).toList();
  }

  static Future<void> removerOperacaoPendente(int dbId) async {
    final db = await database;
    await db.delete(
      'operacoes_pendentes',
      where: 'dbId = ?',
      whereArgs: [dbId],
    );
  }
}

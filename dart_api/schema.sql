-- =====================================================
--  MedControl – Schema SQLite
--  Fonte: darthave/sqlite.sql
-- =====================================================

-- =========================
-- TABELA USUÁRIOS
-- =========================
CREATE TABLE IF NOT EXISTS users (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    nome            TEXT    NOT NULL,
    email           TEXT    NOT NULL UNIQUE,
    senha           TEXT    NOT NULL,
    data_nascimento TEXT    NOT NULL,
    created_at      TEXT    DEFAULT CURRENT_TIMESTAMP
);

-- =========================
-- TABELA MEDICAMENTOS
-- =========================
CREATE TABLE IF NOT EXISTS medications (
    id               INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id          INTEGER NOT NULL,
    nome             TEXT    NOT NULL,
    dosagem          TEXT    NOT NULL,
    intervalo_horas  INTEGER NOT NULL,
    dias_tratamento  INTEGER NOT NULL,
    data_inicio      TEXT    NOT NULL,
    ativo            INTEGER DEFAULT 1,
    FOREIGN KEY (user_id) REFERENCES users(id)
);

-- =========================
-- TABELA HORÁRIOS
-- =========================
CREATE TABLE IF NOT EXISTS schedules (
    id            INTEGER PRIMARY KEY AUTOINCREMENT,
    medication_id INTEGER NOT NULL,
    horario       TEXT    NOT NULL,
    FOREIGN KEY (medication_id)
        REFERENCES medications(id)
        ON DELETE CASCADE
);

-- =========================
-- TABELA HISTÓRICO
-- =========================
CREATE TABLE IF NOT EXISTS history (
    id            INTEGER PRIMARY KEY AUTOINCREMENT,
    medication_id INTEGER NOT NULL,
    data          TEXT    NOT NULL,
    horario       TEXT    NOT NULL,
    status        TEXT    NOT NULL,   -- 'tomado' | 'nao_tomado' | 'atrasado'
    FOREIGN KEY (medication_id)
        REFERENCES medications(id)
        ON DELETE CASCADE
);

-- =========================
-- TABELA CUIDADORES
-- =========================
CREATE TABLE IF NOT EXISTS caregivers (
    id       INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id  INTEGER NOT NULL,
    nome     TEXT    NOT NULL,
    telefone TEXT,
    email    TEXT,
    FOREIGN KEY (user_id)
        REFERENCES users(id)
        ON DELETE CASCADE
);

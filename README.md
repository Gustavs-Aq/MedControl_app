# MedControl — Projeto Completo

App Flutter de controle de medicamentos com banco SQLite local e API REST em Dart puro.

---

## 📁 Estrutura do projeto

```
medcontrol_completo/
├── flutter_app/                  ← App Flutter
│   ├── pubspec.yaml
│   └── lib/
│       ├── main.dart             ← Entry point (AuthGate + enum AppScreen + MainNavigation)
│       ├── database/
│       │   └── database_helper.dart   ← SQLite (5 tabelas do schema)
│       ├── models/
│       │   └── models.dart       ← Medication, AppUser, Schedule, HistoryEntry, TodaySchedule, Caregiver
│       ├── services/
│       │   └── api_service.dart  ← Cliente HTTP para o servidor Dart
│       ├── providers/
│       │   └── auth_controller.dart   ← Sessão do usuário
│       ├── theme/
│       │   └── app_theme.dart    ← Paleta de cores e ThemeData
│       ├── widgets/
│       │   └── shared_widgets.dart    ← StatusBar, BottomNav, PillIcon, painters, snack
│       └── screens/
│           ├── splash_screen.dart
│           ├── login_screen.dart
│           ├── register_screen.dart
│           ├── home_screen.dart        ← Horários do dia com botão "Tomei"
│           ├── medications_screen.dart ← Lista com busca + swipe para deletar
│           ├── history_screen.dart     ← Calendário semanal + registros
│           ├── reports_screen.dart     ← Gráfico circular + barras + estatísticas
│           ├── profile_screen.dart     ← Perfil + cuidadores + logout
│           └── add_medication_modal.dart ← Modal animado com salvamento no SQLite
│
└── dart_api/                     ← API REST em Dart puro
    ├── pubspec.yaml
    ├── schema.sql                ← Schema original do sqlite.sql
    └── bin/
        └── server.dart           ← Servidor HTTP na porta 8080
```

---

## 🗃️ Banco de dados (SQLite)

Schema baseado em `darthave/sqlite.sql` — 5 tabelas:

| Tabela        | Descrição                                    |
|---------------|----------------------------------------------|
| `users`       | Usuários (nome, email, senha, data_nascimento) |
| `medications` | Medicamentos (nome, dosagem, intervalo, dias) |
| `schedules`   | Horários de cada medicamento                 |
| `history`     | Registro de tomadas (tomado/nao_tomado/atrasado) |
| `caregivers`  | Cuidadores vinculados ao usuário             |

---

## 🚀 Como rodar

### Flutter App

```bash
cd flutter_app
flutter pub get
flutter run
```

### Servidor Dart (API)

```bash
cd dart_api
dart pub get
dart run bin/server.dart
```

O servidor inicia em `http://localhost:8080`.

---

## 🔌 Rotas da API

### Auth
| Método | Rota             | Descrição          |
|--------|------------------|--------------------|
| POST   | /auth/register   | Criar conta        |
| POST   | /auth/login      | Login              |

### Usuários
| Método | Rota         | Descrição          |
|--------|--------------|--------------------|
| GET    | /users/:id   | Buscar usuário     |
| PUT    | /users/:id   | Atualizar usuário  |

### Medicamentos
| Método | Rota                | Descrição              |
|--------|---------------------|------------------------|
| GET    | /medications        | Listar por user_id     |
| POST   | /medications        | Criar medicamento      |
| GET    | /medications/:id    | Buscar por id          |
| PUT    | /medications/:id    | Atualizar              |
| DELETE | /medications/:id    | Remover (soft-delete)  |

### Horários
| Método | Rota                              | Descrição         |
|--------|-----------------------------------|-------------------|
| GET    | /medications/:id/schedules        | Listar horários   |
| POST   | /medications/:id/schedules        | Adicionar horário |

### Histórico
| Método | Rota      | Descrição                        |
|--------|-----------|----------------------------------|
| GET    | /history  | Listar por user_id e/ou date     |
| POST   | /history  | Registrar tomada (upsert)        |

### Relatórios
| Método | Rota                  | Descrição              |
|--------|-----------------------|------------------------|
| GET    | /reports/adherence    | Adesão dos 7 dias      |

### Cuidadores
| Método | Rota              | Descrição           |
|--------|-------------------|---------------------|
| GET    | /caregivers       | Listar por user_id  |
| POST   | /caregivers       | Adicionar           |
| DELETE | /caregivers/:id   | Remover             |

---

## 🎨 Paleta de cores

| Cor            | Hex         | Uso                                  |
|----------------|-------------|--------------------------------------|
| Azul primário  | `#2563EB`   | Header Medicamentos, Relatórios, Login |
| Verde          | `#10B981`   | Botões, status "Tomado", BottomNav   |
| Fundo          | `#F9FAFB`   | Background geral                     |
| Texto escuro   | `#111827`   | Títulos                              |
| Texto médio    | `#6B7280`   | Subtítulos e labels                  |

---

## 📱 Telas

| Tela              | Funcionalidade real                                  |
|-------------------|------------------------------------------------------|
| Splash            | Logo animado, 2s → login                             |
| Login             | Auth com SQLite, validação de email/senha            |
| Cadastro          | Registro com validação + data de nascimento          |
| Home              | Horários do dia via JOIN SQL, botão "Tomei", aderência |
| Medicamentos      | Lista com busca, swipe para deletar, horários        |
| Histórico         | Calendário semanal, registros por dia com status     |
| Relatórios        | Gráfico circular, barras 7 dias, stats reais do DB   |
| Perfil            | Editar nome, cuidadores (CRUD), logout               |
| Modal Add Med     | Formulário com SQLite, múltiplos horários            |

---

## 🏗️ Arquitetura

```
UI (screens) 
  ↓ chama
AuthController / DatabaseHelper (providers + database)
  ↓ usa
sqflite (SQLite local)  +  ApiService (HTTP → Dart API)
```

- **SQLite local** é a fonte primária de dados (offline-first)
- **ApiService** comunica com o servidor Dart para sincronização futura
- **AuthController** é singleton que mantém a sessão do usuário em memória
- **IndexedStack** na MainNavigation preserva o estado de cada aba

---

## ⚙️ Dependências

```yaml
# Flutter
sqflite: ^2.3.2      # SQLite local
path: ^1.9.0          # Caminhos de banco
http: ^1.2.1          # Comunicação com API
intl: ^0.19.0         # Datas


---

# Full `ARCHITECTURE.md`

Create a file named `ARCHITECTURE.md` in your project root and paste this:

```md
# ARCHITECTURE.md

## Architectural Decisions for CampusBites

CampusBites was designed as a Flutter application with local-only data persistence. The architecture is intentionally simple and practical for a course project while still following separation of concerns.

## Main Design Choices

### 1. Flutter UI Layer
The UI is built in Flutter using Material Design widgets. Screens are divided by purpose, such as:
- dashboard
- food list
- restaurant details
- favorites
- budget tracker
- settings

This keeps navigation clear and makes the app easier to extend.

### 2. SQLite for Structured Data
SQLite is used for data that benefits from structured storage and relationships:
- restaurants
- expenses
- favorites
- reviews

This allows CRUD operations and supports the project requirement for local-only storage.

### 3. SharedPreferences for Simple Settings
SharedPreferences is used for the weekly budget goal because it is a simple key-value setting and does not need a relational table.

### 4. Database Helper Abstraction
All SQLite logic is placed in `database_helper.dart`. This improves separation of concerns because UI code does not directly manage raw database setup logic.

Benefits:
- easier maintenance
- clearer data flow
- reusable database methods

### 5. Stateful Widgets for Local Screen State
Stateful widgets are used where screens need to refresh data after inserts or updates, such as:
- food list
- restaurant details
- budget tracker
- settings

This approach is lightweight and suitable for the scale of this project.

## Why This Architecture Works

This architecture was chosen because it is:
- simple enough for a class project
- fully offline
- easy to understand
- aligned with Flutter + SQLite requirements
- practical for demonstrating CRUD, navigation, and persistence

## Future Improvements

If the project were expanded further, it could be improved by:
- moving models into separate files
- adding repository classes
- using Provider or Riverpod for state management
- splitting screens into separate Dart files
- adding automated tests
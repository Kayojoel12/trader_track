# TRADE Track

Application Flutter de journal de trading, avec Supabase pour l'authentification et les données, et une API NestJS pour l'import MT5.

## Démarrage rapide

```powershell
flutter pub get
flutter run --dart-define=SUPABASE_URL=https://<project-ref>.supabase.co --dart-define=SUPABASE_ANON_KEY=<publishable-key>
```

Remplace les valeurs par celles du projet Supabase utilisé. Ne mets jamais une clé `service_role` dans l'application. L'API MT5 est facultative pour le reste de l'application ; voir le guide pour la configurer.

## Documentation

- [Guide de développement](docs/DEVELOPMENT.md) : architecture, navigation, ajout d'une page, tests et dépannage de l'authentification.
- [Migrations Supabase](supabase/migrations/) : schéma et politiques de sécurité à appliquer dans l'ordre.

## Vérifications rapides

```powershell
flutter analyze
flutter test
```


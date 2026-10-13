# Offerte AI — regole del progetto

App Flutter (Android + iOS) che legge volantini di supermercati con l'API di Claude e stima i prezzi migliori. Due sviluppatori lavorano sullo stesso repo: segui queste regole in ogni sessione.

## Lingua
- Interfaccia, commenti e messaggi di commit in **italiano**.
- Nomi di classi, metodi e variabili in inglese (convenzione Dart).

## Architettura
- `models/` solo dati e conversioni, niente Flutter né rete.
- `services/` logica: `price_analyzer.dart` deve restare **Dart puro** (testabile senza dispositivo).
- `state/offers_provider.dart` è l'unico punto che modifica i dati; le schermate leggono con `context.watch` e agiscono con `context.read`.
- Gestione dello stato con `provider`. Non introdurre altre librerie di stato senza discuterne.
- Prezzi sempre in euro come `double`; i confronti usano il prezzo per unità base (kg, l, pz) tramite `comparablePrice`.

## Prompt dell'AI
- Il prompt di estrazione è in `services/ai_extractor.dart`. Se cambi lo schema JSON, aggiorna anche `Offer.fromAiJson` e i test in `test/`.

## Prima di ogni commit
- `dart format .`
- `flutter analyze` senza errori
- `flutter test` tutto verde
- Nuova logica in `services/` o `models/` → nuovo test.

## Git
- Mai lavorare direttamente su `main`: un branch per attività (`feature/...`, `fix/...`).
- `git pull` prima di iniziare.
- Commit piccoli con messaggio chiaro in italiano; poi pull request.
- Non committare mai chiavi API o file `.env`.

## Cartelle android/ e ios/
- Generate con `flutter create` (vedi README). Se le modifichi, ricorda i permessi: fotocamera e galleria su iOS, INTERNET su Android.

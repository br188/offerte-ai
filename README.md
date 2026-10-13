# Offerte AI

App per Android e iOS che legge i volantini dei supermercati con l'intelligenza artificiale, salva le offerte e stima dove e quando un prodotto costa meno.

Scritta in **Flutter** (linguaggio Dart): un solo codice per entrambe le piattaforme.

## Come funziona

1. **Leggi volantino** — fotografi una pagina (o la scegli dalla galleria). L'immagine viene inviata all'API di Claude, che restituisce le offerte in formato strutturato: prodotto, marca, categoria, prezzo, prezzo pieno, formato, date di validità.
2. **Controllo** — vedi l'elenco estratto e togli la spunta alle righe sbagliate prima di salvare.
3. **Prezzi migliori** — l'app raggruppa lo stesso prodotto tra supermercati diversi e confronta il **prezzo al kg / al litro / al pezzo**, così una confezione da 500 g e una da 1 kg sono confrontabili.
4. **Stima** — con lo storico delle offerte lette calcola il prezzo abituale (mediana) e giudica il miglior prezzo attuale: *Ottimo* (nel 25% più basso), *Buono*, *Nella media*, *Sopra la media*. Con meno di 3 rilevazioni mostra *Pochi dati*.

I dati restano sul telefono (SQLite). La chiave API è salvata cifrata nel portachiavi del dispositivo.

## Struttura

```
lib/
  main.dart                      avvio, tema, provider
  models/offer.dart              modello Offer, conversione unità (g→kg, ml→l)
  services/
    ai_extractor.dart            chiamata all'API di Claude e lettura del JSON
    price_analyzer.dart          confronto prezzi, stima del prezzo abituale, giudizio
    offer_repository.dart        database locale SQLite
    settings_service.dart        chiave API e modello (archivio cifrato)
  state/offers_provider.dart     stato dell'app e filtri
  screens/                       home, lettura volantino, dettaglio prodotto, impostazioni
  widgets/                       componenti riusabili
  utils/format.dart              formattazione prezzi e date
test/price_analyzer_test.dart    test della logica (senza rete né telefono)
```

## Installazione

Serve [Flutter](https://docs.flutter.dev/get-started/install) 3.22 o successivo.

```bash
git clone <url-del-repo>
cd offerte-ai

# Genera le cartelle android/ e ios/ (una sola volta, non tocca lib/)
flutter create . --platforms=android,ios --project-name offerte_ai --org it.offerteai

flutter pub get
flutter test
flutter run
```

### Permessi da aggiungere dopo `flutter create`

**iOS** — in `ios/Runner/Info.plist`, dentro `<dict>`:

```xml
<key>NSCameraUsageDescription</key>
<string>Serve per fotografare i volantini.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Serve per scegliere la foto di un volantino.</string>
```

**Android** — in `android/app/src/main/AndroidManifest.xml`, prima di `<application>`:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
```

Con Claude Code basta chiedere: *"completa la configurazione di Android e iOS come indicato nel README"*.

### Chiave API

Crea una chiave su [console.anthropic.com](https://console.anthropic.com) e inseriscila in **Impostazioni** dentro l'app. Ogni pagina di volantino letta consuma qualche centesimo di credito API.

> Per uso personale va bene tenere la chiave sul telefono. Se l'app venisse distribuita ad altri, la chiamata all'API andrebbe spostata su un piccolo server, così la chiave non finisce nell'app.

## Lavorare in due

- Un branch per ogni attività: `git switch -c feature/nome-attivita`.
- Prima di iniziare: `git pull`.
- A lavoro finito: commit, push e pull request; l'altro la rivede e la unisce.
- `CLAUDE.md` contiene le regole del progetto: Claude Code lo legge in automatico, quindi lavora allo stesso modo per entrambi.

## Idee per i prossimi passi

- Lista della spesa che sceglie il supermercato più conveniente per l'intero carrello.
- Lettura di volantini in PDF (più pagine in una volta).
- Grafico dell'andamento del prezzo nel tempo.
- Notifica quando un prodotto seguito scende sotto il prezzo abituale.

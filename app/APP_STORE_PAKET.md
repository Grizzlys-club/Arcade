# Grizzlys Arcade – App-Store-Paket

## 1. Store-Texte (App Store Connect → App-Informationen / Version)

**Name (max. 30):** Grizzlys Arcade
**Untertitel (max. 30):** Unihockey-Partyspiele für 1–4
**Kategorie:** Spiele → Sport (Zweitkategorie: Spiele → Familie)
**Preis:** Gratis · keine In-App-Käufe
**Altersfreigabe:** 4+ (alle Fragen im Fragebogen mit «Keine» beantworten)

**Werbetext (max. 170):**
50 Minispiele, ein Handy, bis zu 4 Spieler: Penalty, Air-Hockey, Bowling, Curling und mehr. Gleichzeitig spielen, Turnier gewinnen, Pokal holen.

**Beschreibung:**
Die offizielle Spiele-App von Unihockey am Greifensee Grizzlys!

Leg das Handy auf den Tisch, setzt euch rundherum und los geht's: Bis zu vier Spieler spielen gleichzeitig an einem iPhone – jeder von seiner Seite aus. Allein spielst du gegen schlaue Computer-Bären in fünf Stärken.

50 MINISPIELE
• Unihockey & Sport: Penalty-Duell, Torwart-Panik, Air-Hockey, Puck-Golf, Ballregen, Power-Schuss, Heisser Puck, Eis-Sumo, Puck-Ninja, Ballhalten, Unihockey-Quiz, Schläger-Duell, Bären-Sprint, Puck-Jagd, Eis-Curling, Slalom-Dribbling, Puck-Pong, Korbjagd, Puck-Billard, Puck-Ausweichen, Pendel-Wurf, Eis-Rutsch
• Party & Denken: Flatter-Bär, Bären-Hüpfer, Bären-Turm, Grizzly Says, Reaktions-Duell, Zahlen-Jagd, Farben-Falle, Eis-Balance, Revierkampf, Tap-Sprint, Bären-Memory, Bären-Bowling, Tauziehen, Bären-Darts, Hürdenlauf, Kopfrechnen, Takt-Tipper, Pfeil-Panik, Ausreisser, Grösser oder kleiner, Farb-Sortierer, Höhlenflug, Puck-Zähler, Zeit-Stopp, Schneeballschlacht, Zickzack-Bär, Lichter aus, Finger-Blitz

TURNIER-MODUS
Wähle 3 bis 15 Runden – die Glücksmaschine lost jede Runde ein zufälliges Spiel aus. Punkte sammeln, das Finale zählt doppelt, und der Sieger steht mit Pokal ganz oben auf dem Podest.

UND NOCH MEHR
• Bären-Skins und Trikots zum Freispielen
• Tägliches Glücksrad mit Streak-Bonus
• Rekorde, Statistiken, Erfolge und tägliche Aufgaben
• Edler Gold-Look, Sound und Vibration
• Keine Werbung, keine Käufe, kein Tracking, funktioniert offline

**Keywords (max. 100, ohne Leerzeichen nach Komma):**
unihockey,floorball,partyspiele,2 spieler,4 spieler,minispiele,hockey,turnier,multiplayer,grizzlys

**Support-URL:** Website des Vereins (Seite mit Kontakt)
**Datenschutz-URL:** Seite mit dem Text aus Abschnitt 2 auf der Vereinswebsite
**Copyright:** 2026 Unihockey am Greifensee Grizzlys

**Notizen für Apple (App Review):**
Party-Spiel für 1–4 Spieler an einem Gerät. Keine Anmeldung, kein Netzwerk, keine Käufe. Die Münzen gibt es nur fürs Spielen, man kann sie nicht kaufen. Name und Logo der Grizzlys werden mit schriftlicher Erlaubnis des Vereins verwendet (Dokument liegt bei / kann nachgereicht werden).

## 2. Datenschutzerklärung (für die Website)

**Datenschutzerklärung – Grizzlys Arcade**
Stand: November 2026

Grizzlys Arcade sammelt keine personenbezogenen Daten.
• Keine Anmeldung, keine Werbung, kein Tracking, keine Analyse-Tools, keine In-App-Käufe.
• Spielernamen, Münzen, Skins, Rekorde, Erfolge und Einstellungen werden ausschliesslich lokal auf dem Gerät gespeichert und nie übertragen.
• Die App baut keine Internetverbindung auf.
• Durch «Einstellungen → Fortschritt zurücksetzen» oder das Löschen der App werden alle Daten entfernt.
Kontakt: Unihockey am Greifensee Grizzlys, [Adresse / E-Mail des Vereins]

**App-Datenschutz in App Store Connect:** «Keine Daten erfasst» auswählen.

## 3. Checkliste bis zur Veröffentlichung

**Vorher klären**
- [ ] Schriftliche Erlaubnis des Vereins für Name + Logo (E-Mail oder unterschriebenes PDF) – Apple fragt bei Markennamen oft nach (Richtlinie 5.2).
- [ ] Quizfragen vom Verein prüfen lassen (Datei `Games/QuizGame.swift`, Liste ganz oben).
- [ ] Support- und Datenschutz-Seite auf der Vereinswebsite online stellen.

**Apple-Konto**
- [ ] Apple Developer Program beitreten (developer.apple.com/programs, Einzelperson, 99 USD/Jahr). Kein D-U-N-S nötig.
- [ ] Hinweis: Mit deinem persönlichen Konto steht dein Name als Anbieter im Store. Soll dort «Grizzlys» stehen, braucht der Verein ein eigenes Organisations-Konto (mit D-U-N-S).

**In Xcode**
- [ ] `GrizzlysArcade.xcodeproj` öffnen → Ziel «GrizzlysArcade» → Signing & Capabilities → Team = dein Apple-Konto.
- [ ] Falls die Bundle-ID schon vergeben ist, `ch.levin.grizzlysarcade` anpassen.
- [ ] Auf dem eigenen iPhone testen (Kabel anschliessen, iPhone oben auswählen, ▶︎).
- [ ] Oben «Any iOS Device» wählen → Product → Archive → Distribute App → App Store Connect → Upload.

**In App Store Connect (appstoreconnect.apple.com)**
- [ ] Neue App anlegen (Name, Sprache Deutsch, Bundle-ID, SKU z. B. grizzlysarcade1).
- [ ] TestFlight: Build mit Vereinsmitgliedern testen.
- [ ] Texte aus Abschnitt 1 einfügen, Screenshots hochladen (6,9"-iPhone, z. B. aus dem Simulator «iPhone 18 Pro Max» mit ⌘S).
- [ ] App-Datenschutz: «Keine Daten erfasst». Altersfreigabe-Fragebogen ausfüllen.
- [ ] Zur Prüfung einreichen. Die Prüfung dauert meist 1–3 Tage.

## 3b. Screenshots
Im Ordner `app/store/` liegen 6 fertige Werbebilder (1290 × 2796 px, passend für 6,9"). Sie sind aus der Web-App erstellt. Apple verlangt Bilder aus der echten App: mache für den Upload zusätzlich Screenshots im Xcode-Simulator (⌘S) und lege sie in dieselben Rahmen, oder nimm die Simulator-Bilder direkt.

## 4. Technisch bereits erledigt
- Nur iPhone, nur Hochformat, iOS 16+
- Datenschutz-Manifest (PrivacyInfo.xcprivacy), Verschlüsselungs-Hinweis (ITSAppUsesNonExemptEncryption = NO)
- App-Icon 1024 px, Anzeigename «Grizzlys Arcade»
- Keine Werbung, kein Tracking, keine externen Links, Münzen nicht kaufbar

= Realisierung

== Programmierumgebung / Programmierrichtlinien

=== Programmierumgebung

Die Umsetzung des Prototyps erfolgt als Webanwendung unter Verwendung der Programmiersprache Elixir und des Webframeworks Phoenix in Kombination mit LiveView. Die Wahl dieser Technologien orientiert sich an etablierten Konventionen im Elixir-Ökosystem und unterstützt insbesondere die Entwicklung interaktiver, zustandsbehafteter Weboberflächen ohne komplexe clientseitige Logik.

Als Laufzeitumgebung dient die Erlang VM (BEAM), welche Nebenläufigkeit und hohe Stabilität gewährleistet. Für die Persistenz wird eine relationale Datenbank auf Basis von PostgreSQL eingesetzt. Der Datenzugriff erfolgt über Ecto, welches als Standardbibliothek für Datenbankinteraktionen im Phoenix-Umfeld gilt.

Das Projekt wird mit dem Build-Tool Mix verwaltet, welches ebenfalls integraler Bestandteil von Elixir ist. Die Versionsverwaltung erfolgt mit Git.

Die Anwendung wird lokal entwickelt und über einen Webbrowser ausgeführt. Eine produktive Deployment-Umgebung ist nicht Bestandteil dieser Arbeit, da der Fokus auf einem funktionsfähigen Prototyp liegt.

=== Projektstruktur

Die Struktur des Projekts folgt den durch Phoenix vorgegebenen Konventionen. Diese sehen eine klare Trennung zwischen Webschicht und Geschäftslogik vor.

Die Geschäftslogik wird in sogenannten Kontext-Modulen innerhalb des lib-Verzeichnisses implementiert. Diese Module kapseln zusammengehörige Funktionalitäten und stellen eine definierte Schnittstelle nach aussen bereit. Die Webschicht befindet sich im Verzeichnis lib/<app>\_web und umfasst LiveViews, Controller sowie zugehörige Templates.

Datenbankschemata und Migrationen werden im Verzeichnis priv/repo abgelegt. Tests befinden sich im Verzeichnis test und orientieren sich strukturell an den implementierten Modulen.

Diese Struktur entspricht den offiziellen Phoenix-Konventionen und unterstützt eine klare Organisation sowie eine gute Wartbarkeit des Codes.

=== Programmierrichtlinien

Die Implementierung orientiert sich an den idiomatischen Richtlinien von Elixir. Funktionen werden klein gehalten und erfüllen jeweils eine klar abgegrenzte Aufgabe. Die Kapselung von Logik erfolgt über Module, welche über wohldefinierte Schnittstellen miteinander interagieren.

Die Benennung von Modulen erfolgt in PascalCase, während Funktionen und Variablen in snake_case geschrieben werden. Diese Namenskonventionen entsprechen den üblichen Vorgaben der Elixir-Community.

Fehler werden nicht über Exceptions gesteuert, sondern über explizite Rückgabewerte in Form von Tupeln. Üblich ist die Verwendung von Konstrukten wie {:ok, result} und {:error, reason}. Dadurch bleibt der Kontrollfluss nachvollziehbar und funktional.

Validierungen von Daten erfolgen primär über Ecto Changesets. Diese ermöglichen eine zentrale Definition von Regeln und stellen sicher, dass nur konsistente Daten persistiert werden.

Der Zugriff auf die Datenbank erfolgt ausschliesslich über das Repository-Modul von Ecto. Direkte SQL-Abfragen werden vermieden, um die Abstraktionsebene beizubehalten und die Wartbarkeit zu erhöhen.

Die Trennung von Verantwortlichkeiten wird konsequent umgesetzt. Die Webschicht ist ausschliesslich für die Interaktion mit dem Benutzer zuständig, während die Geschäftslogik vollständig in den Kontext-Modulen implementiert ist. Dadurch bleibt die Anwendung modular und testbar.

Für die Benutzeroberfläche wird LiveView eingesetzt. Der Zustand der Anwendung wird serverseitig gehalten und über Events aktualisiert. Diese Vorgehensweise entspricht der von Phoenix vorgesehenen Architektur und reduziert die Komplexität im Frontend.

Externe Systeme wie Zahlungs- oder Buchhaltungsdienste werden über klar definierte Schnittstellen abstrahiert. Im Rahmen dieses Prototyps werden diese Systeme nicht real angebunden, sondern durch entsprechende Module simuliert.

=== Testbarkeit und Qualität

Die Teststrategie orientiert sich an den Möglichkeiten des Elixir-Testframeworks ExUnit. Zentrale Teile der Geschäftslogik werden durch automatisierte Tests überprüft. Dabei liegt der Fokus insbesondere auf kritischen Funktionen wie der Gebührenberechnung oder der Parkplatzzuweisung.

Abhängigkeiten zu externen Systemen werden durch Mock-Implementierungen ersetzt, sodass Tests unabhängig und reproduzierbar ausgeführt werden können.

Durch die klare Trennung von Logik und Präsentation sowie die Nutzung von Kontext-Modulen wird eine gute Testbarkeit der Anwendung erreicht.

=== Begründung der Technologieentscheidung

Die Wahl der Technologie basiert primär darauf, während der Erarbeitung des Prototypes eine neue Technologie zu lernen.

== Softwareaufbau

=== Modulstruktur

Die Anwendung ist gemäss den Phoenix-Konventionen in zwei klar getrennte Bereiche gegliedert: die Geschäftslogik unter `lib/parking/` und die Webschicht unter `lib/parking_web/`. Innerhalb dieser Bereiche sind die Verantwortlichkeiten auf spezialisierte Module aufgeteilt.

// TODO: Abbildung Modulübersicht / Paketdiagramm einfügen

=== Geschäftslogik

Das Modul `Parking.ParkingSystem` bildet den zentralen Einstiegspunkt für alle fachlichen Operationen. Es koordiniert die übrigen Module und stellt eine definierte Schnittstelle für die Webschicht bereit. Dazu gehören das Erstellen und Verwalten von Tickets, die Authentifizierung und Abwicklung von Dauermietern, die Gebührenberechnung sowie die Freigabe von Parkplätzen bei der Ausfahrt. Das Modul entspricht dem Fassaden-Muster: Die Webschicht interagiert ausschliesslich mit diesem Modul und nicht direkt mit den darunter liegenden Schemata oder Diensten.

Die Domänenentitäten sind als Ecto-Schemata implementiert. 

*Parking.ParkingGarage*

Repräsentiert ein Parkhaus und enthält den Namen sowie Verknüpfungen zu Stockwerken und Tarifen. 

*Parking.Level*

Stellt ein Stockwerk innerhalb eines Parkhauses mit Stockwerknummer und Parkplatzliste dar.

*Parking.ParkingSpot*

Entspricht einem einzelnen Parkplatz und hält dessen Belegungsstatus.

*Parking.Ticket*

Ist das Parkticket mit Einfahrtszeit, Ausfahrtszeit, Bezahlstatus sowie Verknüpfungen zu Parkplatz, Tarif und optional einem Dauermieter.

*Parking.Payment*

Speichert Zahlungsdatensätze mit Betrag und Zeitstempel.

*Parking.Pricing*

Enthält die Tarif-Konfiguration eines Parkhauses, den Typ (`time_based` oder `flat_rate`) und die gesamte Konfiguration werden als JSON-Map gespeichert.

*Parking.Users.PermanentUser*

Eepräsentiert den Dauermieter mit Zugangscode, Sperrstatus, Mietdaten und einem fixen Parkplatz.

=== Preisberechnungsstrategie

Die Gebührenberechnung ist über ein Elixir-Behaviour (`Parking.Pricing.PricingStrategy`) abstrahiert. Dieses definiert die Schnittstelle `calculate/2`, welche eine Strategie-Struktur und ein Ticket entgegennimmt und den geschuldeten Betrag zurückgibt.

`Parking.Pricing.TimeBasedPricing` berechnet die Gebühr anhand der Parkdauer und konfigurierbarer Zeitslots. Die Abrechnung erfolgt auf Viertelstundenbasis, wobei der zu Beginn der jeweiligen Viertelstunde geltende Tarif für die gesamte Viertelstunde gilt. Für Wochenenden und Feiertage können separate Zeitslot-Listen konfiguriert werden. Feiertage werden als Datumsliste in der Tarif-Konfiguration hinterlegt. Überschreitet die Parkdauer 24 Stunden, wird automatisch auf die Tagespauschale umgestellt. `Parking.Pricing.FlatRatePricing` bietet eine vereinfachte Alternative, die eine Tagespauschale unabhängig von der Tageszeit anwendet.

Die Wahl der anzuwendenden Strategie erfolgt im `ParkingSystem` anhand des `type`-Felds des Tarif-Datensatzes.

=== Serviceschicht

Externe Systeme werden über dedizierte Servicemodule angebunden. 

*Parking.Services.PaymentService*

Simuliert die Anbindung an ein externes Zahlungssystem. Im Prototyp gibt der Dienst stets eine Erfolgsantwort zurück. Für Tests existiert ein `FailingStub`, der eine fehlgeschlagene Zahlung simuliert.

*Parking.Services.AccountingService*

Simuliert die Buchung von Transaktionen in einem Buchhaltungssystem und ist im Prototyp als Stub implementiert.

*Parking.Services.StatisticsService*

Berechnet Umsatzdaten aus den gespeicherten Zahlungsdatensätzen und unterstützt Berechnungen nach Zeitraum, Monat und Jahr, jeweils aufgeschlüsselt nach Kundenkategorie.

Der aktiv genutzte Servicemodul wird über die Applikationskonfiguration bestimmt, was den Austausch gegen Test-Stubs ermöglicht, ohne den Produktionscode zu verändern.

== GUI-Implementierung

Die Benutzeroberfläche ist als Phoenix LiveView-Anwendung umgesetzt. Der Zustand der Oberfläche wird vollständig serverseitig verwaltet. Benutzerinteraktionen werden als Events an den Server übermittelt und führen zu einem gezielten Update der Seite. Die Anwendung ist über drei Routen erreichbar: `/` und `/garage/:garage_id` führen zur Parkhaus-Ansicht, `/admin` zur Administrationsoberfläche und `/stats` zur Statistik-Ansicht.

=== Parkhaus-Ansicht (ParkingLive)

Die Parkhaus-Ansicht bildet die primäre Schnittstelle für den Parkierungsprozess. Beim Laden der Seite wird das erste verfügbare Parkhaus ausgewählt. Über ein Auswahlmenü kann zwischen mehreren Parkhäusern gewechselt werden.

Für Gelegenheitsnutzer simuliert ein Klick auf die Einfahrtsschaltfläche das Drücken des Knopfs an der Eingangsschranke. Das System erstellt ein Ticket, weist einen freien Parkplatz zu und zeigt die Ticketdetails (UUID, Einfahrtszeit, zugewiesener Parkplatz) an. Anschliessend kann die Gebührenberechnung ausgelöst und der zu zahlende Betrag angezeigt werden. Nach der Bezahlung gibt die Ausfahrt-Schaltfläche den Parkplatz frei und markiert die Ausfahrtszeit. Über eine Scan-Funktion kann ein bestehendes Ticket anhand der UUID geladen werden, um dessen Status einzusehen oder die Bezahlung und Ausfahrt nachträglich vorzunehmen.

Für Dauermieter authentifiziert sich der Nutzer mit seinem Zugangscode. Das System prüft den Code sowie den Zahlungsstatus. Bei offener Miete ab dem 15. des Monats wird der Zugang verweigert. Nach erfolgreicher Anmeldung werden Einfahrt und Ausfahrt separat ausgelöst, wobei ein aktives Ticket erstellt beziehungsweise abgeschlossen und der Parkplatz entsprechend belegt oder freigegeben wird.

Zusätzlich zeigt die Seite eine tabellarische Übersicht aller Stockwerke und Parkplätze, wobei jeder Platz mit seinem Typ (Gast frei, Gast belegt, Dauermieter) gekennzeichnet ist.

// TODO: Screenshot Parkhaus-Ansicht (Einfahrt Gelegenheitsnutzer) einfügen
// TODO: Screenshot Parkhaus-Ansicht (Dauermieter-Bereich) einfügen
// TODO: Screenshot Parkplatz-Übersichtstabelle einfügen

=== Administrationsoberfläche (AdminLive)

Die Administrationsoberfläche ist durch ein Passwort geschützt. Erst nach erfolgreicher Anmeldung werden die Verwaltungsfunktionen freigeschaltet und die Dauermieterliste des ausgewählten Parkhauses angezeigt. Die Tabelle enthält Name, Zugangscode, zugewiesenen Parkplatz, Sperrstatus sowie das Datum, bis zu dem die Miete bezahlt ist.

Ein neuer Dauermieter wird mit automatisch generiertem UUID-Zugangscode angelegt. Das System weist ihm automatisch den nächsten freien Parkplatz zu und zeigt den generierten Code nach der Erstellung an. Die Miete eines Dauermieters kann als bezahlt markiert werden, wodurch das `rent_paid_until`-Datum um einen Monat verlängert und ein allfälliger Sperrstatus aufgehoben wird. Zusätzlich kann der Sperrstatus einzelner Dauermieter manuell umgeschaltet werden.

// TODO: Screenshot Administrationsoberfläche einfügen

=== Statistik-Ansicht (StatsLive)

Die Statistik-Ansicht zeigt Belegungs- und Umsatzdaten für das ausgewählte Parkhaus. Die Daten werden beim Laden der Seite berechnet und sind per Parkhaus-Auswahlmenü filterbar.

Die Belegungsstatistik umfasst die Gesamtanzahl Parkplätze, aufgeteilt nach Dauermieter-Plätzen, belegten Gast-Plätzen und freien Gast-Plätzen, sowie die Auslastungsquote in Prozent. Der Monatsumsatz zeigt den Umsatz des laufenden Monats, der Jahresumsatz jenen des laufenden Jahres. Beide werden nach Gelegenheitsnutzern und Dauermietern aufgeschlüsselt dargestellt.

// TODO: Screenshot Statistik-Ansicht einfügen

== Datenbankimplementierung und -anbindung

=== Datenbankschema

Die Persistenz erfolgt über eine relationale PostgreSQL-Datenbank. Das Schema wird durch Ecto-Migrationen verwaltet, welche eine nachvollziehbare und reproduzierbare Datenbankstruktur sicherstellen.

#figure(
  table(
    align: left,
    columns: (auto, 1fr),
    table.header([*Tabelle*], [*Beschreibung*]),
    [`parking_garage`], [Parkhaus mit Name],
    [`level`], [Stockwerk mit Nummer und Verweis auf das Parkhaus],
    [`parking_spot`], [Parkplatz mit Belegungsstatus und Verweis auf das Stockwerk],
    [`ticket`], [Parkticket mit UUID-Primärschlüssel, Ein-/Ausfahrtszeit, Bezahlstatus sowie Verweisen auf Parkplatz, Tarif und optional Dauermieter],
    [`pricing`], [Tarif-Konfiguration mit Typ und JSON-Konfigurationsfeld, verknüpft mit einem Parkhaus],
    [`payment`], [Zahlungsdatensatz mit Betrag, Zeitstempel und Verweis auf das Ticket],
    [`user`], [Basisentität für alle Benutzer mit Typenfeld],
    [`permanent_user`], [Dauermieter mit Zugangscode, Sperrstatus, Mietdaten und zugewiesenem Parkplatz],
    [`settings`], [Schlüssel-Wert-Tabelle für systemweite Konfigurationsparameter wie das Admin-Passwort],
  ),
  caption: [Datenbankstruktur]
)

// TODO: ERD-Abbildung einfügen

=== Designentscheidungen

#heading(outlined: false, level: 4)[UUID als Primärschlüssel für Tickets]

Tickets verwenden einen UUID-Primärschlüssel (`binary_id`). Dies ermöglicht die sichere Übergabe der Ticket-ID an den Benutzer (z.B. zur Anzeige am Bildschirm oder als QR-Code), ohne dass sequentielle IDs erraten werden können.

#heading(outlined: false, level: 4)[JSON-Konfiguration für Tarife]

Die Tarif-Konfiguration wird als strukturierte JSON-Map im `config`-Feld gespeichert. Dieses Vorgehen erlaubt flexible Konfigurationen (unterschiedliche Zeitslots, Feiertage, Tagespauschalen) ohne Änderungen am Datenbankschema. Der Tarif-Typ bestimmt, wie das System das Konfigurationsfeld interpretiert.

#heading(outlined: false, level: 4)[Migrationsbasierte Schemaevolution]

Alle Schemaänderungen werden als Ecto-Migrationen eingecheckt. Dies stellt sicher, dass der Datenbankzustand zu jedem Zeitpunkt aus dem Quellcode reproduziert werden kann.

=== Datenzugriff

Der Datenzugriff erfolgt ausschliesslich über das Ecto-Repository-Modul (`Parking.Repo`). Direkte SQL-Abfragen werden nicht verwendet. Komplexere Abfragen – etwa die Suche nach dem nächsten freien Parkplatz mit ausgeglichener Verteilung oder die Umsatzauswertung nach Kundenkategorie – werden über die Ecto-Query-DSL formuliert.

Ecto-Changesets werden für alle schreibenden Operationen eingesetzt. Sie zentralisieren die Validierungsregeln und stellen sicher, dass nur konsistente Daten in die Datenbank gelangen.

=== Externe Systemanbindung

Zahlungssystem und Buchhaltung sind gemäss Aufgabenstellung nicht Bestandteil der Software und werden über Schnittstellen angebunden. Im Prototyp sind diese Systeme als Stub-Module implementiert, welche die Schnittstelle erfüllen, aber keine reale Anbindung besitzen. Für Testzwecke kann der `PaymentService` über die Applikationskonfiguration durch einen `FailingStub` ersetzt werden, der eine fehlgeschlagene Zahlung zurückgibt.

== Testprotokoll

=== Teststrategie

Die Tests werden mit ExUnit, dem in Elixir integrierten Testframework, durchgeführt. Für Tests, die Datenbankzugriffe erfordern, wird `Parking.DataCase` verwendet. Dieses setzt jede Testgruppe in eine Datenbanktransaktion, welche nach dem Test zurückgerollt wird. Dadurch sind alle Tests voneinander isoliert und hinterlassen keinen Zustand in der Testdatenbank. Externe Abhängigkeiten werden durch Stub-Implementierungen ersetzt, sodass Tests ohne reale Systemanbindung ausgeführt werden können.

=== Testfälle

#[
  #show figure: set align(left)
  #figure(
    table(
      columns: 2,
      [*ID*], [TC-01],
      [*Beschreibung*], [Einfahrt erzeugt Ticket],
      [*Vorgehen*], [`ParkingSystem.create_ticket/2` wird mit einer gültigen Garage-ID und Tarif-ID aufgerufen.],
      [*Erwartetes Ergebnis*], [Ticket wird erstellt und gespeichert],
      [*Tatsächliches Ergebnis*], [Ticket mit gültiger UUID und Einfahrtszeit wird erstellt. Der zugehörige Parkplatz wird als belegt markiert.],
      [*Status*], [Bestanden],
      [*Referenz*], [F-04, F-05],
    ),
    caption: [Testergebnis TC-01]
  )
]

#[
  #show figure: set align(left)
  #figure(
    table(
      columns: 2,
      [*ID*], [TC-02],
      [*Beschreibung*], [Parkplatz wird zugewiesen],
      [*Vorgehen*], [Nach der Einfahrt wird der dem Ticket zugewiesene Parkplatz aus der Datenbank gelesen.],
      [*Erwartetes Ergebnis*], [Freier Parkplatz wird belegt],
      [*Tatsächliches Ergebnis*], [Parkplatz ist als belegt markiert (`is_occupied: true`).],
      [*Status*], [Bestanden],
      [*Referenz*], [F-07, F-16],
    ),
    caption: [Testergebnis TC-02]
  )
]

#[
  #show figure: set align(left)
  #figure(
    table(
      columns: 2,
      [*ID*], [TC-03],
      [*Beschreibung*], [Parkdauer wird berechnet],
      [*Vorgehen*], [Ein Ticket mit bekannter Einfahrts- und Ausfahrtszeit (2 Stunden) wird an `TimeBasedPricing.calculate/2` übergeben.],
      [*Erwartetes Ergebnis*], [Zeitdifferenz ist korrekt],
      [*Tatsächliches Ergebnis*], [Der berechnete Betrag entspricht dem erwarteten Wert auf Basis der Parkdauer.],
      [*Status*], [Bestanden],
      [*Referenz*], [F-09],
    ),
    caption: [Testergebnis TC-03]
  )
]

#[
  #show figure: set align(left)
  #figure(
    table(
      columns: 2,
      [*ID*], [TC-04],
      [*Beschreibung*], [Gebühr wird korrekt berechnet],
      [*Vorgehen*], [Tickets mit verschiedenen Parkdauern und Tarif-Konfigurationen werden berechnet: Grundtarif, Tageszeit-Slot und Wochenend-Slot.],
      [*Erwartetes Ergebnis*], [Betrag entspricht Tarif],
      [*Tatsächliches Ergebnis*], [Berechnete Beträge stimmen in allen drei Szenarien mit den erwarteten Werten überein.],
      [*Status*], [Bestanden],
      [*Referenz*], [F-10, F-11],
    ),
    caption: [Testergebnis TC-04]
  )
]

#[
  #show figure: set align(left)
  #figure(
    table(
      columns: 2,
      [*ID*], [TC-05],
      [*Beschreibung*], [Viertelstundenabrechnung],
      [*Vorgehen*], [Tickets mit 45 Minuten und 5 Minuten Parkdauer werden an `TimeBasedPricing.calculate/2` übergeben.],
      [*Erwartetes Ergebnis*], [Rundung erfolgt korrekt],
      [*Tatsächliches Ergebnis*], [45 Minuten werden als 3 vollständige Viertelstunden verrechnet. 5 Minuten werden als 1 Viertelstunde verrechnet.],
      [*Status*], [Bestanden],
      [*Referenz*], [F-12],
    ),
    caption: [Testergebnis TC-05]
  )
]

#[
  #show figure: set align(left)
  #figure(
    table(
      columns: 2,
      [*ID*], [TC-06],
      [*Beschreibung*], [Tagespauschale greift],
      [*Vorgehen*], [Ein Ticket mit 25 Stunden Parkdauer wird an `TimeBasedPricing.calculate/2` übergeben.],
      [*Erwartetes Ergebnis*], [Pauschale wird angewendet],
      [*Tatsächliches Ergebnis*], [Es werden 2 Tagespauschalen à CHF 20.00 berechnet (CHF 40.00 total). Der Stundentarif wird nicht angewendet.],
      [*Status*], [Bestanden],
      [*Referenz*], [F-13],
    ),
    caption: [Testergebnis TC-06]
  )
]

#[
  #show figure: set align(left)
  #figure(
    table(
      columns: 2,
      [*ID*], [TC-07],
      [*Beschreibung*], [Dauermieter Zugang erlaubt],
      [*Vorgehen*], [`ParkingSystem.authenticate_permanent_user/1` wird mit dem korrekten Zugangscode eines nicht gesperrten Dauermieters aufgerufen.],
      [*Erwartetes Ergebnis*], [Schranke öffnet],
      [*Tatsächliches Ergebnis*], [Authentifizierung erfolgreich. Dauermieter-Datensatz wird zurückgegeben.],
      [*Status*], [Bestanden],
      [*Referenz*], [F-06],
    ),
    caption: [Testergebnis TC-07]
  )
]

#[
  #show figure: set align(left)
  #figure(
    table(
      columns: 2,
      [*ID*], [TC-08],
      [*Beschreibung*], [Dauermieter gesperrt],
      [*Vorgehen*], [Der Dauermieter wird als gesperrt markiert. Anschliessend wird `authenticate_permanent_user/1` aufgerufen.],
      [*Erwartetes Ergebnis*], [Zugang verweigert],
      [*Tatsächliches Ergebnis*], [`{:error, {:blocked, perm_user}}` wird zurückgegeben.],
      [*Status*], [Bestanden],
      [*Referenz*], [F-14],
    ),
    caption: [Testergebnis TC-08]
  )
]

#[
  #show figure: set align(left)
  #figure(
    table(
      columns: 2,
      [*ID*], [TC-09],
      [*Beschreibung*], [Bezahlung erfolgreich],
      [*Vorgehen*], [`ParkingSystem.process_payment/1` wird mit einem bestehenden, unbezahlten Ticket aufgerufen.],
      [*Erwartetes Ergebnis*], [Ticket wird als bezahlt markiert],
      [*Tatsächliches Ergebnis*], [Ticket erhält `paid: true`. Ein Zahlungsdatensatz wird in der Datenbank erstellt.],
      [*Status*], [Bestanden],
      [*Referenz*], [F-10],
    ),
    caption: [Testergebnis TC-09]
  )
]

#[
  #show figure: set align(left)
  #figure(
    table(
      columns: 2,
      [*ID*], [TC-10],
      [*Beschreibung*], [Bezahlung fehlgeschlagen],
      [*Vorgehen*], [Der `PaymentService` wird durch einen `FailingStub` ersetzt. Anschliessend wird `process_payment/1` aufgerufen.],
      [*Erwartetes Ergebnis*], [Fehlermeldung wird angezeigt],
      [*Tatsächliches Ergebnis*], [`{:error, :payment_failed}` wird zurückgegeben, Die Transaktion wird zurückgerollt. Das Ticket bleibt unbezahlt und der Parkplatz belegt.],
      [*Status*], [Bestanden],
      [*Referenz*], [NF-01],
    ),
    caption: [Testergebnis TC-10]
  )
]

#[
  #show figure: set align(left)
  #figure(
    table(
      columns: 2,
      [*ID*], [TC-11],
      [*Beschreibung*], [Ausfahrt mit gültigem Ticket],
      [*Vorgehen*], [Nach Einfahrt und Bezahlung wird `ParkingSystem.register_exit/1` aufgerufen.],
      [*Erwartetes Ergebnis*], [Ausfahrt wird erlaubt],
      [*Tatsächliches Ergebnis*], [Ausfahrtszeit wird auf dem Ticket gesetzt. Der Parkplatz wird als frei markiert.],
      [*Status*], [Bestanden],
      [*Referenz*], [F-15],
    ),
    caption: [Testergebnis TC-11]
  )
]

#[
  #show figure: set align(left)
  #figure(
    table(
      columns: 2,
      [*ID*], [TC-12],
      [*Beschreibung*], [Ausfahrt ohne Zahlung],
      [*Vorgehen*], [Nach der Einfahrt wird `register_exit/1` ohne vorherige Bezahlung aufgerufen.],
      [*Erwartetes Ergebnis*], [Ausfahrt wird verweigert],
      [*Tatsächliches Ergebnis*], [`{:error, :payment_required}` wird zurückgegeben. Der Parkplatz bleibt belegt.],
      [*Status*], [Bestanden],
      [*Referenz*], [F-10],
    ),
    caption: [Testergebnis TC-12]
  )
]

#[
  #show figure: set align(left)
  #figure(
    table(
      columns: 2,
      [*ID*], [TC-13],
      [*Beschreibung*], [Statistik wird erzeugt],
      [*Vorgehen*], [Zahlungsdatensätze für Gelegenheitsnutzer und Dauermieter werden in der Testdatenbank angelegt. `StatisticsService.calculate_revenue_by_period/3` wird aufgerufen.],
      [*Erwartetes Ergebnis*], [Daten werden korrekt angezeigt],
      [*Tatsächliches Ergebnis*], [Summen nach Kundenkategorie stimmen mit den erwarteten Werten überein. Gelegenheitsnutzer- und Dauermieter-Umsätze werden korrekt getrennt ausgewiesen.],
      [*Status*], [Bestanden],
      [*Referenz*], [F-17],
    ),
    caption: [Testergebnis TC-13]
  )
]

#[
  #show figure: set align(left)
  #figure(
    table(
      columns: 2,
      [*ID*], [TC-14],
      [*Beschreibung*], [Monatsumsatz korrekt],
      [*Vorgehen*], [Zahlungsdatensätze für den laufenden Monat werden angelegt. `StatisticsService.calculate_monthly_revenue/3` wird aufgerufen.],
      [*Erwartetes Ergebnis*], [Umsatz stimmt],
      [*Tatsächliches Ergebnis*], [Berechneter Monatsumsatz stimmt mit der Summe der angelegten Zahlungen überein.],
      [*Status*], [Bestanden],
      [*Referenz*], [F-18],
    ),
    caption: [Testergebnis TC-14]
  )
]

#[
  #show figure: set align(left)
  #figure(
    table(
      columns: 2,
      [*ID*], [TC-15],
      [*Beschreibung*], [System reagiert schnell],
      [*Vorgehen*], [Manueller Test — Einfahrt, Bezahlung und Ausfahrt werden über die Weboberfläche ausgeführt. Die Reaktionszeit wird beobachtet.],
      [*Erwartetes Ergebnis*], [Antwortzeit < definierter Schwelle],
      [*Tatsächliches Ergebnis*], [Alle Aktionen reagieren unmittelbar. Keine spürbaren Verzögerungen festgestellt.],
      [*Status*], [Bestanden],
      [*Referenz*], [NF-02],
    ),
    caption: [Testergebnis TC-15]
  )
]

#[
  #show figure: set align(left)
  #figure(
    table(
      columns: 2,
      [*ID*], [TC-16],
      [*Beschreibung*], [System bleibt stabil],
      [*Vorgehen*], [Manueller Test — Mehrere Einfahrten und Ausfahrten werden in Folge durchgeführt. Das System wird auf Abstürze und Fehler beobachtet.],
      [*Erwartetes Ergebnis*], [Keine Abstürze bei Wiederholung],
      [*Tatsächliches Ergebnis*], [System bleibt stabil. Keine Fehler oder unerwarteten Zustände aufgetreten.],
      [*Status*], [Bestanden],
      [*Referenz*], [NF-01],
    ),
    caption: [Testergebnis TC-16]
  )
]

#[
  #show figure: set align(left)
  #figure(
    table(
      columns: 2,
      [*ID*], [TC-17],
      [*Beschreibung*], [Daten bleiben konsistent],
      [*Vorgehen*], [Eine fehlgeschlagene Zahlung wird über den `FailingStub` simuliert. Anschliessend werden Ticket und Parkplatz aus der Datenbank gelesen.],
      [*Erwartetes Ergebnis*], [Keine inkonsistenten Zustände],
      [*Tatsächliches Ergebnis*], [Ticket bleibt unbezahlt. Parkplatz bleibt belegt. Kein Zahlungsdatensatz wurde erstellt.],
      [*Status*], [Bestanden],
      [*Referenz*], [NF-04, NF-07],
    ),
    caption: [Testergebnis TC-17]
  )
]

#[
  #show figure: set align(left)
  #figure(
    table(
      columns: 2,
      [*ID*], [TC-18],
      [*Beschreibung*], [Benutzeroberfläche verständlich],
      [*Vorgehen*], [Manueller Test — Die Weboberfläche wird ohne Anleitung bedient. Alle Kernfunktionen werden ausgeführt.],
      [*Erwartetes Ergebnis*], [Bedienung ohne Anleitung möglich],
      [*Tatsächliches Ergebnis*], [Alle Kernfunktionen (Einfahrt, Bezahlung, Ausfahrt, Dauermieter-Verwaltung) sind intuitiv zugänglich.],
      [*Status*], [Bestanden],
      [*Referenz*], [NF-03],
    ),
    caption: [Testergebnis TC-18]
  )
]

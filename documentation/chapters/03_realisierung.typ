= Realisierung

== Programmierumgebung / Programmierrichtlinien

=== Programmierumgebung

Die Umsetzung des Prototyps erfolgt als Webanwendung unter Verwendung der Programmiersprache Elixir und des Webframeworks Phoenix in Kombination mit LiveView. Die Wahl dieser Technologien orientiert sich an etablierten Konventionen im Elixir-Ökosystem und unterstützt insbesondere die Entwicklung interaktiver, zustandsbehafteter Weboberflächen ohne komplexe clientseitige Logik.

Als Laufzeitumgebung dient die Erlang VM (BEAM). Die BEAM wurde ursprünglich für Telekommunikationssysteme entwickelt, bei denen hohe Verfügbarkeit und gleichzeitige Verarbeitung vieler unabhängiger Vorgänge zentrale Anforderungen sind. Sie ermöglicht die parallele Ausführung von Millionen leichtgewichtiger Prozesse, die vollständig voneinander isoliert sind. Tritt in einem Prozess ein Fehler auf, bleibt der Rest des Systems davon unberührt. Für dieses Projekt bedeutet das konkret: Mehrere Parkvorgänge können gleichzeitig abgewickelt werden, ohne dass sich die Prozesse gegenseitig beeinflussen. Ein Fehler bei einer Einfahrt oder Zahlung gefährdet nicht die Stabilität des gesamten Systems.

Für die Persistenz wird eine relationale Datenbank auf Basis von PostgreSQL eingesetzt. Der Datenzugriff erfolgt über Ecto, welches als Standardbibliothek für Datenbankinteraktionen im Phoenix-Umfeld gilt.

Das Projekt wird mit dem Build-Tool Mix verwaltet, welches ebenfalls integraler Bestandteil von Elixir ist. Die Versionsverwaltung erfolgt mit Git.

Die Anwendung wird lokal entwickelt und über einen Webbrowser ausgeführt. Eine produktive Deployment-Umgebung ist nicht Bestandteil dieser Arbeit, da der Fokus auf einem funktionsfähigen Prototyp liegt.

=== Projektstruktur

Die Struktur des Projekts folgt den durch Phoenix vorgegebenen Konventionen. Diese sehen eine klare Trennung zwischen Webschicht und Geschäftslogik vor, was auch dem erarbeiteten Konzept entspricht.

Die Geschäftslogik wird in sogenannten Kontext-Modulen innerhalb des lib-Verzeichnisses implementiert. Diese Module kapseln zusammengehörige Funktionalitäten und stellen eine definierte Schnittstelle nach aussen bereit. Die Webschicht befindet sich im Verzeichnis lib/parking_web und umfasst LiveViews, Controller sowie zugehörige Templates.

Datenbankschemata und Migrationen werden im Verzeichnis priv/repo abgelegt. Eine Migration ist ein versioniertes Skript, das eine Änderung am Datenbankschema beschreibt, z.B. das Erstellen einer Tabelle oder das Hinzufügen einer Spalte. Migrationen werden sequenziell ausgeführt und erlauben es, den Datenbankzustand jederzeit aus dem Quellcode herzustellen oder schrittweise weiterzuentwickeln. Gegenüber einer direkten Anpassung der Datenbank hat dieser Ansatz den Vorteil, dass Schemaänderungen versioniert und nachvollziehbar im Quellcode festgehalten sind. Jede Änderung kann so auf einer neuen Umgebung reproduziert werden, ohne dass die Datenbankstruktur manuell nachgezogen werden muss. 

Tests befinden sich im Verzeichnis test und orientieren sich strukturell an den implementierten Modulen.

Diese Struktur entspricht den offiziellen Phoenix-Konventionen und unterstützt eine klare Organisation sowie eine gute Wartbarkeit des Codes.

=== Programmierrichtlinien

Die Implementierung orientiert sich an den Richtlinien von Elixir. Funktionen werden klein gehalten und erfüllen jeweils eine klar abgegrenzte Aufgabe. Die Kapselung von Logik erfolgt über Module, welche über wohldefinierte Schnittstellen miteinander interagieren.

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

== Softwareaufbau

=== Modulstruktur

Die Anwendung ist gemäss den Phoenix-Konventionen in zwei klar getrennte Bereiche gegliedert: die Geschäftslogik unter `lib/parking/` und die Webschicht unter `lib/parking_web/`. Innerhalb dieser Bereiche sind die Verantwortlichkeiten auf spezialisierte Module aufgeteilt.

#figure(
  image("../diagrams/Moduluebersicht.png", width: 100%),
  caption: [Modulübersicht]
)

=== Geschäftslogik

Die Geschäftslogik ist auf vier spezialisierte Kontextmodule aufgeteilt, welche die Webschicht als definierte Schnittstelle nutzt.

*Parking.GuestParking*

Koordiniert den Parkierungsprozess für Gelegenheitsnutzer: Erstellen von Tickets, Zuweisung von Parkplätzen mit ausgeglichener Stockwerkverteilung, Zahlungsabwicklung und Registrierung der Ausfahrt.

*Parking.PermanentParking*

Kapselt alle Operationen für Dauermieter: Authentifizierung, Ein- und Ausfahrt, Erstellung neuer Dauermieter, Mietabrechnung sowie Platzzuweisung.

*Parking.GarageStats*

Berechnet und liefert Belegungs- und Zustandsdaten eines Parkhauses, aufgeschlüsselt nach Parkplatztypen.

*Parking.Pricing.Calculator*

Übernimmt die Gebührenberechnung: Liest die Tarif-Konfiguration aus der Datenbank, wählt die passende Pricing-Strategie und delegiert die Berechnung an die entsprechende Implementierung.

Die Domänenentitäten sind als Ecto-Schemata implementiert.

*Parking.ParkingGarage*

Repräsentiert ein Parkhaus und enthält den Namen sowie Verknüpfungen zu Stockwerken und Tarifen. 

*Parking.Level*

Stellt ein Stockwerk innerhalb eines Parkhauses mit Stockwerknummer und Parkplatzliste dar.

*Parking.ParkingSpot*

Entspricht einem einzelnen Parkplatz mit einer lesbaren Platznummer (`number`). Die Platznummer wird nach dem Schema Stockwerknummer × 100 + laufende Nummer vergeben, sodass Platz 3 auf Stockwerk 2 die Nummer 203 trägt. Der Belegungsstatus wird nicht als eigenes Feld gespeichert, sondern zur Laufzeit aus aktiven Tickets abgeleitet: Ein Parkplatz gilt als belegt, wenn ein Ticket mit dieser Platz-ID existiert, dessen `exit_time` noch nicht gesetzt ist. Die Zuweisung eines Parkplatzes erfolgt beim Erstellen des Tickets. Im Konzept war ein dreistufiger Lebenszyklus (frei, reserviert, belegt) vorgesehen; eine explizite Reservierungsphase wird im Prototyp nicht benötigt und wurde nicht umgesetzt.

*Parking.Ticket*

Ist das Parkticket mit Einfahrtszeit, Ausfahrtszeit sowie Verknüpfungen zu Parkplatz, Tarif und optional einem Dauermieter. Im Konzept war ein explizites `paid`-Feld vorgesehen; in der Umsetzung entfällt dieses, da der Bezahlstatus aus der Existenz eines verknüpften `Payment`-Datensatzes abgeleitet wird.

*Parking.Payment*

Speichert Zahlungsdatensätze mit Betrag und Verweis auf das Ticket. Der Zeitstempel wird automatisch über das Ecto-Feld `inserted_at` gesetzt.

*Parking.Pricing*

Enthält den Tarif-Typ eines Parkhauses und verknüpft die zugehörige Konfiguration über typisierte Untertabellen. Unterstützte Typen sind `time_based`, `daily_rate` und `monthly_rent`. Die Konfigurationsdetails werden in separaten Tabellen (`time_based_pricing`, `daily_rate_pricing`, `monthly_rent_pricing`) gespeichert, die jeweils nur die für den jeweiligen Typ relevanten Felder enthalten. Die Monatsmiete ist damit pro Parkhaus konfigurierbar.

*Parking.Users.PermanentUser*

Repräsentiert den Dauermieter mit Zugangscode, Sperrstatus, Mietdaten und einem fixen Parkplatz.

Die Entität `Parking.Users.OccasionalUser` existiert als Ecto-Schema zur Vervollständigung des Datenmodells, enthält jedoch ausser der ID-Verknüpfung zur `User`-Tabelle keine weiteren Felder. Bei der Einfahrt eines Gelegenheitsnutzers wird kein `OccasionalUser`-Datensatz angelegt — der Parkvorgang wird vollständig über das Ticket abgebildet.

=== Preisberechnungsstrategie

Die Gebührenberechnung ist über ein Elixir-Behaviour (`Parking.Pricing.PricingStrategy`) abstrahiert. Dieses definiert die Schnittstelle `calculate/2`, welche eine Strategie-Struktur und ein Ticket entgegennimmt und den geschuldeten Betrag zurückgibt.

`Parking.Pricing.TimeBasedPricing` berechnet die Gebühr anhand der Parkdauer und konfigurierbarer Zeitslots. Die Abrechnung erfolgt auf Viertelstundenbasis, wobei der zu Beginn der jeweiligen Viertelstunde geltende Tarif für die gesamte Viertelstunde gilt. Für Wochenenden und Feiertage können separate Zeitslot-Listen konfiguriert werden. Feiertage werden als Datumsliste in der Tarif-Konfiguration hinterlegt. Überschreitet die Parkdauer 24 Stunden, wird automatisch auf die Tagespauschale umgestellt. `Parking.Pricing.FlatRatePricing` bietet eine vereinfachte Alternative, die eine Tagespauschale unabhängig von der Tageszeit anwendet. Die Konfiguration der jeweiligen Strategie wird aus den typisierten Untertabellen gelesen.

Die Wahl der anzuwendenden Strategie erfolgt im `Calculator` anhand des `type`-Felds des Tarif-Datensatzes.

=== Serviceschicht

Externe Systeme werden über dedizierte Servicemodule angebunden. 

*Parking.Services.PaymentService*

Simuliert die Anbindung an ein externes Zahlungssystem. Im Prototyp gibt der Dienst stets eine Erfolgsantwort zurück. Für Tests existiert ein `FailingStub`, der eine fehlgeschlagene Zahlung simuliert.

*Parking.Services.AccountingService*

Simuliert die Buchung von Transaktionen in einem Buchhaltungssystem und ist im Prototyp als Stub implementiert.

*Parking.Services.StatisticsService*

Berechnet Umsatzdaten aus den gespeicherten Zahlungsdatensätzen und unterstützt Berechnungen nach Zeitraum, Monat und Jahr, jeweils aufgeschlüsselt nach Kundenkategorie.

Das aktiv genutzte Servicemodul wird über die Applikationskonfiguration bestimmt, was den Austausch gegen Test-Stubs ermöglicht, ohne den Produktionscode zu verändern.

== GUI-Implementierung

Die Benutzeroberfläche ist als Phoenix LiveView-Anwendung umgesetzt. Der Zustand der Oberfläche wird vollständig serverseitig verwaltet. Benutzerinteraktionen werden als Events an den Server übermittelt und führen zu einem gezielten Update der Seite. Die Anwendung ist über drei Routen erreichbar: `/` und `/garage/:garage_id` führen zur Parkhaus-Ansicht, `/admin` zur Administrationsoberfläche und `/stats` zur Statistik-Ansicht.

=== Parkhaus-Ansicht (ParkingLive)

Die Parkhaus-Ansicht bildet die primäre Schnittstelle für den Parkierungsprozess. Beim Laden der Seite wird das erste verfügbare Parkhaus ausgewählt. Über ein Auswahlmenü kann zwischen mehreren Parkhäusern gewechselt werden.

Für Gelegenheitsnutzer simuliert ein Klick auf die Einfahrtsschaltfläche das Drücken des Knopfs an der Eingangsschranke. Das System erstellt ein Ticket, weist einen freien Parkplatz zu und zeigt die Ticketdetails (UUID, Einfahrtszeit, zugewiesener Parkplatz) sowie die bis dahin aufgelaufene Gebühr direkt an. Die angezeigte Gebühr wird serverseitig bei jeder Interaktion neu berechnet. Nach der Bezahlung gibt die Ausfahrt-Schaltfläche den Parkplatz frei und markiert die Ausfahrtszeit. Über eine Scan-Funktion kann ein bestehendes Ticket anhand der UUID geladen werden, um dessen Status einzusehen oder die Bezahlung und Ausfahrt nachträglich vorzunehmen. Das im Konzept vorgesehene eigenständige Austrittsticket (F-21) wird nicht als separates digitales Dokument generiert. Bezahlstatus und Ausfahrtszeit werden direkt auf dem bestehenden Ticket in der Weboberfläche angezeigt. Ein physisches Ticket, das beispielsweise ausgedruckt werden könnte, ist im Prototyp nicht vorgesehen, könnte aber unabhängig gedruckt werden, auch wenn kein neues digitales Dokument erstellt wird.

Für Dauermieter authentifiziert sich der Nutzer mit seinem Zugangscode. Das System prüft den Code sowie den Zahlungsstatus. Die Sperrlogik unterscheidet zwei Fälle: Ist die Miete zwei oder mehr Monate im Rückstand, erfolgt die Sperrung sofort. Ist die Miete genau einen Monat im Rückstand, gilt eine Frist bis zum 15. des laufenden Monats. Nach erfolgreicher Anmeldung werden Einfahrt und Ausfahrt separat ausgelöst, wobei ein aktives Ticket erstellt beziehungsweise abgeschlossen und der Parkplatz entsprechend belegt oder freigegeben wird.

#figure(
  image("/documentation/screenshots/Einfahrt_gelegenheit.png", width: 100%),
  caption: [Einfahrt Gelegenheitsnutzer]
)

#figure(
  image("/documentation/screenshots/Einfahrt_permanent.png", width: 100%),
  caption: [Dauermieter-Bereich]
)




=== Administrationsoberfläche (AdminLive)

Die Administrationsoberfläche ist durch ein Passwort geschützt. Erst nach erfolgreicher Anmeldung werden die Verwaltungsfunktionen freigeschaltet und die Dauermieterliste des ausgewählten Parkhauses angezeigt. Eine Oberfläche zur Konfiguration von Parkhäusern, Stockwerken und Parkplätzen (F-01, F-02) ist nicht implementiert. Diese Konfiguration erfolgt im Prototyp über Datenbankmigrationen und Seed-Daten. Die Tabelle enthält Name, Zugangscode, zugewiesenen Parkplatz, Sperrstatus sowie das Datum, bis zu dem die Miete bezahlt ist.

Ein neuer Dauermieter wird mit automatisch generiertem UUID-Zugangscode angelegt. Das System weist ihm automatisch den nächsten freien Parkplatz zu und zeigt den generierten Code nach der Erstellung an. Bei der Erstellung wird die erste Monatsmiete sofort als Ticket- und Zahlungsdatensatz erfasst, sodass der Dauermieter ab dem ersten Tag Zugang erhält. Die Miete eines Dauermieters kann als bezahlt markiert werden, wodurch das `rent_paid_until`-Datum um einen Monat verlängert, ein Ticket sowie ein Zahlungsdatensatz für die Miete erstellt und ein allfälliger Sperrstatus aufgehoben wird. Zusätzlich kann der Sperrstatus einzelner Dauermieter manuell umgeschaltet werden. Einem Dauermieter kann nachträglich ein anderer freier Parkplatz zugewiesen werden, sofern er aktuell nicht parkiert.

#figure(
  image("/documentation/screenshots/Admin_login.png", width: 100%),
  caption: [Admin Login]
)
#figure(
  image("/documentation/screenshots/Admin_Ansicht.png", width: 100%),
  caption: [Admin Ansicht]
)

=== Statistik-Ansicht (StatsLive)

Die Statistik-Ansicht zeigt Belegungs- und Umsatzdaten für das ausgewählte Parkhaus. Die Daten werden beim Laden der Seite berechnet und sind per Parkhaus-Auswahlmenü filterbar.

Die Belegungsstatistik umfasst die Gesamtanzahl Parkplätze, aufgeteilt nach Dauermieter-Plätzen, belegten Gast-Plätzen und freien Gast-Plätzen, sowie die Auslastungsquote in Prozent. Der Monatsumsatz zeigt den Umsatz des laufenden Monats, der Jahresumsatz jenen des laufenden Jahres. Beide werden nach Gelegenheitsnutzern und Dauermietern aufgeschlüsselt dargestellt. Die für das Parkaus erfassten Tarife, Tagespauschale und Dauermieten werden aufgelistet.  

#figure(
  image("/documentation/screenshots/Parkstatistiken.png", width: 100%),
  caption: [Statistik-Ansicht]
)

Zusätzlich zeigt die Seite eine tabellarische Übersicht aller Stockwerke und Parkplätze, wobei jeder Platz mit seinem Typ (Gast frei, Gast belegt, Dauermieter frei, Dauermieter belegt) gekennzeichnet ist.

#figure(
  image("/documentation/screenshots/Etagen.png", width: 100%),
  caption: [Etagen Ansicht]
)

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
    [`parking_spot`], [Parkplatz mit lesbarer Platznummer und Verweis auf das Stockwerk; Belegungsstatus wird aus aktiven Tickets abgeleitet],
    [`occasional_user`], [Gelegenheitsnutzer als Stub-Entität; enthält nur die ID-Verknüpfung zur User-Tabelle, wird im Parkvorgang nicht aktiv befüllt],
    [`ticket`], [Parkticket mit UUID-Primärschlüssel, Ein-/Ausfahrtszeit sowie Verweisen auf Parkplatz, Tarif und optional Dauermieter; Bezahlstatus ergibt sich aus verknüpftem `Payment`-Datensatz],
    [`pricing`], [Tarif-Eintrag mit Typ (`time_based`, `daily_rate`, `monthly_rent`), verknüpft mit einem Parkhaus],
    [`time_based_pricing`], [Konfiguration für zeitbasierte Tarife: Zeitslots, Wochenend- und Feiertagstarife, Tagespauschale],
    [`daily_rate_pricing`], [Konfiguration für Tagespauschalen-Tarife: einheitliche Tagesrate],
    [`monthly_rent_pricing`], [Konfiguration für Monatsmiete pro Parkhaus: monatlicher Mietbetrag],
    [`payment`], [Zahlungsdatensatz mit Betrag und Verweis auf das Ticket; Zeitstempel über `inserted_at`],
    [`user`], [Basisentität für alle Benutzer mit Typenfeld],
    [`permanent_user`], [Dauermieter mit Zugangscode, Sperrstatus, Mietdaten und zugewiesenem Parkplatz],
    [`settings`], [Schlüssel-Wert-Tabelle für systemweite Konfigurationsparameter wie das Admin-Passwort],
  ),
  caption: [Datenbankstruktur]
)

#figure(
  image("../diagrams/ERD_Realisierung.png", width: 70%),
  caption: [Entity-Relationship-Diagramm]
)

=== Designentscheidungen

#heading(outlined: false, level: 4)[UUID als Primärschlüssel für Tickets]

Tickets verwenden einen UUID-Primärschlüssel (`binary_id`). Dies ermöglicht die sichere Übergabe der Ticket-ID an den Benutzer (z.B. zur Anzeige am Bildschirm oder als QR-Code), ohne dass sequentielle IDs erraten werden können.

#heading(outlined: false, level: 4)[Typisierte Untertabellen für Tarife]

Jeder Tarif-Typ (`time_based`, `daily_rate`, `monthly_rent`) besitzt eine eigene Untertabelle mit den jeweils relevanten Feldern. Dies ermöglicht Datenbankvalidierungen auf Feldebene und klarere Abfragen. Die Monatsmiete ist als eigener Tarif-Typ pro Parkhaus hinterlegt, sodass verschiedene Parkhäuser unterschiedliche Mietbeträge verwenden können.

#heading(outlined: false, level: 4)[Migrationsbasierte Schemaevolution]

Alle Schemaänderungen werden als Ecto-Migrationen eingecheckt. Dies stellt sicher, dass der Datenbankzustand zu jedem Zeitpunkt aus dem Quellcode reproduziert werden kann.

=== Datenzugriff

Der Datenzugriff erfolgt ausschliesslich über das Ecto-Repository-Modul (`Parking.Repo`). Direkte SQL-Abfragen werden nicht verwendet. Komplexere Abfragen - etwa die Suche nach dem nächsten freien Parkplatz mit ausgeglichener Verteilung oder die Umsatzauswertung nach Kundenkategorie - werden über die Ecto-Query-DSL formuliert.

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
      [*Vorgehen*], [`GuestParking.create_ticket/2` wird mit einer gültigen Garage-ID und Tarif-ID aufgerufen.],
      [*Erwartetes Ergebnis*], [Ticket wird erstellt und gespeichert],
      [*Tatsächliches Ergebnis*], [Ticket mit gültiger UUID und Einfahrtszeit wird erstellt. Ein aktives Ticket für den zugehörigen Parkplatz ist in der Datenbank vorhanden.],
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
      [*Tatsächliches Ergebnis*], [Ein aktives Ticket (ohne `exit_time`) ist dem Parkplatz zugewiesen. Der Parkplatz gilt damit als belegt.],
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
      [*Vorgehen*], [Ein Ticket mit 25 Stunden Parkdauer wird an `TimeBasedPricing.calculate/2` übergeben. Die Konfiguration verwendet die spezifikationskonforme Tagespauschale von CHF 35.00.],
      [*Erwartetes Ergebnis*], [Pauschale wird angewendet],
      [*Tatsächliches Ergebnis*], [Es werden 2 Tagespauschalen à CHF 35.00 berechnet (CHF 70.00 total). Der Stundentarif wird nicht angewendet.],
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
      [*Vorgehen*], [`PermanentParking.authenticate_permanent_user/1` wird mit dem korrekten Zugangscode eines nicht gesperrten Dauermieters aufgerufen.],
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
      [*Vorgehen*], [`GuestParking.process_payment/1` wird mit einem bestehenden, unbezahlten Ticket aufgerufen.],
      [*Erwartetes Ergebnis*], [Ticket wird als bezahlt markiert],
      [*Tatsächliches Ergebnis*], [Ein Zahlungsdatensatz wird in der Datenbank erstellt. Das Ticket gilt damit als bezahlt.],
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
      [*Tatsächliches Ergebnis*], [`{:error, :payment_failed}` wird zurückgegeben. Die Transaktion wird zurückgerollt. Kein Zahlungsdatensatz wurde erstellt; das aktive Ticket bleibt bestehen.],
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
      [*Vorgehen*], [Nach Einfahrt und Bezahlung wird `GuestParking.register_exit/1` aufgerufen.],
      [*Erwartetes Ergebnis*], [Ausfahrt wird erlaubt],
      [*Tatsächliches Ergebnis*], [Ausfahrtszeit wird auf dem Ticket gesetzt. Das Ticket ist damit nicht mehr aktiv; der Parkplatz gilt als frei.],
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
      [*Tatsächliches Ergebnis*], [`{:error, :payment_required}` wird zurückgegeben. Das aktive Ticket bleibt unverändert bestehen.],
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
      [*Tatsächliches Ergebnis*], [Kein Zahlungsdatensatz wurde erstellt; das Ticket bleibt damit unbezahlt und das aktive Ticket unverändert.],
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

#[
  #show figure: set align(left)
  #figure(
    table(
      columns: 2,
      [*ID*], [TC-19],
      [*Beschreibung*], [Spezifikationskonforme Wochentagstarife],
      [*Vorgehen*], [Ein Ticket mit 2 Stunden Parkdauer am Donnerstag (10:00-12:00) wird mit der vollständigen Tarifkonfiguration gemäss Lastenheft Anhang 5.1 an `TimeBasedPricing.calculate/2` übergeben.],
      [*Erwartetes Ergebnis*], [Tageszeitslot wird korrekt angewendet],
      [*Tatsächliches Ergebnis*], [Der Slot 09:00-18:00 (CHF 3.60/Std.) wird erkannt. Es werden 8 Viertelstunden à CHF 0.90 berechnet (CHF 7.20 total).],
      [*Status*], [Bestanden],
      [*Referenz*], [F-11],
    ),
    caption: [Testergebnis TC-19]
  )
]

#[
  #show figure: set align(left)
  #figure(
    table(
      columns: 2,
      [*ID*], [TC-20],
      [*Beschreibung*], [Tarifwechsel an Slotgrenze (Cross-Slot-Abrechnung)],
      [*Vorgehen*], [Ein Ticket mit Einfahrt 17:50 und Ausfahrt 18:10 an einem Wochentag wird an `TimeBasedPricing.calculate/2` übergeben.],
      [*Erwartetes Ergebnis*], [Der Tarif zu Beginn jeder Viertelstunde gilt für diese Viertelstunde],
      [*Tatsächliches Ergebnis*], [Die Viertelstunde ab 17:45 wird mit CHF 3.60/Std. (Tagstarif, CHF 0.90) abgerechnet, die Viertelstunde ab 18:00 mit CHF 2.80/Std. (Abendtarif, CHF 0.70). Total CHF 1.60.],
      [*Status*], [Bestanden],
      [*Referenz*], [F-11, F-12],
    ),
    caption: [Testergebnis TC-20]
  )
]

#[
  #show figure: set align(left)
  #figure(
    table(
      columns: 2,
      [*ID*], [TC-21],
      [*Beschreibung*], [Grenzwert 24 Stunden: Stundentarif statt Tagespauschale],
      [*Vorgehen*], [Ein Ticket mit exakt 24 Stunden Parkdauer wird an `TimeBasedPricing.calculate/2` übergeben.],
      [*Erwartetes Ergebnis*], [Tagespauschale wird bei exakt 24 Stunden nicht ausgelöst],
      [*Tatsächliches Ergebnis*], [Die Bedingung `duration > 86400` ist `false`. Es werden 96 Viertelstunden à CHF 0.75 berechnet (CHF 72.00 total). Die Tagespauschale wird erst ab mehr als 24 Stunden angewendet.],
      [*Status*], [Bestanden],
      [*Referenz*], [F-13],
    ),
    caption: [Testergebnis TC-21]
  )
]

#[
  #show figure: set align(left)
  #figure(
    table(
      columns: 2,
      [*ID*], [TC-22],
      [*Beschreibung*], [Feiertagstarife überschreiben Wochentagstarife],
      [*Vorgehen*], [Ein Ticket mit 2 Stunden Parkdauer am 01.01.2026 (Neujahr, Donnerstag) wird mit der vollständigen Tarifkonfiguration an `TimeBasedPricing.calculate/2` übergeben.],
      [*Erwartetes Ergebnis*], [Feiertagstarif wird angewendet statt Wochentagstarif],
      [*Tatsächliches Ergebnis*], [Der Feiertag wird erkannt. Der Slot 09:00-18:00 (CHF 3.20/Std.) aus den Feiertagstarifen wird angewendet. Es werden 8 Viertelstunden à CHF 0.80 berechnet (CHF 6.40 total). Der Wochentagstarif (CHF 3.60/Std.) wird nicht angewendet.],
      [*Status*], [Bestanden],
      [*Referenz*], [F-11],
    ),
    caption: [Testergebnis TC-22]
  )
]

== Empfehlungen

Der vorliegende Prototyp deckt die wesentlichen funktionalen Anforderungen ab und bildet eine solide Grundlage für eine produktive Weiterentwicklung. Die folgenden Punkte stellen die empfohlenen nächsten Schritte dar.

=== Physische Hardware-Integration

Im Prototyp werden Einfahrt und Ausfahrt über die Weboberfläche simuliert. Für den produktiven Betrieb müssten Schranken, Ticketautomaten und Kartenlesegeräte an das System angebunden werden. Die bestehenden Schnittstellen in `GuestParking` und `PermanentParking` sind darauf ausgelegt, durch entsprechende Hardware-Aufrufe ersetzt oder ergänzt zu werden.

=== Anbindung realer externer Dienste

Zahlungssystem und Buchhaltung sind derzeit als Stubs implementiert. Für den Produktiveinsatz müssen `PaymentService` und `AccountingService` gegen reale Dienstleister ausgetauscht werden. Die bestehende Abstraktion über Elixir-Behaviours und die Applikationskonfiguration erlaubt diesen Austausch, ohne die übrige Geschäftslogik zu verändern.

=== Verwaltungsoberfläche für Parkhäuser

Die Konfiguration von Parkhäusern, Stockwerken und Parkplätzen erfolgt derzeit über Datenbankmigrationen. Eine Administrationsoberfläche, über die Betreiber neue Parkhäuser anlegen, Stockwerke definieren und Parkplätze verwalten können, würde den Betrieb erheblich vereinfachen und die Abhängigkeit von technischen Deployments reduzieren.

=== Verbesserung der Benutzeroberfläche

Das aktuelle UI ist funktional, jedoch gestalterisch nicht auf einen produktiven Einsatz ausgelegt. Eine überarbeitete Oberfläche mit konsistentem Design, verbesserter mobiler Darstellung und gezieltem Nutzerfeedback würde die Benutzbarkeit deutlich erhöhen.

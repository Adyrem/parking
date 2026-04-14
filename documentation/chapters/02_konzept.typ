= Konzept


== Kontextdiagramm

Das Kontextdiagramm zeigt die Beziehung zwischen dem Parkhaus-System und externen Systemen. Dazu gehören insbesondere das Zahlungssystem sowie die Buchhaltung. Diese Systeme tauschen Daten mit der Parkhaus-Software über Schnittstellen aus.

#figure(
  image("../diagrams/kontextdiagramm.png", width: 100%),
  caption: [
    Kontextdiagramm
  ]
)



== Geschäftsprozessanalyse

Der zentrale Geschäftsprozess ist das Parkieren eines Fahrzeugs. Dieser Prozess beginnt mit der Einfahrt in das Parkhaus und endet mit der Ausfahrt.

Beim Einfahren erhält ein Gelegenheitsnutzer ein Parkticket. Während der Parkdauer wird ein Parkplatz belegt. Vor der Ausfahrt wird das Ticket bezahlt und danach kann das Fahrzeug das Parkhaus verlassen.
#figure(
  image("../diagrams/geschäftsprozess.png", width: 100%),
  caption: [
    Geschäftsprozess
  ]
)

== Detailanforderungen an das neue System


=== Funktionale Anforderungen

#[
  #show figure: set align(left)
#figure(
  table(
    align: left,
    columns: 3,
    table.header(
      [*ID*],
      [*Anforderung*],
      [*Beschreibung*],
    ),

    [F-01], [Parkhäuser verwalten], [Mehrere Parkhäuser im System verwalten],
    [F-02], [Parkhaus konfigurieren], [Stockwerke und Parkplätze definieren],
    [F-03], [Benutzerkategorien], [Gelegenheitsnutzer und Dauermieter unterscheiden],
    [F-04], [Ticket erstellen], [Ticket bei Einfahrt generieren],
    [F-05], [Einfahrt registrieren], [Datum und Zeit speichern],
    [F-06], [Code prüfen], [Zugangscode von Dauermietern prüfen],
    [F-07], [Parkplatz zuweisen], [Automatische Zuweisung eines Parkplatzes],
    [F-08], [Fixe Parkplätze], [Dauermietern feste Plätze zuweisen],
    [F-09], [Parkdauer berechnen], [Dauer zwischen Ein- und Ausfahrt bestimmen],
    [F-10], [Gebühren berechnen], [Kosten basierend auf Tarif berechnen],
    [F-11], [Tarife verwalten], [Tarife nach Tageszeit, Wochentag und Feiertagen anwenden],
    [F-12], [Viertelstundenabrechnung], [Abrechnung in 15-Minuten-Schritten],
    [F-13], [Tagespauschale], [Automatische Tagespauschale >24h],
    [F-14], [Sperrlogik], [Dauermieter bei Nichtzahlung sperren],
    [F-15], [Ein-/Ausfahrten protokollieren], [Alle Bewegungen speichern],
    [F-16], [Parkplätze anzeigen], [Freie und belegte Plätze darstellen],
    [F-17], [Statistiken erstellen], [Nutzungsdaten auswerten],
    [F-18], [Monatsumsatz berechnen], [Umsatz pro Monat berechnen],
    [F-19], [Jahresumsatz berechnen], [Umsatz pro Jahr berechnen],
    [F-20], [Dauermieter verwalten], [Dauermieter erstellen und verwalten],
    [F-21], [Austrittsticket erstellen], [Nach erfolgreicher Zahlung ein Austrittsticket generieren und am Bildschirm anzeigen]
  ),
  caption: [Funktionale Anforderungen]
) <funktionale_anforderungen>
]


=== Nicht-funktionale Anforderungen

#[
  #show figure: set align(left)
#figure(
  table(
    align: left,
    columns: 3,
    table.header(
      [*ID*],
      [*Anforderung*],
      [*Beschreibung*],
    ),

    [NF-01], [Zuverlässigkeit], [System funktioniert stabil und fehlerfrei],
    [NF-02], [Performance], [Schnelle Reaktion bei Einfahrt und Berechnung],
    [NF-03], [Benutzbarkeit], [Einfache und verständliche Bedienung],
    [NF-04], [Korrektheit], [Gebühren und Zeiten werden korrekt berechnet],
    [NF-05], [Verfügbarkeit], [System ist jederzeit nutzbar],
    [NF-06], [Sicherheit], [Zugriffe und Daten sind geschützt],
    [NF-07], [Wartbarkeit], [System kann einfach angepasst werden],
    [NF-08], [Erweiterbarkeit], [Neue Funktionen können ergänzt werden]
  ),
  caption: [Nicht-funktionale Anforderungen]
) <nicht_funktionale_anforderungen>
]


=== Organisatorische Anforderungen

#[
  #show figure: set align(left)
#figure(
  table(
    align: left,
    columns: 3,
    table.header(
      [*ID*],
      [*Anforderung*],
      [*Beschreibung*],
    ),

    [O-01], [Einzelprojekt], [Projekt wird von einer Person durchgeführt],
    [O-02], [Dokumentation], [Alle Ergebnisse werden dokumentiert],
    [O-03], [Reviews], [Teilnahme an zwei Reviews],
    [O-04], [Termine], [Einhaltung der vorgegebenen Termine],
    [O-05], [Prototyp], [Erstellung eines funktionsfähigen Prototyps],
    [O-06], [Nachvollziehbarkeit], [Arbeitsschritte müssen verständlich sein]
  ),
  caption: [Organisatorische Anforderungen]
) <organisatorische_anforderungen>
]


== Use-Case-Beschreibungen

#[
  #show figure: set align(left)
#figure(
  table(
    columns: 2,
    [*Name*], [Einfahrt Gelegenheitsnutzer],
    [*Nummer*], [UC-01],
    [*Kurzbeschreibung*], [Ein Nutzer fährt ins Parkhaus ein und erhält ein Ticket],
    [*Stakeholder*], [Gelegenheitsnutzer],
    [*Fachverantwortliche Person*], [Adrian Aeschlimann],
    [*Referenzen*], [Ticketautomat, Schranke],
    [*Vorbedingungen*], [Parkplätze verfügbar],
    [*Nachbedingungen*], [Ticket erstellt, Einfahrt erfolgt],
    [*Typischer Ablauf*], [Knopf drücken → Ticket wird erstellt → Schranke öffnet],
    [*Alternative Abläufe*], [Kein Parkplatz → Einfahrt verweigert],
    [*Kritikalität*], [Hoch],
    [*Verknüpfungen*], [UC-03, UC-04],
    [*Funktionale Anforderungen*], [F-04 Ticket erstellen, F-05 Einfahrt registrieren, F-07 Parkplatz zuweisen],
    [*Nicht-funktionale Anforderungen*], [NF-01 Zuverlässigkeit, NF-02 Performance]
  ),
  caption: [Use Case UC-01]
)
]

#[
  #show figure: set align(left)
#figure(
  table(
    columns: 2,
    [*Name*], [Einfahrt Dauermieter],
    [*Nummer*], [UC-02],
    [*Kurzbeschreibung*], [Dauermieter fährt mit Code ein],
    [*Stakeholder*], [Dauermieter],
    [*Fachverantwortliche Person*], [Adrian Aeschlimann],
    [*Referenzen*], [Schranke],
    [*Vorbedingungen*], [Code vorhanden],
    [*Nachbedingungen*], [Einfahrt registriert],
    [*Typischer Ablauf*], [Code eingeben → Prüfung → Schranke öffnet],
    [*Alternative Abläufe*], [Code ungültig → Zutritt verweigert],
    [*Kritikalität*], [Hoch],
    [*Verknüpfungen*], [UC-04],
    [*Funktionale Anforderungen*], [F-06 Code prüfen, F-05 Einfahrt registrieren],
    [*Nicht-funktionale Anforderungen*], [NF-06 Sicherheit, NF-05 Verfügbarkeit]
  ),
  caption: [Use Case UC-02]
)
]

#[
  #show figure: set align(left)
#figure(
  table(
    columns: 2,
    [*Name*], [Bezahlung Parkticket],
    [*Nummer*], [UC-03],
    [*Kurzbeschreibung*], [Berechnung und Bezahlung der Parkgebühr],
    [*Stakeholder*], [Gelegenheitsnutzer],
    [*Fachverantwortliche Person*], [Adrian Aeschlimann],
    [*Referenzen*], [Zahlungssystem],
    [*Vorbedingungen*], [Ticket vorhanden],
    [*Nachbedingungen*], [Ticket entwertet, Austrittsticket erstellt],
    [*Typischer Ablauf*], [Ticket scannen → Betrag berechnen → bezahlen → Austrittsticket erstellen],
    [*Alternative Abläufe*], [Zahlung fehlgeschlagen → erneut versuchen],
    [*Kritikalität*], [Sehr hoch],
    [*Verknüpfungen*], [UC-01, UC-04],
    [*Funktionale Anforderungen*], [F-09 Parkdauer berechnen, F-10 Gebühren berechnen, F-11 Tarife verwalten, F-12 Viertelstundenabrechnung, F-13 Tagespauschale, F-21 Austrittsticket erstellen],
    [*Nicht-funktionale Anforderungen*], [NF-04 Korrektheit, NF-02 Performance]
  ),
  caption: [Use Case UC-03]
)
]

#[
  #show figure: set align(left)
#figure(
  table(
    columns: 2,
    [*Name*], [Ausfahrt],
    [*Nummer*], [UC-04],
    [*Kurzbeschreibung*], [Fahrzeug verlässt das Parkhaus],
    [*Stakeholder*], [Alle Nutzer],
    [*Fachverantwortliche Person*], [Adrian Aeschlimann],
    [*Referenzen*], [Schranke],
    [*Vorbedingungen*], [Gültiges Austrittsticket (Gelegenheitsnutzer) oder gültiger Code (Dauermieter)],
    [*Nachbedingungen*], [Ausfahrt registriert],
    [*Typischer Ablauf*], [Austrittsticket scannen bzw. Code eingeben → Ausfahrtszeit registrieren → Schranke öffnet],
    [*Alternative Abläufe*], [Ticket ungültig → Ausfahrt verweigert],
    [*Kritikalität*], [Sehr hoch],
    [*Verknüpfungen*], [UC-01, UC-02, UC-03],
    [*Funktionale Anforderungen*], [F-05 Einfahrt registrieren, F-15 Ein-/Ausfahrten protokollieren, F-21 Austrittsticket erstellen],
    [*Nicht-funktionale Anforderungen*], [NF-01 Zuverlässigkeit]
  ),
  caption: [Use Case UC-04]
)
]

#[
  #show figure: set align(left)
#figure(
  table(
    columns: 2,
    [*Name*], [Parkplätze anzeigen],
    [*Nummer*], [UC-05],
    [*Kurzbeschreibung*], [Anzeige freier und belegter Parkplätze],
    [*Stakeholder*], [Betreiber],
    [*Fachverantwortliche Person*], [Adrian Aeschlimann],
    [*Referenzen*], [-],
    [*Vorbedingungen*], [Parkhaus konfiguriert],
    [*Nachbedingungen*], [Aktuelle Belegung sichtbar],
    [*Typischer Ablauf*], [System zeigt Status pro Parkplatz],
    [*Alternative Abläufe*], [-],
    [*Kritikalität*], [Mittel],
    [*Verknüpfungen*], [-],
    [*Funktionale Anforderungen*], [F-16 Parkplätze anzeigen],
    [*Nicht-funktionale Anforderungen*], [NF-03 Benutzbarkeit]
  ),
  caption: [Use Case UC-05]
)
]

#[
  #show figure: set align(left)
#figure(
  table(
    columns: 2,
    [*Name*], [Parkhaus konfigurieren],
    [*Nummer*], [UC-06],
    [*Kurzbeschreibung*], [Struktur eines Parkhauses definieren],
    [*Stakeholder*], [Betreiber],
    [*Fachverantwortliche Person*], [Adrian Aeschlimann],
    [*Referenzen*], [-],
    [*Vorbedingungen*], [System gestartet],
    [*Nachbedingungen*], [Parkhaus ist konfiguriert],
    [*Typischer Ablauf*], [Stockwerke und Parkplätze definieren],
    [*Alternative Abläufe*], [Ungültige Eingaben → Korrektur],
    [*Kritikalität*], [Hoch],
    [*Verknüpfungen*], [UC-01, UC-05],
    [*Funktionale Anforderungen*], [F-01 Parkhäuser verwalten, F-02 Parkhaus konfigurieren],
    [*Nicht-funktionale Anforderungen*], [NF-03 Benutzbarkeit]
  ),
  caption: [Use Case UC-06]
)
]

#[
  #show figure: set align(left)
#figure(
  table(
    columns: 2,
    [*Name*], [Parkplatz zuweisen],
    [*Nummer*], [UC-07],
    [*Kurzbeschreibung*], [Automatische Zuweisung eines Parkplatzes],
    [*Stakeholder*], [System],
    [*Fachverantwortliche Person*], [Adrian Aeschlimann],
    [*Referenzen*], [-],
    [*Vorbedingungen*], [Freie Parkplätze vorhanden],
    [*Nachbedingungen*], [Parkplatz zugewiesen],
    [*Typischer Ablauf*], [System wählt Parkplatz],
    [*Alternative Abläufe*], [Keine Plätze → Abbruch],
    [*Kritikalität*], [Hoch],
    [*Verknüpfungen*], [UC-01],
    [*Funktionale Anforderungen*], [F-07 Parkplatz zuweisen],
    [*Nicht-funktionale Anforderungen*], [NF-02 Performance]
  ),
  caption: [Use Case UC-07]
)
]

#[
  #show figure: set align(left)
#figure(
  table(
    columns: 2,
    [*Name*], [Parkgebühr berechnen],
    [*Nummer*], [UC-08],
    [*Kurzbeschreibung*], [Berechnung der Parkkosten],
    [*Stakeholder*], [System],
    [*Fachverantwortliche Person*], [Adrian Aeschlimann],
    [*Referenzen*], [-],
    [*Vorbedingungen*], [Einfahrtszeit vorhanden],
    [*Nachbedingungen*], [Betrag berechnet],
    [*Typischer Ablauf*], [Parkdauer berechnen → Wochentag/Feiertag prüfen → geltenden Tarif anwenden],
    [*Alternative Abläufe*], [>24h → Tagespauschale; Wochenende oder Feiertag → Wochenend-/Feiertagstarif],
    [*Kritikalität*], [Sehr hoch],
    [*Verknüpfungen*], [UC-03],
    [*Funktionale Anforderungen*], [F-09 Parkdauer berechnen, F-10 Gebühren berechnen, F-11 Tarife verwalten],
    [*Nicht-funktionale Anforderungen*], [NF-04 Korrektheit]
  ),
  caption: [Use Case UC-08]
)
]

#[
  #show figure: set align(left)
#figure(
  table(
    columns: 2,
    [*Name*], [Dauermieter verwalten],
    [*Nummer*], [UC-09],
    [*Kurzbeschreibung*], [Verwaltung von Dauermietern],
    [*Stakeholder*], [Betreiber],
    [*Fachverantwortliche Person*], [Adrian Aeschlimann],
    [*Referenzen*], [-],
    [*Vorbedingungen*], [System verfügbar],
    [*Nachbedingungen*], [Daten gespeichert],
    [*Typischer Ablauf*], [Daten erfassen/ändern],
    [*Alternative Abläufe*], [-],
    [*Kritikalität*], [Mittel],
    [*Verknüpfungen*], [UC-02],
    [*Funktionale Anforderungen*], [F-03 Benutzerkategorien, F-20 Dauermieter verwalten],
    [*Nicht-funktionale Anforderungen*], [NF-06 Sicherheit]
  ),
  caption: [Use Case UC-09]
)
]

#[
  #show figure: set align(left)
#figure(
  table(
    columns: 2,
    [*Name*], [Sperrstatus prüfen],
    [*Nummer*], [UC-10],
    [*Kurzbeschreibung*], [Prüfung ob Dauermieter gesperrt ist],
    [*Stakeholder*], [System],
    [*Fachverantwortliche Person*], [Adrian Aeschlimann],
    [*Referenzen*], [-],
    [*Vorbedingungen*], [Dauermieter vorhanden],
    [*Nachbedingungen*], [Status bestimmt],
    [*Typischer Ablauf*], [Zahlungsstatus prüfen],
    [*Alternative Abläufe*], [Nicht bezahlt → Sperre],
    [*Kritikalität*], [Hoch],
    [*Verknüpfungen*], [UC-02],
    [*Funktionale Anforderungen*], [F-14 Sperrlogik],
    [*Nicht-funktionale Anforderungen*], [NF-01 Zuverlässigkeit]
  ),
  caption: [Use Case UC-10]
)
]

#[
  #show figure: set align(left)
#figure(
  table(
    columns: 2,
    [*Name*], [Statistiken erstellen],
    [*Nummer*], [UC-11],
    [*Kurzbeschreibung*], [Auswertung von Nutzungsdaten],
    [*Stakeholder*], [Betreiber],
    [*Fachverantwortliche Person*], [Adrian Aeschlimann],
    [*Referenzen*], [-],
    [*Vorbedingungen*], [Daten vorhanden],
    [*Nachbedingungen*], [Statistik erstellt],
    [*Typischer Ablauf*], [Zeitraum wählen → Daten anzeigen],
    [*Alternative Abläufe*], [-],
    [*Kritikalität*], [Mittel],
    [*Verknüpfungen*], [-],
    [*Funktionale Anforderungen*], [F-17 Statistiken erstellen],
    [*Nicht-funktionale Anforderungen*], [NF-02 Performance]
  ),
  caption: [Use Case UC-11]
)
]

#[
  #show figure: set align(left)
#figure(
  table(
    columns: 2,
    [*Name*], [Umsatz berechnen],
    [*Nummer*], [UC-12],
    [*Kurzbeschreibung*], [Berechnung von Monats- und Jahresumsätzen],
    [*Stakeholder*], [Betreiber],
    [*Fachverantwortliche Person*], [Adrian Aeschlimann],
    [*Referenzen*], [Buchhaltungssystem],
    [*Vorbedingungen*], [Daten vorhanden],
    [*Nachbedingungen*], [Umsatz berechnet],
    [*Typischer Ablauf*], [Zeitraum wählen → Berechnung],
    [*Alternative Abläufe*], [-],
    [*Kritikalität*], [Hoch],
    [*Verknüpfungen*], [UC-11],
    [*Funktionale Anforderungen*], [F-18 Monatsumsatz berechnen, F-19 Jahresumsatz berechnen],
    [*Nicht-funktionale Anforderungen*], [NF-04 Korrektheit]
  ),
  caption: [Use Case UC-12]
)
]

#[
  #show figure: set align(left)
#figure(
  table(
    columns: 2,
    [*Name*], [Austrittsticket erstellen],
    [*Nummer*], [UC-13],
    [*Kurzbeschreibung*], [Generierung und Anzeige des Austrittstickets nach erfolgreicher Zahlung],
    [*Stakeholder*], [Gelegenheitsnutzer],
    [*Fachverantwortliche Person*], [Adrian Aeschlimann],
    [*Referenzen*], [-],
    [*Vorbedingungen*], [Parkgebühr erfolgreich bezahlt],
    [*Nachbedingungen*], [Austrittsticket am Bildschirm angezeigt; Ticket als bezahlt markiert],
    [*Typischer Ablauf*], [Zahlung abgeschlossen → Austrittsticket generieren → Austrittsticket am Bildschirm anzeigen],
    [*Alternative Abläufe*], [-],
    [*Kritikalität*], [Sehr hoch],
    [*Verknüpfungen*], [UC-03, UC-04],
    [*Funktionale Anforderungen*], [F-21 Austrittsticket erstellen],
    [*Nicht-funktionale Anforderungen*], [NF-01 Zuverlässigkeit, NF-03 Bedienbarkeit]
  ),
  caption: [Use Case UC-13]
)
]

== Sequenzdiagramme

#figure(
  image("../diagrams/Ausfahrt.png", width: 100%),
  caption: [
    Ausfahrt
  ]
)
#figure(
  image("../diagrams/Bezahlung.png", width: 100%),
  caption: [
    Bezahlung
  ]
)
#figure(
  image("../diagrams/Einfahrt_Dauermieter.png", width: 100%),
  caption: [
    Einfahrt Dauermieter
  ]
)
#figure(
  image("../diagrams/Einfahrt_Gelegenheitsnutzer.png", width: 100%),
  caption: [
    Einfahrt Gelegenheitsnutzer
  ]
)
#figure(
  image("../diagrams/Statistiken.png", width: 100%),
  caption: [
    Statistiken (Umsatz)
  ]
)

== Modellierung der Klassen


=== Klassendiagramm

#figure(
  image("../diagrams/class_diagram.png", width: 100%),
  caption: [
    Klassendiagramm
  ]
)


=== Beschreibung der Fachklassen

*ParkingSystem*

Die Klasse ParkingSystem bildet die zentrale Steuerung des gesamten Systems. Sie übernimmt die Koordination aller Abläufe wie Einfahrt, Ausfahrt, Ticketverarbeitung, Parkplatzzuweisung, Gebührenberechnung sowie Zahlungsabwicklung. Dabei fungiert sie als zentrale Schnittstelle zwischen den einzelnen Komponenten und kapselt die Geschäftslogik.
Die Klasse ruft je nach Anwendungsfall spezialisierte Services auf, beispielsweise für Zahlungsabwicklung oder Statistik. Durch diese Bündelung wird die Komplexität reduziert und die Interaktion mit dem System vereinfacht.

*ParkingGarage*

Die Klasse ParkingGarage repräsentiert ein vollständiges Parkhaus. Sie enthält mehrere Ebenen und bietet Funktionen zur Verwaltung und Abfrage von Parkplätzen.
Eine zentrale Aufgabe ist die Ermittlung freier Parkplätze, die als Grundlage für die automatische Zuweisung dient. Die Struktur erlaubt eine Erweiterung auf mehrere Parkhäuser innerhalb desselben Systems.

*Level*

Die Klasse Level dient der Strukturierung eines Parkhauses in einzelne Ebenen. Sie verwaltet eine Menge von Parkplätzen und ermöglicht so eine klare Organisation innerhalb des Parkhauses.

*ParkingSpot*

Die Klasse ParkingSpot repräsentiert einen einzelnen Parkplatz. Sie enthält Informationen über den aktuellen Belegungsstatus sowie eine eindeutige Identifikation.
Zentrale Methoden sind das Belegen und Freigeben eines Parkplatzes. Diese Klasse ist ein zentraler Bestandteil der Parkplatzlogik, da sie direkt von der Zuweisung und der Anzeige beeinflusst wird.

*Ticket*

Die Klasse Ticket enthält alle relevanten Daten eines Parkvorgangs. Dazu gehören insbesondere Einfahrtszeit, Ausfahrtszeit sowie der Zahlungsstatus.
Sie bildet die Grundlage für mehrere Kernfunktionen des Systems, darunter die Berechnung der Parkdauer und der Gebühren sowie die Validierung bei der Ausfahrt.
Das Ticket durchläuft verschiedene Zustände, etwa „aktiv“, „bezahlt“ oder „abgelaufen“, wodurch der Lebenszyklus eines Parkvorgangs abgebildet wird.

*User*

Abstrakte Basisklasse für alle Benutzer des Systems. Enthält grundlegende Identifikationsmerkmale.

*OccasionalUser*

Repräsentiert einen Gelegenheitsnutzer, der das Parkhaus einmalig oder unregelmässig nutzt.
Diese Benutzer erhalten bei der Einfahrt ein Ticket, welches später zur Bezahlung und Ausfahrt benötigt wird. Es erfolgt keine dauerhafte Speicherung von Nutzerdaten.

*PermanentUser*

Repräsentiert einen Dauermieter mit wiederkehrender Nutzung. Die Klasse verfügt über zusätzliche Attribute wie Zugangscode und Sperrstatus.
Ein zentraler Bestandteil ist die Prüfung des Zugangscodes sowie die Überprüfung, ob der Benutzer aufgrund offener Zahlungen gesperrt ist.
Es wird ein fester Parkplatz zugewiesen, wodurch sich das Verhalten bei der Parkplatzvergabe unterscheidet.

*PaymentService*

Die Klasse PaymentService kapselt die gesamte Zahlungslogik und dient als Schnittstelle zu einem externen Zahlungssystem.
Sie übernimmt die Verarbeitung von Zahlungen und liefert das Ergebnis an das System zurück. Durch diese Trennung bleibt die Kernlogik unabhängig von konkreten Zahlungsanbietern. Im Rahmen diese Projektes wird hier ein externes System simuliert.

*AccountingService*

Zuständig für die Übergabe von Finanzdaten an ein externes Buchhaltungssystem. Erfasst Umsätze und stellt diese für Auswertungen bereit. Auch hier wird das externe System nur simuliert.

*PricingStrategy*

Die abstrakte Klasse PricingStrategy definiert die Schnittstelle zur Berechnung der Parkgebühren. Sie ermöglicht es, unterschiedliche Berechnungslogiken unabhängig voneinander zu implementieren.
Dieses Konzept erlaubt eine flexible Anpassung von Tarifen oder erstellen einer neuen Berechnungslogik, ohne die zentrale Systemlogik zu verändern.

*TimeBasedPricing*

Diese Klasse implementiert eine zeitbasierte Gebührenberechnung. Die Kosten werden anhand der Parkdauer und definierter Tarife bestimmt, beispielsweise mit Abrechnung in Viertelstunden.
Zusätzlich können Regeln wie unterschiedliche Tarife je nach Tageszeit oder Wochentag berücksichtigt werden.

*FlatRatePricing*

Die Klasse FlatRatePricing bildet Pauschalpreise ab, beispielsweise bei sehr langen Parkdauern.
Sie wird typischerweise in Kombination mit der zeitbasierten Berechnung verwendet, etwa wenn eine Tagespauschale ab einer bestimmten Dauer greift.

*StatisticsService*

Die Klasse StatisticsService verarbeitet die im System gespeicherten Daten und stellt Auswertungen zur Verfügung. Dazu gehören z.B. Belegungsstatistiken sowie die Berechnung von Monats- und Jahresumsätzen.
Die Berechnungen basieren auf protokollierten Ein-/Ausfahrten sowie den zugehörigen Zahlungen. Dadurch können betriebliche Kennzahlen einfach analysiert werden.

== Zustandsdiagramme

Das Zustandsdiagramm des ParkingSpot zeigt den Belegungsstatus eines Parkplatzes. Ein Parkplatz ist initial frei und kann durch das System reserviert werden. Sobald ein Fahrzeug den Platz belegt, wechselt der Zustand zu belegt. Nach der Ausfahrt wird der Parkplatz wieder freigegeben und steht erneut zur Verfügung.
#figure(
  image("../diagrams/parkingspot_lifecycle.png", width: 50%),
  caption: [
    Parkplatz Zustandsdiagramm
  ]
)

Das Zustandsdiagramm des Ticket beschreibt den gesamten Lebenszyklus eines Parkvorgangs. Nach der Erstellung bei der Einfahrt wechselt das Ticket in den aktiven Zustand, in dem die Parkdauer läuft. Nach der Bezahlung wird es als bezahlt markiert und kann für die Ausfahrt verwendet werden. Erfolgt die Ausfahrt innerhalb einer definierten Zeit, wird das Ticket erfolgreich abgeschlossen. Wird diese Zeit überschritten, wechselt es in einen abgelaufenen Zustand und muss entsprechend nachbearbeitet werden.
#figure(
  image("../diagrams/ticket_lifecycle.png", width: 100%),
  caption: [
    Ticket Zustandsdiagramm
  ]
)


== Modellierung der Datenbank


=== ERD

#figure(
  image("../diagrams/ERD.png", width: 70%),
  caption: [
    ERD
  ]
)



=== Beschreibung der Fachentitäten, Beziehungen und der referenziellen Integritätsbedingungen

*ParkingGarage*

Die Entität ParkingGarage repräsentiert ein Parkhaus und bildet die oberste strukturelle Einheit. Ein Parkhaus besteht aus mehreren Ebenen. Jede zugehörige Ebene muss eindeutig einem existierenden Parkhaus zugeordnet sein, wodurch sichergestellt wird, dass keine Ebene ohne gültige Referenz existiert.

*Level*

Die Entität Level beschreibt eine Ebene innerhalb eines Parkhauses. Jede Ebene gehört genau zu einem Parkhaus und enthält mehrere Parkplätze. Die referenzielle Integrität verlangt, dass jede Ebene eine gültige Referenz auf ein bestehendes Parkhaus besitzt. Beim Löschen eines Parkhauses muss berücksichtigt werden, dass zugehörige Ebenen ebenfalls behandelt werden.

*ParkingSpot*

Die Entität ParkingSpot stellt einen einzelnen Parkplatz dar. Jeder Parkplatz gehört genau zu einer Ebene und kann im Zeitverlauf mehreren Parkvorgängen zugeordnet sein.
Die Integritätsbedingungen stellen sicher, dass jeder Parkplatz eine gültige Ebene referenziert. Zudem darf ein Parkplatz nur dann gelöscht werden, wenn keine aktiven Referenzen, beispielsweise durch laufende Parkvorgänge, bestehen.

*Ticket*

Die Entität Ticket repräsentiert einen Parkvorgang. Sie speichert Einfahrts- und Ausfahrtszeit sowie den Zahlungsstatus und ist einem Parkplatz zugeordnet.
Jedes Ticket muss auf einen existierenden Parkplatz verweisen. Zusätzlich kann ein Ticket mit mehreren Zahlungsvorgängen verknüpft sein. Die referenzielle Integrität stellt sicher, dass keine Zahlungen ohne gültiges Ticket existieren und dass ein Ticket nicht gelöscht werden kann, solange abhängige Zahlungen vorhanden sind.

*User*

Die Entität User bildet die Basis für Benutzer im System. Sie enthält grundlegende Identifikationsmerkmale und dient als Ausgangspunkt für Spezialisierungen.
Die Integrität stellt sicher, dass spezialisierte Benutzer nur existieren können, wenn ein entsprechender Basiseintrag vorhanden ist.

*PermanentUser*

Die Entität PermanentUser erweitert die Basisklasse User um zusätzliche Informationen wie Zugangscode und Sperrstatus. Jeder Eintrag in dieser Entität muss auf einen existierenden Benutzer verweisen.
Optional kann ein fester Parkplatz zugewiesen werden. In diesem Fall muss der referenzierte Parkplatz existieren. Wird ein Parkplatz gelöscht, muss geprüft werden, ob er einem Dauermieter zugewiesen ist.

*Payment*

Die Entität Payment speichert einzelne Zahlungsvorgänge. Jeder Zahlungseintrag ist genau einem Ticket zugeordnet.
Die referenzielle Integrität stellt sicher, dass keine Zahlung ohne gültiges Ticket existieren kann. Beim Löschen eines Tickets müssen zugehörige Zahlungen ebenfalls berücksichtigt oder entfernt werden.

*Pricing*

Die Entität Pricing repräsentiert Tarifmodelle zur Gebührenberechnung. Ein Tarif kann mehreren Tickets zugeordnet sein.
Die Integrität verlangt, dass jedes Ticket auf ein gültiges Tarifmodell verweist. Änderungen an Tarifmodellen müssen so erfolgen, dass bestehende Ticketdaten konsistent bleiben.


== Systemarchitektur

Die Systemarchitektur des Parkhaus-Systems ist als Web-Anwendung aufgebaut. Ziel ist eine klare Trennung der Verantwortlichkeiten sowie eine einfache und nachvollziehbare Struktur, die sich gut erweitern lässt.

Das System folgt einer schichtenbasierten Architektur, bestehend aus Präsentationsschicht, Anwendungsschicht und Datenhaltungsschicht. Die Präsentationsschicht wird als Web-Frontend umgesetzt und läuft im Browser. Sie dient ausschliesslich der Interaktion mit dem Benutzer und enthält keine Geschäftslogik. Benutzeraktionen werden an die Anwendungsschicht weitergeleitet.

Die Anwendungsschicht bildet den Kern des Systems und enthält die gesamte Geschäftslogik. Hier werden alle zentralen Abläufe wie Einfahrt, Ausfahrt, Ticketverarbeitung, Parkplatzzuweisung und Gebührenberechnung umgesetzt. Die Klasse ParkingSystem fungiert als zentrale Steuerungskomponente und koordiniert die Interaktion zwischen den einzelnen Services.

Die Datenhaltung erfolgt über eine relationale Datenbank auf Basis von PostgreSQL. Der Systemzustand wird soweit möglich vollständig in der Datenbank persistiert. Dadurch wird sichergestellt, dass das System auch bei einem Neustart konsistent bleibt und keine Zustandsinformationen verloren gehen.

Die Kommunikation mit der Datenbank erfolgt ausschliesslich über die Anwendungsschicht. Direkte Zugriffe aus der Präsentationsschicht sind nicht vorgesehen. Die Datenbank enthält alle relevanten Entitäten wie Tickets, Parkplätze, Benutzer und Zahlungen.

Externe Systeme wie das Zahlungssystem und das Buchhaltungssystem werden im Rahmen dieses Projekts nicht real angebunden, sondern durch Mock-Klassen simuliert. Diese simulierten Komponenten implementieren die gleichen Schnittstellen wie reale Systeme, sodass ein späterer Austausch ohne Änderungen an der Kernlogik möglich ist.

Der Datenfluss im System beginnt mit einer Benutzeraktion im Web-Frontend. Die Anfrage wird an die Anwendungsschicht übergeben, dort verarbeitet und bei Bedarf durch Datenbankzugriffe oder Aufrufe von Services ergänzt. Anschliessend wird das Ergebnis an die Präsentationsschicht zurückgegeben und dem Benutzer angezeigt.

Die Architektur ist bewusst einfach gehalten und verzichtet auf komplexe Verteilung oder Microservices. Stattdessen wird eine monolithische Struktur verwendet, die alle Komponenten in einer Anwendung vereint. Diese Entscheidung reduziert die Komplexität und ist für den Umfang des Projekts ausreichend.

#figure(
  image("../diagrams/Architekturdiagram.png", width: 70%),
  caption: [
    Architekturdiagramm
  ]
)


== Testkonzept

Das Testkonzept beschreibt das Vorgehen zur Überprüfung der funktionalen und nicht-funktionalen Anforderungen des Parkhaus-Systems. Ziel ist es, die korrekte Umsetzung der definierten Anforderungen sicherzustellen und Fehler frühzeitig zu erkennen.

=== Vorgehen

Die Tests werden schrittweise während der Entwicklung durchgeführt. Zunächst werden einzelne Komponenten isoliert getestet, anschliessend erfolgt die Überprüfung des Zusammenspiels mehrerer Komponenten. Abschliessend werden zentrale Anwendungsfälle aus Sicht des Benutzers getestet.

Der Fokus liegt auf der Validierung der Geschäftslogik in der Anwendungsschicht sowie auf der korrekten Verarbeitung und Speicherung von Daten in der Datenbank. Externe Systeme werden über Mock-Klassen simuliert, wodurch deren Verhalten gezielt gesteuert werden kann.

Die Tests orientieren sich direkt an den definierten Anforderungen. Jede funktionale Anforderung wird mindestens durch einen Testfall abgedeckt. Nicht-funktionale Anforderungen werden durch gezielte Szenarien überprüft, beispielsweise durch wiederholte Ausführung oder Messung von Reaktionszeiten.

=== Testobjekte

Die folgenden Komponenten werden getestet:

- Zentrale Steuerung (ParkingSystem)
- Ticket-Logik (Erstellung, Status, Ausfahrt)
- Parkplatzlogik (Zuweisung, Freigabe)
- Gebührenberechnung (PricingStrategy)
- Zahlungsabwicklung (PaymentService, Mock)
- Persistenz (Datenbankzugriffe und Konsistenz)
- Statistikfunktionen (StatisticsService)

=== Testfälle

#[
  #show figure: set align(left)
  #figure(
    table(
      align: left,
      columns: 4,
      table.header(
        [ID],
        [Beschreibung],
        [Erwartetes Ergebnis],
        [Referenz],
      ),
      [TC-01], [Einfahrt erzeugt Ticket], [Ticket wird erstellt und gespeichert], [F-04, F-05],
      [TC-02], [Parkplatz wird zugewiesen], [Freier Parkplatz wird belegt], [F-07, F-16],
      [TC-03], [Parkdauer wird berechnet], [Zeitdifferenz ist korrekt], [F-09],
      [TC-04], [Gebühr wird korrekt berechnet], [Betrag entspricht Tarif], [F-10, F-11],
      [TC-05], [Viertelstundenabrechnung], [Rundung erfolgt korrekt], [F-12],
      [TC-06], [Tagespauschale greift], [Pauschale wird angewendet], [F-13],
      [TC-07], [Dauermieter Zugang erlaubt], [Schranke öffnet], [F-06],
      [TC-08], [Dauermieter gesperrt], [Zugang verweigert], [F-14],
      [TC-09], [Bezahlung erfolgreich], [Ticket wird als bezahlt markiert], [F-10],
      [TC-10], [Bezahlung fehlgeschlagen], [Fehlermeldung wird angezeigt], [NF-01],
      [TC-11], [Ausfahrt mit gültigem Ticket], [Ausfahrt wird erlaubt], [F-15],
      [TC-12], [Ausfahrt ohne Zahlung], [Ausfahrt wird verweigert], [F-10],
      [TC-13], [Statistik wird erzeugt], [Daten werden korrekt angezeigt], [F-17],
      [TC-14], [Monatsumsatz korrekt], [Umsatz stimmt], [F-18],
      [TC-15], [System reagiert schnell], [Antwortzeit < definierter Schwelle], [NF-02],
      [TC-16], [System bleibt stabil], [Keine Abstürze bei Wiederholung], [NF-01],
      [TC-17], [Daten bleiben konsistent], [Keine inkonsistenten Zustände], [NF-04, NF-07],
      [TC-18], [Benutzeroberfläche verständlich], [Bedienung ohne Anleitung möglich], [NF-03]
    ),
    caption: [Testfälle]
  ) <testfaelle>
]

== Einführungskonzept

Die Einführung des Systems erfolgt im Rahmen der Projektabgabe und beschränkt sich auf die Bereitstellung der erarbeiteten Ergebnisse. Eine produktive Inbetriebnahme ist nicht vorgesehen.

Im Zentrum der Einführung steht die Dokumentation des Systems. Diese beschreibt die Anforderungen, die Architektur, die Umsetzung sowie die wichtigsten Abläufe. Sie dient dazu, das System nachvollziehbar darzustellen und einen Überblick über die getroffenen Entscheidungen zu geben.

Zusätzlich wird eine abschliessende Präsentation durchgeführt. In dieser werden die wichtigsten Aspekte des Projekts vorgestellt. Dazu gehören insbesondere die Zielsetzung, die gewählte Lösung, zentrale Funktionen sowie ausgewählte technische Entscheidungen. Die Präsentation dient dazu, das Verständnis für das System zu vermitteln und die erarbeiteten Inhalte kompakt zusammenzufassen.

Eine Schulung von Benutzern oder ein Rollout in eine reale Umgebung findet nicht statt. Das System wird ausschliesslich im Rahmen der Projektarbeit demonstriert.

== Migrationskonzept

Ein Migrationskonzept ist für dieses Projekt nicht erforderlich, da kein tatsächlich bestehendes System abgelöst wird und keine Altdaten übernommen werden müssen.

Das Parkhaus-System wird als eigenständige Lösung entwickelt und startet ohne vorhandene Datenbasis. Alle benötigten Daten werden entweder während der Nutzung erzeugt oder können zu Testzwecken initial angelegt werden.

Aufgrund dieses Szenarios sind keine Massnahmen zur Datenübernahme, Datenbereinigung oder Systemumstellung notwendig.

== GUI-Design

Das GUI des Parkhaus-Systems wird als Web-Anwendung umgesetzt und über einen Browser bedient. Ziel ist eine einfache und klare Benutzeroberfläche, die die wichtigsten Funktionen ohne lange Einarbeitung zugänglich macht.

Die Benutzeroberfläche ist in logisch getrennte Bereiche aufgebaut, die sich an den zentralen Anwendungsfällen orientieren. Dazu gehören insbesondere Einfahrt, Ausfahrt, Bezahlung, Verwaltung sowie Auswertungen. Die Navigation erfolgt über eine klare Struktur, sodass die einzelnen Funktionen schnell erreichbar sind.

Die Interaktion erfolgt über einfache Eingabemasken und übersichtliche Anzeigen. Benutzer sollen ohne zusätzliche Erklärung erkennen können, welche Aktionen möglich sind. Wichtige Informationen wie Parkstatus, Gebühren oder Fehlermeldungen werden direkt sichtbar dargestellt. Die Oberfläche vermeidet unnötige Komplexität und konzentriert sich auf die wesentlichen Abläufe.

Für die Darstellung von Parkplätzen wird eine visuelle Übersicht verwendet, in der freie und belegte Plätze klar unterscheidbar sind. Dadurch kann der aktuelle Zustand des Parkhauses schnell erfasst werden. Die Anzeige wird regelmässig aktualisiert, sodass Änderungen zeitnah sichtbar sind.

Die Bezahlfunktion wird so gestaltet, dass der Ablauf möglichst einfach ist. Nach dem Scannen oder Eingeben eines Tickets werden die berechneten Gebühren angezeigt und die Zahlung kann direkt ausgelöst werden. Rückmeldungen über den Erfolg oder Fehler einer Zahlung werden unmittelbar angezeigt.

Die Verwaltung von Parkhäusern und Dauermietern erfolgt über separate Bereiche. Dort können Konfigurationen vorgenommen und Daten angepasst werden. Die Eingaben werden validiert, um fehlerhafte Daten zu vermeiden.

Nicht-funktionale Anforderungen wie Benutzbarkeit und Performance werden im GUI berücksichtigt, indem die Oberfläche schnell reagiert und klar strukturiert ist. Aktionen sollen ohne merkliche Verzögerung ausgeführt werden.




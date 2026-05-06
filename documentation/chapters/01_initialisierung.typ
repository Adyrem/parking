= Abkürzungsverzeichnis

#[
  #show figure: set align(left)
#figure(
  table(
    align: left,
    columns: 2,
    table.header(
      [*Abkürzung*], 
      [*Bedeutung*], 
    ),
    [BEAM], [Bogdan's Erlang Abstract Machine],
    [DSL], [Domain Specific Language],
    [UUID], [Universally Unique Identifier]
  ),
  caption: [Abkürzungsverzeichnis]
) <abkürzungsverzeichnis>
]

= Projektinitialisierung


== Ausgangslage


Die EasyParking AG betreibt mehrere Parkhäuser in verschiedenen Städten. Für den Betrieb dieser Parkhäuser wird aktuell eine Software verwendet, welche den Parkprozess unterstützt. Diese Software ist jedoch in die Jahre gekommen und soll spätestens bis Ende 2029 ersetzt werden.

Im Vorfeld wurde geprüft, ob eine bestehende Standardsoftware eingesetzt werden kann. Dazu wurde eine Marktanalyse durchgeführt. Die geprüften Produkte konnten die Anforderungen der EasyParking AG jedoch nicht ausreichend erfüllen. Aus diesem Grund wurde entschieden, eine eigene Software entwickeln zu lassen.

Die EasyParking AG verfügt über eine interne IT-Abteilung, hat jedoch keine eigenen Entwicklerkapazitäten für ein solches Projekt. Deshalb soll die Entwicklung der neuen Parkhaus-Software durch einen externen Anbieter erfolgen.


== Situationsanalyse (IST-Zustand)

Die bestehende Software wird aktuell für den Betrieb der Parkhäuser verwendet und bildet den grundlegenden Parkprozess ab. Dazu gehört insbesondere der Ablauf von der Einfahrt eines Fahrzeugs bis zur Ausfahrt nach erfolgter Bezahlung.

Die bestehende Lösung erfüllt jedoch nicht mehr alle Anforderungen des Unternehmens. Anpassungen oder Erweiterungen sind nur schwer möglich. Deshalb soll die Software in den kommenden Jahren durch eine neue Lösung ersetzt werden.


== Rahmenbedingungen


=== Prozessbezogene Rahmenbedingungen

Die Semesterarbeit wird als individuelles Projekt durchgeführt und erstreckt sich über einen Zeitraum von zwölf Wochen. Während dieser Zeit finden zwei Reviews statt, in denen der aktuelle Stand des Projekts überprüft wird.

Im Projekt sollen Methoden aus dem Softwareengineering angewendet werden. Dazu gehören insbesondere Planung, Analyse, Design und Dokumentation der entwickelten Lösung.


=== Produktbezogene Rahmenbedingungen

Die neue Software soll den Parkprozess innerhalb eines Parkhauses abbilden. Dazu gehören insbesondere Einfahrt, Parkieren, Berechnung der Parkgebühren und Ausfahrt.

Das System soll mehrere Parkhäuser verwalten können. Die Struktur eines Parkhauses, insbesondere die Anzahl Stockwerke sowie die Anzahl Parkplätze pro Stockwerk, muss im System definiert werden können.

Externe Systeme wie das Zahlungssystem und die Buchhaltung bleiben bestehen und werden über Schnittstellen angebunden.


== Abgrenzung

Nicht Bestandteil dieses Projekts sind externe Systeme wie das Zahlungssystem oder die Buchhaltung. Diese Systeme werden lediglich über Schnittstellen angebunden.

Die physische Steuerung von Schranken oder Ticketautomaten gehört ebenfalls nicht zum Projektumfang. Für den Prototyp wird die Interaktion mit diesen Komponenten am Bildschirm simuliert.


== Stakeholder-Analyse

#[
  #show figure: set align(left)
#figure(
  table(
    align: left,
    columns: 2,
    table.header(
      [*Stakeholder*], 
      [*Interesse am Projekt*], 
    ),
    [Geschäftsleitung], [Entscheidung über Einführung der neuen Software],
    [IT-Leitung], [Technische Bewertung der Lösung],
    [Betreiber der Parkhäuser], [Zuverlässiger Betrieb der Parkhäuser],
    [Softwareentwickler], [Umsetzung der Anforderungen],
    [Kunden der Parkhäuser], [Einfache Nutzung des Parksystems]
  ),
  caption: [Stakeholderanalyse]
) <stakeholderanalyse>
]


== Ziele

Das Hauptziel des Projekts ist die Entwicklung eines Prototyps für eine neue Parkhaus-Software. Diese Software soll den Parkprozess vollständig unterstützen und mehrere Parkhäuser verwalten können.

Zusätzlich soll eine strukturierte Projektdokumentation erstellt werden, welche Analyse, Design und Umsetzung der Lösung beschreibt.


== Grobe Anforderungen an das neue System

Die neue Software soll den Parkprozess von der Einfahrt bis zur Ausfahrt unterstützen. Dabei müssen zwei Arten von Nutzern berücksichtigt werden: Gelegenheitsnutzer und Dauermieter.

Beim Einfahren eines Gelegenheitsnutzers wird ein Parkticket erstellt. Dieses enthält Informationen über die Einfahrtszeit und den zugewiesenen Parkplatz.

Dauermieter erhalten einen festen Parkplatz und können das Parkhaus mithilfe eines persönlichen Codes betreten.

Die Software muss ausserdem Parkgebühren berechnen können. Die Berechnung basiert auf der Parkdauer sowie auf definierten Tarifen, die je nach Tageszeit variieren können.

Zusätzlich soll das System Auswertungen über die Nutzung und die Umsätze eines Parkhauses erstellen können.


== Lösungskonzept mit Varianten und Beurteilung


=== Varianten

#[
  #show figure: set align(left)
#figure(
  table(
    align: left,
    columns: 4,
    table.header(
      [*Kriterium*],
      [*Desktop-Anwendung*],
      [*Webanwendung*],
      [*Bewertung*],
    ),

    [Installation], [Lokale Installation notwendig], [Keine Installation, läuft im Browser], [Web Vorteil],
    [Zugriff], [Nur auf installiertem Gerät], [Von überall mit Browser zugänglich], [Web Vorteil],
    [Hardware-Anbindung], [Direkter Zugriff möglich], [Nur über Schnittstellen möglich], [Desktop Vorteil],
    [Wartung], [Updates pro Gerät notwendig], [Zentrale Updates], [Web Vorteil],
    [Entwicklungs-komplexität], [Einfacher für Prototyp], [Höherer Aufwand], [Desktop Vorteil],
    [Skalierbarkeit], [Begrenzt], [Gut skalierbar], [Web Vorteil],
    [Offline-Fähigkeit], [Gut möglich], [Eingeschränkt], [Desktop Vorteil],
    [Geeignet für Prototyp], [Sehr gut geeignet], [Eher aufwendig], [Desktop Vorteil]
  ),
  caption: [Variantenvergleich]
) <variantenvergleich>
]

Für die Umsetzung der Parkhaus-Software wurden zwei grundlegende Varianten betrachtet. Einerseits eine klassische Desktop-Anwendung, andererseits eine webbasierte Anwendung.

Die Desktop-Anwendung wird lokal installiert und ausgeführt. Sie kann direkt auf lokale Ressourcen zugreifen und ist einfacher umzusetzen, insbesondere für einen Prototyp. Der Nachteil liegt in der Verteilung und Wartung, da Updates auf jedem System einzeln durchgeführt werden müssen.

Die Webanwendung wird zentral betrieben und über einen Browser genutzt. Dadurch ist sie von verschiedenen Geräten aus zugänglich und einfacher zu warten. Allerdings ist die Entwicklung aufwendiger und der direkte Zugriff auf Hardware ist eingeschränkt.

#heading(outlined: false, level: 4)[Webframework]

#[
  #show figure: set align(left)
#figure(
  table(
    align: left,
    columns: 4,
    table.header(
      [*Kriterium*],
      [*Elixir / Phoenix*],
      [*Express.js*],
      [*Bewertung*],
    ),
    [Nebenläufigkeit], [Eingebaut (BEAM)], [Begrenzt (Single-threaded)], [Phoenix Vorteil],
    [Lernkurve], [Hoch], [Niedrig], [Express Vorteil],
    [Ökosystem], [Klein, spezialisiert], [Gross, weit verbreitet], [Express Vorteil],
    [Echtzeit-UI], [LiveView nativ], [Zusätzliche Bibliotheken nötig], [Phoenix Vorteil],
    [Vorwissen], [Keine Erfahrung], [Grundkenntnisse vorhanden], [Express Vorteil],
    [Stabilität], [BEAM garantiert Fehlertoleranz], [Abhängig von Implementierung], [Phoenix Vorteil],
  ),
  caption: [Variantenvergleich Webframework]
)
]

Für Express.js sind Grundkenntnisse vorhanden, was die Einarbeitung vereinfacht hätte. Elixir und Phoenix bieten jedoch eine bessere Grundlage für eine robuste, nebenläufige Anwendung. Ausserdem war das Kennenlernen einer neuen Technologie ein explizites Lernziel. Deshalb wurde Elixir/Phoenix gewählt.

#heading(outlined: false, level: 4)[Vorgehensmodell]

#[
  #show figure: set align(left)
#figure(
  table(
    align: left,
    columns: 4,
    table.header(
      [*Kriterium*],
      [*Wasserfall*],
      [*Scrum*],
      [*Bewertung*],
    ),
    [Planbarkeit], [Hoch], [Gering], [Wasserfall Vorteil],
    [Flexibilität], [Gering], [Hoch], [Scrum Vorteil],
    [Teamgrösse], [Geeignet für Einzelperson], [Für Teams ausgelegt], [Wasserfall Vorteil],
    [Meilensteine], [Klar definiert], [Sprint-basiert], [Wasserfall Vorteil],
    [Dokumentation], [Klar strukturiert], [Iterativ], [Wasserfall Vorteil],
    [Overhead], [Gering], [Hoch (Meetings, Rollen)], [Wasserfall Vorteil],
  ),
  caption: [Variantenvergleich Vorgehensmodell]
)
]

Scrum ist für Teams mit iterativer Entwicklung ausgelegt. Da das Projekt von einer einzelnen Person durchgeführt wird und die Meilensteine durch die Semesterarbeit vorgegeben sind, ist das Wasserfallmodell besser geeignet. Der geringere organisatorische Overhead kommt einem Einzelprojekt zugute.


=== Machbarkeitsbeurteilung

Beide Varianten (Desktop und Web) sind grundsätzlich realisierbar. Die Webanwendung bietet Vorteile im späteren Betrieb, insbesondere bei Wartung und Zugriff. Für den Umfang dieser Semesterarbeit ist sie jedoch mit höherem Aufwand verbunden. Die Desktop-Anwendung ist einfacher umzusetzen und erlaubt eine schnelle Entwicklung eines funktionalen Prototyps.

Beide Webframeworks sind für die Umsetzung geeignet. Express.js erlaubt dank vorhandener Grundkenntnisse einen schnelleren Einstieg. Elixir und Phoenix sind technisch überlegen, erfordern jedoch eine intensive Einarbeitungszeit.

Sowohl Wasserfall als auch Scrum sind grundsätzlich anwendbar. Für ein Einzelprojekt mit vorgegebenen Meilensteinen bietet das Wasserfallmodell klare Vorteile, da der organisatorische Overhead von Scrum ohne Team kaum gerechtfertigt ist.


=== Variantenentscheid

Für dieses Projekt wird eine Webanwendung gewählt. Diese Entscheidung basiert darauf, dass eine funktionierende Grundlage aufgebaut wird, welche in der Zukunft einfach erweitert werden kann. Ausserdem ermöglicht eine Webanwendung eine einfachere Demonstration des Produktes, ohne dass der Benutzer den Prototyp aufsetzen muss.

Als Webframework wird Elixir/Phoenix eingesetzt. Trotz höherer Lernkurve bietet die Plattform bessere Stabilität und eine native Lösung für Echtzeit-Weboberflächen über LiveView. Das Kennenlernen einer neuen Technologie war zudem ein explizites Lernziel.

Als Vorgehensmodell wird das Wasserfallmodell gewählt. Die Meilensteine sind durch die Semesterarbeit vorgegeben und das Projekt wird von einer einzelnen Person durchgeführt, weshalb der Mehraufwand von Scrum nicht gerechtfertigt ist.


== Projektmanagement


=== Projektplanung

Für die Umsetzung des Projekts wird als Vorgehensmodell das Wasserfallmodell gewählt. Das Projekt wird in klar getrennte Phasen unterteilt.

Die gewählten Phasen orientieren sich an der Vorlage der Semesterarbeit und bestehen aus Initialisierung, Konzept, Realisierung und Dokumentation.

Der Zeitplan ist in Form eines Gantt-Charts dargestellt. Die Planung basiert auf den vorgegebenen Terminen und teilt die Arbeit in mehrere zusammenhängende Aufgaben auf. Während der Realisierung und Dokumentation gibt es bewusst Überschneidungen, um die Dokumentation parallel zur Umsetzung zu erstellen.

Die Planung ist bewusst einfach gehalten und fokussiert sich auf die wichtigsten Meilensteine sowie auf eine sinnvolle zeitliche Aufteilung der Arbeit.

Die Ressourcenplanung ist überschaubar, da das Projekt im Rahmen einer Semesterarbeit von einer einzelnen Person durchgeführt wird. Es stehen keine weiteren Entwickler oder zusätzliche Ressourcen zur Verfügung. Dies wurde bei der Planung berücksichtigt, indem der Umfang auf einen realistischen Prototyp begrenzt wurde.

=== Zeitplan
#figure(
  image("../diagrams/Gantt.png", width: 100%),
  caption: [
    Zeitplan
  ]
)


=== Risikoanalyse

#[
  #show figure: set align(left)
#figure(
  table(
    align: left,
    columns: 3,
    table.header(
      [*Risiko*], 
      [*Beschreibung*], 
      [*Massnahme*], 
    ),
    [Zeitmangel], [Mehraufwand durch neue Technologie], [Kernfunktionen priorisieren, Buffer einplanen],
    [Komplexität], [Unbekannte Konzepte erhöhen Komplexität], [Einfach halten, schrittweise umsetzen],
    [Technologierisiko], [Probleme durch fehlende Erfahrung], [Gezielt einarbeiten, Alternativen bereithalten]
  ),
  caption: [Risikoanalyse]
) <risikoanalyse>
]

=== Qualitätsmanagement

Die Qualität der Lösung wird durch regelmässige Überprüfung der Anforderungen sowie durch Reviews während des Projekts sichergestellt. Zusätzlich wird die Software getestet, um die korrekte Funktion der wichtigsten Abläufe zu prüfen.


=== Konfigurationsmanagement

Der Quellcode sowie die Projektdokumentation werden versioniert gespeichert. Änderungen werden nachvollziehbar dokumentiert, sodass jederzeit der aktuelle Stand des Projekts ersichtlich ist.

Wie der Code sowohl auch die Dokumentation sind in einem Github-Repository gespeichert:

#show link: underline
https://github.com/Adyrem/parking


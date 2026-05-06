= Fazit / Lessons learned

Die Nachvollziehbarkeit für Project Controlling in dieser Arbeit wäre meiner Meinung nach nicht genügend für die Diplomarbeit. In der Diplomarbeit werde ich die geleisteten Aufwände dokumentieren. Ausserdem werde ich häufiger commits erstellen, was ich etwas vernachlässigte, da ich der einzige Entwickler/Tester in diesem Projekt war.

Die Technologiewahl von Elixir/Phoenix hat sich bewährt. Der Funktionale Ansatz machte das automatische Testen sehr einfach. Bis heute bin ich aber sicher noch kein Experte in Elixir und könnte nicht alle Details genau erklären. Z.B. Ecto für die Datenbankanbindung habe ich einfach angewandt, ohne genauer zu hinterfragen wie es funktioniert. Ich werde diese Technologien in der Zukunft wieder verwenden.

Typst + plantuml für die Dokumentation war sehr angenehm. Dank Typst hatte ich nie Probleme bei der Formatierung (im Gegensatz zu Word), ohne die Komplexität von LateX. Der Hauptvorteil von plantuml war, dass ich die Diagramme als code abspeichern konnte. Dadurch konnte ich die Diagramme einerseits sehr einfach anpassen und andererseits einfacher als Kontext an KI weitergeben.

Die Verwendung von KI war sehr hilfreich beim Lernen der neuen Programmiersprache. Ich konnte Anfängerfehler direkt verbessern und Designentscheidungen welche mir später in den Weg kommen würden, konnten frühzeitig erkannt und verbessert werden. Ausserdem konnte mich die KI daran erinnern, wenn ich beim Implementieren Abweichungen zum Konzept hatte.

= Anhang

== Parktarife

Die nachfolgenden Tarife sind dem Lastenheft entnommen und bilden die Grundlage für die Implementierung der Gebührenberechnung.

#[
  #show figure: set align(left)
#figure(
  table(
    align: left,
    columns: (1fr, auto),
    table.header([*Zeitraum*], [*Tarif*]),
    table.cell(colspan: 2)[*Wochentage*],
    [00:00 - 05:59], [CHF 2.50 / Std.],
    [06:00 - 08:59], [CHF 2.80 / Std.],
    [09:00 - 17:59], [CHF 3.60 / Std.],
    [18:00 - 20:59], [CHF 2.80 / Std.],
    [21:00 - 23:59], [CHF 2.40 / Std.],
    table.cell(colspan: 2)[*Wochenende und Feiertage*],
    [00:00 - 08:59], [CHF 2.40 / Std.],
    [09:00 - 17:59], [CHF 3.20 / Std.],
    [18:00 - 23:59], [CHF 2.40 / Std.],
  ),
  caption: [Parktarife (Quelle: Lastenheft)]
)
]

Die Abrechnung erfolgt auf Viertelstundenbasis. Der Tarif zu Beginn einer Viertelstunde gilt für die gesamte Viertelstunde. Bei einer Parkdauer von über 24 Stunden wird eine Tagespauschale von CHF 35.00 pro Tag angewendet. Angebrochene Tage werden vollständig verrechnet.

== Lastenheft

Das Lastenheft ist als separater Anhang verfügbar.
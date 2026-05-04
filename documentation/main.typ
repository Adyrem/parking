#set text(lang: "de")
#set page("a4")
#set page(margin: 2cm)

#set text(lang: "de", size: 11pt)
#set page(margin: (left: 3cm, bottom: 2cm, top: 2cm))
#set par(leading: 0.5em)
#set text(font: "DM Sans")

#include "titelblatt.typ"

#include "chapters/00_abstract.typ"

#pagebreak()

#heading(outlined: false, numbering: none)[Inhaltsverzeichnis]
#show outline.entry.where(
  level: 1
): set block(above: 1em)
#outline(
    title: none,
    indent: 2em,
    depth: 2
)

#pagebreak()

#set page(numbering: "1")
#counter(page).update(1)
#set heading(numbering: "1.")

#include "chapters/01_initialisierung.typ"

#pagebreak()

#include "chapters/02_konzept.typ"

#pagebreak()

#include "chapters/03_realisierung.typ"

#pagebreak()

#include "chapters/04_fazit.typ"

#pagebreak()

#bibliography("works.yml", title: [Literaturverzeichnis], style: "ieee")

#heading(numbering: none)[Tabellenverzeichnis]
#outline(title: none, target: figure.where(kind: table))

#heading(numbering: none)[Abbildungsverzeichnis]
#outline(title: none, target: figure.where(kind: image))


#heading(numbering: none)[Hilfsmittelverzeichnis]

#show table.cell.where(y: 0): strong

#figure(
  table(
    align: left,
    columns: 3,
    table.header(
      [Welches Hilfsmittel wurde eingesetzt?],
      [Wozu wurde das Hilfsmittel eingesetzt?],
      [Betroffene Stellen],
    ),
    [Typst], [Dokumentenerstellung, Rechtschreibkorrektur], [Gesamtes Dokument],
    [Claude], [Dokumentation abgleichen mit Code, Code generierung], [Initialisierung, Konzept, Realisierung],
    [plantuml], [Diagramm Erstellung], [Abbildungen],
  ),
  caption: [Hilfsmittel (eigene Darstellung)]
)


#heading(numbering: none)[Glossar]
#figure(
  table(
    align: left,
    columns: (1fr, 3fr),
    table.header(
      [*Fachwort*], [*Bedeutung*],
    ),
    [BEAM (Bogdan's Erlang Abstract Machine)], [Die virtuelle Maschine, auf der Elixir und Erlang ausgeführt werden. Sie unterstützt Nebenläufigkeit und hohe Fehlertoleranz.],
    [DSL (Domain Specific Language)], [Eine auf einen bestimmten Anwendungsbereich zugeschnittene Abfragesprache. Im Projekt wird die Ecto-Query-DSL für Datenbankabfragen verwendet.],
    [UUID (Universally Unique Identifier)], [128-Bit-Bezeichner, der weltweit eindeutig ist. Im Projekt als Primärschlüssel für Parktickets verwendet.],
  ),
  caption: [Glossar (eigene Darstellung)]
)

#pagebreak()

#heading(numbering: none)[Eigenständigkeitserklärung]
Hiermit bestätige ich, dass ich die vorliegende Semesterarbeit selbstständig erstellt habe und nur die angegebenen Quellen verwendet wurden.

Bern, 11. Mai 2026

#align(center)[Adrian Aeschlimann]
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
    [Typst], [Rechtschreibkorrektur], [Gesamtes Dokument],
    [ChatGPT], [Rechtschreibkorrektur], [Gesamtes Dokument],    [plantuml], [Diagramm Erstellung], [Abbildungen],
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
    /*[ADR (Architecture Decision Record)], [Dokumentationen, in denen Architekturentscheidungen begründet und festgehalten werden, um nachvollziehbar zu machen, warum bestimmte technische Lösungen gewählt wurden.],
    [CI/CD (Continuous Integration/Continuous Deployment)], [Prozesse, die es ermöglichen, Codeänderungen kontinuierlich zu integrieren, automatisiert zu testen und anschließend in produktive Systeme zu deployen – essenziell für einen schnellen und iterativen Entwicklungsprozess.],
    [Docker], [Eine Plattform zur Erstellung und Ausführung von Containern, die eine standardisierte, isolierte Umgebung für Anwendungen bereitstellt.],
    [GPS (Global Positioning System)], [Ein satellitengestütztes System zur Standortbestimmung, das in der Applikation verwendet wird, um den aktuellen Standort des Nutzers zu ermitteln.],
    [Linter], [Ein Tool, das Code oder Dokumente (z. B. Markdown) automatisch auf Einhaltung bestimmter Stil- und Formatierungsregeln überprüft.],
    [Message Broker], [Ein System, das Nachrichten (z. B. zu Parkplatzbelegungen) zwischen verschiedenen Komponenten (wie Sensoren und der API) vermittelt, um eine asynchrone Kommunikation zu ermöglichen.],
    [SMARP], [Name der Applikation was ein Akronym für Smart Parking ist.],*/

  ),
  caption: [Glossar (eigene Darstellung)]
)

#pagebreak()

#heading(numbering: none)[Eigenständigkeitserklärung]
Hiermit erklären ich, dass ich diese Arbeit ohne fremde Hilfe und ohne Verwendung anderer als angegebener Hilfsmittel verfasst haben.

Bern, xx. März 2026

#align(center)[Adrian Aeschlimann]
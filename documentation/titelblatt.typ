#set page(
  paper: "a4",
  header: align(right)[
    #image("TEKO-logo-pink.svg", height: 24pt)
  ]
)
#set text(lang: "de")
#set align(center)

#v(1cm)

#text("TEKO Schweizerische Fachschule", size: 16pt, weight: "bold")
#v(1cm)
#text("Software Engineering", size: 13pt, weight: "bold")
#v(0.5cm)
// #line(length: 100%, stroke: color.linear-rgb(228, 22, 106))
#line(length: 100%)
#v(0.1cm)
#text("Semesterarbeit", size: 19pt, weight: "bold")
#v(0.1cm)
#text("Parkhaus app", size: 19pt, weight: "bold")
#v(0.4cm)
#line(length: 100%)

#v(3cm)

#pad(x: 80pt)[
  #grid(
    columns: (1fr, 1fr),
    gutter: 0pt,
    align(left)[
      _Autor:_\
      Adrian Aeschlimann\

    ],
    align(right)[
      _Dozent:_\
      Patrick Graber
    ]
  )
]

#v(3cm)

#text("Abgabedatum: 12.05.2026")\
#text("Version 0.1")

---
marp: true
theme: default
paginate: true
style: |
  section.small-table table {
    font-size: 0.75em;
  }
  section.img-slide img {
    display: block;
    margin: 0 auto;
  }
---

# Parkhaus-Verwaltungssoftware
### Semesterarbeit Software Engineering

Adrian Aeschlimann · TEKO Schweizerische Fachschule · Mai 2026

---

## Ausgangslage

- EasyParking AG: mehrere Parkhäuser, veraltete Software
- Keine geeignete Standardlösung gefunden
- **Ziel:** Lastenheft + funktionsfähiger Prototyp

---

<!-- _class: small-table -->

## Zwei Nutzertypen

| | Gelegenheitsnutzer | Dauermieter |
|---|---|---|
| Einfahrt | Ticket erhalten | Code eingeben |
| Parkplatz | Automatisch zugewiesen | Fixer Platz |
| Bezahlung | Vor Ausfahrt | Monatliche Miete |
| Ausfahrt | Austrittsticket scannen | Code eingeben |

---

## Technologie-Stack

- **Elixir / Phoenix / LiveView** — serverseitige UI, kein JS-Framework
- **PostgreSQL** + Ecto — relationale Datenhaltung
- **BEAM** — Nebenläufigkeit und Stabilität

Motivation: neue Technologie im Rahmen der Arbeit kennenlernen

---

<!-- _class: img-slide -->

## Architektur

<img src="diagrams/Moduluebersicht.png" width="60%">

---

## Preisberechnung — Strategy Pattern

```
PricingStrategy (Behaviour)
├── TimeBasedPricing   ← Viertelstundentarif, Zeit-/Wochenend-/Feiertagsslots
└── FlatRatePricing    ← Einfache Tagespauschale
```

- Viertelstundenabrechnung (Tarif zu Beginn gilt für ganze Viertelstunde)
- Separate Slots für Wochenende und Feiertage
- Ab 24 Stunden → Tagespauschale CHF 35.00
- Monatsmiete pro Parkhaus konfigurierbar (eigener Tarif-Typ)

---

<!-- _class: small-table -->

## Benutzeroberfläche

| Ansicht | Funktion |
|---|---|
| Parkhaus-Ansicht | Einfahrt, Bezahlung, Ausfahrt — für beide Nutzertypen |
| Admin | Dauermieter verwalten, Miete buchen, Sperrstatus |
| Statistik | Monats-/Jahresumsatz nach Kundenkategorie |

→ Live-Demo

---

<!-- _class: img-slide -->

## Datenbank

<img src="diagrams/ERD_Realisierung.png" width="40%">

---

<!-- _class: small-table -->

## Tests

22 Testfälle · ExUnit · alle bestanden

| Kategorie | Testfälle |
|---|---|
| Einfahrt & Parkplatzzuweisung | TC-01, TC-02 |
| Preisberechnung | TC-03, TC-04, TC-05, TC-06, TC-19, TC-20, TC-21, TC-22 |
| Dauermieter & Authentifizierung | TC-07, TC-08 |
| Bezahlung & Ausfahrt | TC-09, TC-10, TC-11, TC-12 |
| Statistiken | TC-13, TC-14 |
| Nicht-funktionale Anforderungen | TC-15, TC-16, TC-17, TC-18 |

---

## Fazit

**Erreicht:**
- Vollständiger Parkierungsprozess für beide Nutzertypen
- Konfigurierbare Preisberechnung mit Strategy Pattern
- Admin-Dashboard und Statistikauswertung
- 22 Testfälle bestanden

**Learnings:**
- LiveView vereinfacht serverseitige UI erheblich
- Elixer-Ökosystem: robuste Grundlage für Prototyp
- Controlling hat Verbesserungspotenzial

---

## Demo

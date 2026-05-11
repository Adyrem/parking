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
  section.code-compare .cols {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 1.5em;
  }
  section.code-compare pre {
    font-size: 0.6em;
    margin: 0.2em 0;
  }
  section.code-compare p strong {
    font-size: 0.9em;
  }
---

# Parkhaus-Verwaltungssoftware
### Semesterarbeit Software Engineering

Adrian Aeschlimann · TEKO Bern · 12.05.2026

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

- **Elixir / Phoenix / LiveView** - serverseitige UI, kein JS-Framework
- **PostgreSQL** + Ecto - relationale Datenhaltung
- **BEAM** - Nebenläufigkeit und Stabilität

Motivation: neue Technologie im Rahmen der Arbeit kennenlernen

---

<!-- _class: code-compare -->

## Elixir vs. C# - Fehlerbehandlung

<div class="cols">
<div>

**Elixir** - Pattern Matching

```elixir
case GuestParking.process_payment(ticket) do
  {:ok, _}    -> "Bezahlung erfolgreich"
  {:error, _} -> "Zahlung fehlgeschlagen"
end
```

</div>
<div>

**C#** - Exceptions

```csharp
try {
  GuestParking.ProcessPayment(ticket);
  return "Bezahlung erfolgreich";
} catch (Exception) {
  return "Zahlung fehlgeschlagen";
}
```

</div>
</div>

---

<!-- _class: img-slide -->

## Architektur

<img src="diagrams/Moduluebersicht.png" width="80%">

---

## Preisberechnung - Strategy Pattern

```
PricingStrategy (Behaviour)
├── TimeBasedPricing <- Viertelstundentarif, Zeit-/Wochenend-/Feiertagsslots
└── FlatRatePricing  <- Einfache Tagespauschale
```

- Viertelstundenabrechnung (Tarif zu Beginn gilt für ganze Viertelstunde)
- Separate Slots für Wochenende und Feiertage
- Ab 24 Stunden: Tagespauschale CHF 35.00

---
<!-- _class: small-table -->

<!-- ## Benutzeroberfläche

| Ansicht | Funktion |
|---|---|
| Parkhaus-Ansicht | Einfahrt, Bezahlung, Ausfahrt - für beide Nutzertypen |
| Admin | Dauermieter verwalten, Miete buchen, Sperrstatus |
| Statistik | Monats-/Jahresumsatz nach Kundenkategorie |

-> Live-Demo

----->

<!-- _class: img-slide -->

<!--## Datenbank

<img src="diagrams/ERD_Realisierung.png" width="40%">

----->

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

## Demo

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

## Fragen / Feedback
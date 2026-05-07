#heading(outlined: false, numbering: none)[Abstract]

Diese Semesterarbeit beschreibt die Erarbeitung eines Lastenhefts (siehe Anhang) sowie die Entwicklung eines funktionsfähigen Prototyps für eine neue Parkhaus-Verwaltungssoftware im Auftrag der fiktiven Firma EasyParking AG. Die bestehende Software des Unternehmens soll abgelöst werden. Da keine geeignete Standardlösung gefunden wurde, wird eine eigene Anwendung entwickelt.

Im ersten Teil der Arbeit werden die Anforderungen erhoben und in einem Lastenheft dokumentiert. Dabei werden funktionale, nicht-funktionale und organisatorische Anforderungen definiert. Die Analyse umfasst zwei Benutzerkategorien. Gelegenheitsnutzer, die ein Parkticket erhalten und vor der Ausfahrt abgerechnet werden, sowie Dauermieter mit fixem Parkplatz und monatlicher Miete.

Der zweite Teil umfasst die Konzeption und Umsetzung des Prototyps als Webanwendung. Als technische Grundlage dienen die Programmiersprache Elixir und das Web-Framework Phoenix mit LiveView. Der Prototyp bildet den vollständigen Parkierungsprozess ab. Von der Einfahrt über die Gebührenberechnung und Bezahlung bis zur Ausfahrt. Zusätzlich sind ein Admin Dashboard zur Verwaltung von Dauermietern sowie eine Statistikansicht mit Umsatzauswertungen implementiert.

Die Gebührenberechnung erfolgt auf Viertelstundenbasis mit konfigurierbaren Tarifen je nach Tageszeit, Wochentag und Feiertag (siehe Anhang). Bei einer Parkdauer von über 24 Stunden wird automatisch auf eine Tagespauschale umgestellt. Die Parkplatzzuweisung für Gelegenheitsnutzer basiert auf einem Algorithmus, der eine ausgeglichene Verteilung über die Stockwerke anstrebt.

Die Korrektheit der zentralen Geschäftslogik wird durch automatisierte Tests mit ExUnit sichergestellt.
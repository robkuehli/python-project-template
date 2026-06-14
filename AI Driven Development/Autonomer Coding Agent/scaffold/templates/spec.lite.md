# spec.md (Lite) — <Projektname>
<!--
  LITE-Spec fuer kleine PoCs (1-3 Dateien, klares Pattern). Bewusst KEIN voller Spec-Kit-Cascade
  (constitution->specify->clarify->plan->tasks->analyze->implement) — der waere fuer einen 2-Datei-PoC
  Overkill (siehe 06-spec-workflow.md, SDD-Challenge). Ab ~mittlerem MVP (5-7 Dateien) auf den vollen
  Spec-Kit-Flow wechseln. Diese Datei ist trotzdem genug Struktur, damit der Agent nicht driftet.
-->

## Ziel (1-2 Saetze)
<Was soll am Ende laufen? Welches Problem loest es?>

## Stack / Constraints
<Sprache, Framework, Laufzeit. Was ist gesetzt, was ist frei?>

## Funktionale Anforderungen
- F1: <...>
- F2: <...>

## Akzeptanzkriterien (test-bar formulieren!)
<!-- Diese werden 1:1 zu Tests. Konkret + beobachtbar am public contract. -->
- [ ] AK1: Wenn <Input/Aktion>, dann <beobachtbares Ergebnis>.
- [ ] AK2: Bei <Fehlerfall>, dann <definierter Fehler/Exit-Code/Status>.

## Out of Scope (explizit!)
- <Was NICHT gebaut wird — schuetzt vor Scope-Creep des Agenten>

## Beispiele / I-O
<!-- Ein konkretes Eingabe->Ausgabe-Beispiel pro Hauptpfad. Reduziert Halluzination massiv. -->
```
Input:  ...
Output: ...
```

## Offene Annahmen
<!-- Wenn du selbst unsicher bist: hier vormerken. Der Agent traegt seine Annahmen in DECISIONS.md nach. -->

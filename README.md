# Rozwiązywanie konfliktów w Gicie (Power BI)

Kiedy dwie gałęzie zmieniają to samo miejsce w pliku, Git nie wie, którą wersję zostawić, i prosi Cię o decyzję. Poniżej najważniejsze zasady z warsztatu.

## Kiedy wziąć wersję z zewnątrz

Przycisk "Accept Incoming Change" bierze wersję z gałęzi, którą wciągasz. W ćwiczeniu to `dev_XX`, bo wpisujesz `git merge dev_XX`. W dokumentacji Gita nazywa się to "theirs". Wybierz, gdy zmiany z zewnątrz są nowsze albo lepsze od Twoich.

## Gdy obie wersje są złe

VS Code nie ma przycisku "odrzuć obie". Plik z konfliktem to zwykły tekst, więc:

1. Zaznacz cały blok razem ze znacznikami `<<<<<<<`, `=======` i `>>>>>>>`.
2. Usuń go i wpisz poprawną wersję.
3. Zapisz plik.

## Widoki konfliktu w VS Code

- Inline: obie wersje w jednym pliku, oznaczone kolorami (widok domyślny).
- Side-by-side: Twoja wersja po lewej, przychodząca po prawej.
- Merge Editor: Current i Incoming na górze, wynik na dole. Przydaje się przy dłuższym DAX-ie.
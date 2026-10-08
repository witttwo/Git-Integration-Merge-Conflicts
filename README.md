# Rozwiązywanie konfliktów w Gicie (Power BI)

Kiedy dwie gałęzie zmieniają to samo miejsce w pliku, Git nie wie, którą wersję zostawić, i prosi Cię o decyzję. Poniżej najważniejsze zasady z warsztatu.

## Kiedy zostawić swoją wersję

Przycisk "Accept Current Change" zostawia wersję z gałęzi, na której stoisz. W ćwiczeniu to `baza_XX`. W dokumentacji Gita nazywa się to "ours". Wybierz, gdy Twoja wersja jest poprawna i nie chcesz, żeby nadpisało ją coś z zewnątrz.

## Przerwanie merge'a

Za dużo konfliktów albo nie wiesz, co wybrać? Wpisz `git merge --abort`. Projekt wraca do stanu sprzed merge'a i nic nie tracisz.

## Wyjście z edytora Vim

Jeśli po `git commit` bez opisu terminal zamienił się w pełnoekranowy edytor z tyldami (~), to Vim.

- Zapis i wyjście: Esc, potem `:wq` i Enter.
- Wyjście bez zapisu: Esc, potem `:q!` i Enter.
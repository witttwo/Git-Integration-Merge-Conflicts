# Git Integration: Merge Conflicts

Repozytorium ćwiczeniowe do warsztatu o konfliktach w Gicie (projekt Power BI w formacie PBIP).

## Przed warsztatem

1. Sklonuj repo do krótkiej ścieżki (np. `C:\Git\`), nie do OneDrive.
2. Przełącz się na gałąź `workshop`.
3. Zainstaluj w VS Code rozszerzenie **PowerShell** (Microsoft).

## Na warsztacie

W terminalu VS Code, w folderze repo:

```powershell
.\Conflict_generator.ps1
```

Gdy Windows zablokuje skrypt:

```powershell
powershell -ExecutionPolicy Bypass -File .\Conflict_generator.ps1
```

Skrypt pyta o inicjały, tworzy gałęzie `baza_<inicjały>` i `dev_<inicjały>` i scala je, wywołując konflikt.
Coś poszło nie tak? `git merge --abort`, a potem uruchom skrypt jeszcze raz.

# ==========================================
# GENERATOR KONFLIKTU - warsztat "Git Integration: Merge Conflicts"
# Uruchomienie (terminal w VS Code, w folderze repo):
#   .\Conflict_generator.ps1
# W razie blokady Windowsa:
#   powershell -ExecutionPolicy Bypass -File .\Conflict_generator.ps1
# ==========================================

Set-Location $PSScriptRoot
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)

function Read-Text($path) { [System.IO.File]::ReadAllText((Join-Path $PSScriptRoot $path), $utf8NoBom) }
function Write-Text($path, $text) { [System.IO.File]::WriteAllText((Join-Path $PSScriptRoot $path), $text, $utf8NoBom) }

# Podmienia dokładnie jedno wystąpienie; jeśli wzorca nie ma, przerywa skrypt (zamiast cicho nic nie zmienić)
function Set-Once($text, $find, $replace) {
    $idx = $text.IndexOf($find)
    if ($idx -lt 0) { throw "Nie znaleziono w pliku fragmentu: $find" }
    return $text.Substring(0, $idx) + $replace + $text.Substring($idx + $find.Length)
}

# ==========================================
# 0. WALIDACJA
# ==========================================
if (-not (git rev-parse --is-inside-work-tree 2>$null)) {
    Write-Host "To nie jest repozytorium Git. Uruchom skrypt w folderze sklonowanego repo." -ForegroundColor Red; exit 1
}
if (Test-Path (Join-Path (git rev-parse --git-dir) "MERGE_HEAD")) {
    Write-Host "Trwa niedokończony merge. Najpierw: git merge --abort  (albo dokończ go commitem)." -ForegroundColor Red; exit 1
}
if (git status --porcelain) {
    Write-Host "Masz niezapisane zmiany. Zrób commit albo: git stash  - i uruchom skrypt ponownie." -ForegroundColor Red; exit 1
}

do {
    $i = (Read-Host "Podaj swoje inicjaly (np. MJ)").Trim()
} while ($i -notmatch '^[A-Za-z0-9_-]{1,10}$')

$devBranch = "dev_$i"
$baseBranch = "baza_$i"

# 1. PUNKT STARTOWY (obie gałęzie powstają z tego samego commita)
# Zawsze gałąź 'workshop', więc skrypt można odpalić ponownie także po 'git merge --abort'
$startCommit = git rev-parse --verify --quiet workshop
if (-not $startCommit) { $startCommit = git rev-parse --verify --quiet origin/workshop }
if (-not $startCommit) {
    Write-Host "Nie widzę gałęzi 'workshop'. Wykonaj: git fetch  oraz  git checkout workshop" -ForegroundColor Red; exit 1
}

# ==========================================
# 2. ORYGINAŁY
# ==========================================
$tmdlPath = "Git Conflict.SemanticModel\definition\tables\_Global Measures.tmdl"
$visOldPath = "Git Conflict.Report\definition\pages\7a1007e13b28c6d51010\visuals\ff390bfdbc0aea10ab08\visual.json"

# Fragmenty, które zmieniamy. Każdy konflikt ma INNY tekst i inną akcję do przećwiczenia:
#   KONFLIKT 1  miara 'HTML_KPI_Card_Dynamic' (etykieta) -> Accept Current
#   KONFLIKT 2  miara 'Reps Headaer' (nagłówek)  -> ręczna edycja (własny tekst)
#   KONFLIKT 3  visual.json (kolor + kształt markera, 2 bloki) -> Accept Incoming w obu
#   KONFLIKT 4  README.md                        -> Accept Both
#   BEZ KONFLIKTU: 'Sales Shares' zmienia tylko DEV, 'Product Shares' zmienia tylko BAZA -> Git scala sam
$consistencyOld = '_Consistent && NOT ( _Falling ), "High sales consistency ✔"'
$repsHeaderOld = 'VAR _Header = "Sales reps"'
$salesShareHeaderOld = 'VAR _Header = "Sales share"'
$productSubtitleOld = 'VAR _Subtitle = "Which products and brands generate the most sales?"'
$markerAnchor = '(?s)("markerSize":\s*\{\s*"expr":\s*\{\s*"Literal":\s*\{\s*"Value":\s*"7D"\s*\}\s*\}\s*\})'

# ==========================================
# 3. GAŁĄŹ DEV (to, co "przychodzi" = Incoming)
# ==========================================
git checkout -B $devBranch $startCommit 2>$null

# Oryginały czytamy dopiero po przejściu na punkt startowy (a nie z gałęzi, na której ktoś akurat stał)
$tmdlOryginal = Read-Text $tmdlPath
$visOryginal = Read-Text $visOldPath

$tmdlDev = $tmdlOryginal
$tmdlDev = Set-Once $tmdlDev $consistencyOld '_Consistent && NOT ( _Falling ), "🚀 Rock-solid sales (DEV)"'
$tmdlDev = Set-Once $tmdlDev $repsHeaderOld 'VAR _Header = "Sales Team Leaderboard"'
$tmdlDev = Set-Once $tmdlDev $salesShareHeaderOld 'VAR _Header = "Territory Pareto 80/20"'
Write-Text $tmdlPath $tmdlDev

$visDev = $visOryginal.Replace('2.11.0/schema.json', '2.12.0/schema.json')
$markerDev = @'
$1,
            "markerColor": {
              "solid": {
                "color": {
                  "expr": {
                    "ThemeDataColor": {
                      "ColorId": 7,
                      "Percent": 0.2
                    }
                  }
                }
              }
            }
'@
$visDev = [regex]::Replace($visDev, $markerAnchor, $markerDev.Replace("`r`n", "`n"))
Write-Text $visOldPath $visDev

$readmeDev = @"
# ⚔️ KOMPENDIUM: ROZWIĄZYWANIE KONFLIKTÓW (GIT W POWER BI) ⚔️

Podczas łączenia gałęzi (merge), Git czasami nie wie, którą wersję pliku zachować. 
Wtedy do akcji wkraczasz Ty! Poniżej znajdziesz najważniejsze zasady z warsztatów:

🔵 **ACCEPT INCOMING CHANGE (Akceptuj przychodzącą zmianę)**
* **Czym to jest:** Zmiana pochodząca z gałęzi, którą właśnie wciągasz (np. gdy wpisujesz 'git merge dev_MJ', to jest to zawartość 'dev_MJ').
* **Terminologia Git:** W dokumentacji oznaczane jako 'Theirs' (Ich).
* **Kiedy używać:** Gdy pobierasz aktualizacje z serwera i wiesz, że praca zespołu nadpisuje Twoje stare wersje.

❌ **A CO JEŚLI OBIE WERSJE SĄ ZŁE? (BRAK "REJECT BOTH")**
W VS Code nie ma przycisku odrzucenia obu zmian. Pamiętaj, że ostateczny kod to po prostu zwykły plik tekstowy!
1. Zignoruj kolorowe przyciski "Accept...".
2. Zaznacz cały zepsuty blok myszką (razem ze znacznikami <<<<<<< HEAD, ======= oraz >>>>>>>).
3. Wciśnij Delete i po prostu napisz swój poprawny kod w tym miejscu. Zapisz plik!

👁️ **TIP: ZAAWANSOWANE WIDOKI KONFLIKTÓW W VS CODE**
W prawym górnym rogu nad skonfliktowanym kodem (lub pod 3 kropkami) masz opcje widoku:
* **Inline View:** Wszystko zlane w jeden tekst z kolorowymi blokami (widok domyślny).
* **Column View (Side-by-side):** Ekran dzieli się na pół - Twoje zmiany po lewej, przychodzące po prawej.
* **Open in Merge Editor:** Odpala potężne, dedykowane okno. Na górze widzisz 'Current' i 'Incoming', a na dole 'Result' (Ostateczny wynik). Niezastąpione przy trudnym DAXie!
"@
Write-Text "README.md" $readmeDev

$vis1Path = "Git Conflict.Report\definition\pages\7a1007e13b28c6d51010\visuals\bd321ca30d8572eac95e"
$vis2Path = "Git Conflict.Report\definition\pages\7a1007e13b28c6d51010\visuals\632c3c5cf00bcacde04d"
$vis3Path = "Git Conflict.Report\definition\pages\7a1007e13b28c6d51010\visuals\093aef5b47cf7c8c4607"
New-Item -Path $vis1Path -ItemType Directory -Force | Out-Null
New-Item -Path $vis2Path -ItemType Directory -Force | Out-Null
New-Item -Path $vis3Path -ItemType Directory -Force | Out-Null

$json1 = @'
{ "$schema": "https://developer.microsoft.com/json-schemas/fabric/item/report/definition/visualContainer/2.12.0/schema.json", "name": "bd321ca30d8572eac95e", "position": { "x": 852.99, "y": 64.66, "z": 20001, "height": 158.75, "width": 290, "tabOrder": 20001 }, "visual": { "visualType": "image", "objects": { "image": [ { "properties": { "sourceType": { "expr": { "Literal": { "Value": "'imageData'" } } }, "sourceField": { "expr": { "Measure": { "Expression": { "SourceRef": { "Entity": "_Global Measures" } }, "Property": "KPI Card Orders IMG" } } } } } ] }, "visualContainerObjects": { "dropShadow": [ { "properties": { "show": { "expr": { "Literal": { "Value": "true" } } }, "color": { "solid": { "color": { "expr": { "ThemeDataColor": { "ColorId": 0, "Percent": -0.1 } } } } } } } ], "border": [ { "properties": { "show": { "expr": { "Literal": { "Value": "true" } } }, "color": { "solid": { "color": { "expr": { "ThemeDataColor": { "ColorId": 0, "Percent": -0.1 } } } } }, "radius": { "expr": { "Literal": { "Value": "20D" } } } } } ], "background": [ { "properties": { "show": { "expr": { "Literal": { "Value": "true" } } }, "transparency": { "expr": { "Literal": { "Value": "0D" } } } } } ] }, "drillFilterOtherVisuals": true } }
'@
$json2 = @'
{ "$schema": "https://developer.microsoft.com/json-schemas/fabric/item/report/definition/visualContainer/2.12.0/schema.json", "name": "632c3c5cf00bcacde04d", "position": { "x": 543.75, "y": 66.25, "z": 20002, "height": 157.5, "width": 290, "tabOrder": 20002 }, "visual": { "visualType": "image", "objects": { "image": [ { "properties": { "sourceType": { "expr": { "Literal": { "Value": "'imageData'" } } }, "sourceField": { "expr": { "Measure": { "Expression": { "SourceRef": { "Entity": "_Global Measures" } }, "Property": "KPI Card Quota IMG" } } } } } ] }, "visualContainerObjects": { "dropShadow": [ { "properties": { "show": { "expr": { "Literal": { "Value": "true" } } }, "color": { "solid": { "color": { "expr": { "ThemeDataColor": { "ColorId": 0, "Percent": -0.1 } } } } }, "transparency": { "expr": { "Literal": { "Value": "35D" } } }, "shadowBlur": { "expr": { "Literal": { "Value": "15D" } } } } } ], "border": [ { "properties": { "show": { "expr": { "Literal": { "Value": "true" } } }, "color": { "solid": { "color": { "expr": { "ThemeDataColor": { "ColorId": 0, "Percent": -0.1 } } } } }, "radius": { "expr": { "Literal": { "Value": "20D" } } }, "width": { "expr": { "Literal": { "Value": "1D" } } } } } ], "background": [ { "properties": { "show": { "expr": { "Literal": { "Value": "true" } } }, "color": { "solid": { "color": { "expr": { "ThemeDataColor": { "ColorId": 0, "Percent": 0 } } } } }, "transparency": { "expr": { "Literal": { "Value": "0D" } } } } } ], "title": [ { "properties": { "show": { "expr": { "Literal": { "Value": "false" } } }, "titleWrap": { "expr": { "Literal": { "Value": "true" } } }, "fontColor": { "solid": { "color": { "expr": { "Literal": { "Value": "'#0F3460'" } } } } }, "fontSize": { "expr": { "Literal": { "Value": "'14'" } } }, "fontFamily": { "expr": { "Literal": { "Value": "'Arial'" } } } } } ], "spacing": [ { "properties": { "verticalSpacing": { "expr": { "Literal": { "Value": "2D" } } } }, "selector": { "id": "default" } } ], "padding": [ { "properties": { "top": { "expr": { "Literal": { "Value": "5D" } } }, "bottom": { "expr": { "Literal": { "Value": "0D" } } }, "left": { "expr": { "Literal": { "Value": "0D" } } }, "right": { "expr": { "Literal": { "Value": "0D" } } } } } ] }, "drillFilterOtherVisuals": true } }
'@
$json3 = @'
{ "$schema": "https://developer.microsoft.com/json-schemas/fabric/item/report/definition/visualContainer/2.12.0/schema.json", "name": "093aef5b47cf7c8c4607", "position": { "x": 236.66, "y": 64.44, "z": 20003, "height": 158.88, "width": 290, "tabOrder": 20003 }, "visual": { "visualType": "image", "objects": { "image": [ { "properties": { "sourceType": { "expr": { "Literal": { "Value": "'imageData'" } } }, "sourceField": { "expr": { "Measure": { "Expression": { "SourceRef": { "Entity": "_Global Measures" } }, "Property": "KPI Card Net Sales IMG" } } } } } ] }, "visualContainerObjects": { "dropShadow": [ { "properties": { "show": { "expr": { "Literal": { "Value": "true" } } }, "color": { "solid": { "color": { "expr": { "ThemeDataColor": { "ColorId": 0, "Percent": -0.1 } } } } }, "transparency": { "expr": { "Literal": { "Value": "35D" } } }, "shadowBlur": { "expr": { "Literal": { "Value": "15D" } } } } } ], "border": [ { "properties": { "show": { "expr": { "Literal": { "Value": "true" } } }, "color": { "solid": { "color": { "expr": { "Literal": { "Value": "'#006084'" } } } } }, "radius": { "expr": { "Literal": { "Value": "20D" } } }, "width": { "expr": { "Literal": { "Value": "1D" } } } } } ], "background": [ { "properties": { "show": { "expr": { "Literal": { "Value": "true" } } }, "color": { "solid": { "color": { "expr": { "Literal": { "Value": "'#006084'" } } } } }, "transparency": { "expr": { "Literal": { "Value": "0D" } } } } } ], "title": [ { "properties": { "show": { "expr": { "Literal": { "Value": "false" } } }, "titleWrap": { "expr": { "Literal": { "Value": "true" } } }, "fontColor": { "solid": { "color": { "expr": { "Literal": { "Value": "'#0F3460'" } } } } }, "fontSize": { "expr": { "Literal": { "Value": "'14'" } } }, "fontFamily": { "expr": { "Literal": { "Value": "'Arial'" } } } } } ], "spacing": [ { "properties": { "verticalSpacing": { "expr": { "Literal": { "Value": "2D" } } } }, "selector": { "id": "default" } } ], "padding": [ { "properties": { "top": { "expr": { "Literal": { "Value": "5D" } } }, "bottom": { "expr": { "Literal": { "Value": "0D" } } }, "left": { "expr": { "Literal": { "Value": "0D" } } }, "right": { "expr": { "Literal": { "Value": "0D" } } } } } ] }, "drillFilterOtherVisuals": true } }
'@

Write-Text "$vis1Path\visual.json" $json1
Write-Text "$vis2Path\visual.json" $json2
Write-Text "$vis3Path\visual.json" $json3

git add .
git commit -m "DEV: 3 nowe KPI, Rock-solid sales, Sales Team Leaderboard, Pareto 80/20, marker ColorId 7" --quiet

# ==========================================
# 4. GAŁĄŹ BAZA (tu stoimy podczas merge = Current)
# ==========================================
git checkout -B $baseBranch $startCommit 2>$null

$tmdlBase = $tmdlOryginal
$tmdlBase = Set-Once $tmdlBase $consistencyOld '_Consistent && NOT ( _Falling ), "✅ Stable growth (BAZA)"'
$tmdlBase = Set-Once $tmdlBase $repsHeaderOld 'VAR _Header = "Best Sellers of the Month"'
$tmdlBase = Set-Once $tmdlBase $productSubtitleOld 'VAR _Subtitle = "Top brands by revenue"'
Write-Text $tmdlPath $tmdlBase

$visBase = $visOryginal.Replace('2.11.0/schema.json', '2.12.0/schema.json')
$markerBase = @'
$1,
            "markerColor": {
              "solid": {
                "color": {
                  "expr": {
                    "Literal": {
                      "Value": "'#E94560'"
                    }
                  }
                }
              }
            },
            "markerShape": {
              "expr": {
                "Literal": {
                  "Value": "'diamond'"
                }
              }
            }
'@
$visBase = [regex]::Replace($visBase, $markerAnchor, $markerBase.Replace("`r`n", "`n"))
Write-Text $visOldPath $visBase

$readmeBase = @"
# ⚔️ KOMPENDIUM: ROZWIĄZYWANIE KONFLIKTÓW (GIT W POWER BI) ⚔️

Podczas łączenia gałęzi (merge), Git czasami nie wie, którą wersję pliku zachować. 
Wtedy do akcji wkraczasz Ty! Poniżej znajdziesz najważniejsze zasady z warsztatów:

🟢 **ACCEPT CURRENT CHANGE (Akceptuj bieżącą zmianę)**
* **Czym to jest:** Zmiana z gałęzi docelowej – czyli tej, na której AKTUALNIE stoisz (w tym ćwiczeniu: 'baza_MJ').
* **Terminologia Git:** W dokumentacji oznaczane jako 'Ours' (Nasze).
* **Kiedy używać:** Gdy wiesz, że Twój lokalny kod jest poprawny i nie chcesz pozwolić, by cokolwiek z zewnątrz go nadpisało.

🛑 **KOŁO RATUNKOWE 1: PRZERWANIE MERGE'A**
Wybuchło 50 plików na czerwono? Zmiany są przerażające i wolisz zapytać kogoś o pomoc?
* Wpisz w terminalu: 'git merge --abort'
* Twój projekt zostanie natychmiast, całkowicie i bezpiecznie przywrócony do stanu sprzed wpisania komendy merge. Możesz odetchnąć.

😱 **KOŁO RATUNKOWE 2: UWIĘZIENI W TERMINALU (EDYTOR VIM)**
Zrobiłeś commita bez podania nazwy, terminal nagle zrobił się na pełen ekran, ma dziwne tyldy '~' i nic nie możesz kliknąć? Przypadkiem wywołałeś linuksowy edytor VIM!
* Aby zapisać i wyjść: Wciśnij klawisz 'Esc', wpisz na klawiaturze ':wq' i kliknij Enter.
* Aby wyjść awaryjnie bez zapisu: Wciśnij klawisz 'Esc', wpisz ':q!' i kliknij Enter.
"@
Write-Text "README.md" $readmeBase

git add .
git commit -m "BAZA: Stable growth, Best Sellers of the Month, nowy podtytuł produktów, czerwony diament" --quiet

# ==========================================
# 5. WYWOŁANIE KONFLIKTU
# ==========================================
Write-Host ""
Write-Host "Stoisz na gałęzi '$baseBranch' (Current) i wciągasz '$devBranch' (Incoming)..." -ForegroundColor Cyan
git merge $devBranch

Write-Host ""
Write-Host "Co sprawdzić w panelu Source Control -> Merge Changes:" -ForegroundColor Yellow
Write-Host "  _Global Measures.tmdl  2 konflikty: etykieta w 'HTML_KPI_Card_Dynamic' oraz nagłówek 'Reps Headaer'"
Write-Host "  visual.json            2 bloki jednego konfliktu: kolor markera i kształt markera (oba rozstrzygnij tak samo!)"
Write-Host "  README.md              1 konflikt: dwie połówki ściągi"
Write-Host "Git scalił sam: 3 nowe KPI, nagłówek 'Sales Shares' (tylko DEV), podtytuł 'Product Shares' (tylko BAZA)." -ForegroundColor Green
Write-Host "Coś poszło nie tak? git merge --abort  i uruchom skrypt jeszcze raz." -ForegroundColor DarkGray

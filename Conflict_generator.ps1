$i = Read-Host "Podaj swoje inicjaly"
$devBranch = "dev_$i"
$baseBranch = "baza_$i"

# 1. ZABEZPIECZENIE ORYGINAŁÓW (Wspólny przodek)
$tmdlPath = "Git Conflict.SemanticModel\definition\tables\_Global Measures.tmdl"
$visOldPath = "Git Conflict.Report\definition\pages\7a1007e13b28c6d51010\visuals\ff390bfdbc0aea10ab08\visual.json"
$tmdlOryginal = Get-Content $tmdlPath -Raw -Encoding UTF8
$visOryginal = Get-Content $visOldPath -Raw -Encoding UTF8

$regexTmdl1 = '(?<=_Consistent && NOT \( _Falling \), )".*?"'
$regexTmdl2 = '(?<=VAR _Header = )".*?"'
$regexSVG = "<svg xmlns='http://www.w3.org/2000/svg'.*?</svg>"
$noweSVG = "<svg xmlns='http://www.w3.org/2000/svg' width='24' height='24' viewBox='0 0 24 24' fill='none' stroke='currentColor' stroke-width='2' stroke-linecap='round' stroke-linejoin='round' class='lucide lucide-align-end-horizontal-icon lucide-align-end-horizontal'><rect width='6' height='16' x='4' y='2' rx='2'/><rect width='6' height='9' x='14' y='9' rx='2'/><path d='M22 22H2'/></svg>"

# ==========================================
# 2. GAŁĄŹ DEV (Nowe KPI, OMG test, ColorId 7)
# ==========================================
git checkout -b $devBranch 2>$null

$tmdlDev = $tmdlOryginal -replace $regexTmdl1, '"OMG test ✔"'
$tmdlDev = $tmdlDev -replace $regexTmdl2, '"GIT Conflict Test"'
$tmdlDev = $tmdlDev -replace $regexSVG, $noweSVG
Set-Content -Path $tmdlPath -Value $tmdlDev -Encoding UTF8

$visDev = $visOryginal.Replace('2.11.0/schema.json', '2.12.0/schema.json')
$markerDevPayload = '$1, "markerColor": { "solid": { "color": { "expr": { "ThemeDataColor": { "ColorId": 7, "Percent": 0.2 } } } } }'
$visDev = $visDev -replace '(?s)("markerSize":\s*\{\s*"expr":\s*\{\s*"Literal":\s*\{\s*"Value":\s*"7D"\s*\}\s*\}\s*\})', $markerDevPayload
Set-Content -Path $visOldPath -Value $visDev -Encoding UTF8

$readmeDev = @"
# ⚔️ KOMPENDIUM: ROZWIĄZYWANIE KONFLIKTÓW (GIT W POWER BI) ⚔️

Podczas łączenia gałęzi (merge), Git czasami nie wie, którą wersję pliku zachować. 
Wtedy do akcji wkraczasz Ty! Poniżej znajdziesz najważniejsze zasady z warsztatów:

🔵 **ACCEPT INCOMING CHANGE (Akceptuj przychodzącą zmianę)**
* **Czym to jest:** Zmiana pochodząca z gałęzi, którą właśnie wciągasz (np. gdy wpisujesz 'git merge baza_MJ', to jest to zawartość 'baza_MJ').
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
Set-Content -Path "README.md" -Value $readmeDev -Encoding UTF8

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

Set-Content -Path "$vis1Path\visual.json" -Value $json1 -Encoding utf8
Set-Content -Path "$vis2Path\visual.json" -Value $json2 -Encoding utf8
Set-Content -Path "$vis3Path\visual.json" -Value $json3 -Encoding utf8

git add .
git commit -m "Dev: Dodano 3 KPI, OMG test oraz marker ColorId 7"

# ==========================================
# 3. GAŁĄŹ BAZA (Diament, Hex #07B189, Net Sales)
# ==========================================
git checkout - 2>$null 
git checkout -b $baseBranch 2>$null

$tmdlBase = $tmdlOryginal -replace $regexTmdl1, '"Heck yeah, consistency ✔"'
$tmdlBase = $tmdlBase -replace $regexTmdl2, '"Net Sales Updated"'
$tmdlBase = $tmdlBase -replace $regexSVG, $noweSVG
Set-Content -Path $tmdlPath -Value $tmdlBase -Encoding UTF8

$visBase = $visOryginal.Replace('2.11.0/schema.json', '2.12.0/schema.json')
$markerBasePayload = '$1, "markerColor": { "solid": { "color": { "expr": { "Literal": { "Value": "''#07B189''" } } } } }, "markerShape": { "expr": { "Literal": { "Value": "''diamond''" } } }'
$visBase = $visBase -replace '(?s)("markerSize":\s*\{\s*"expr":\s*\{\s*"Literal":\s*\{\s*"Value":\s*"7D"\s*\}\s*\}\s*\})', $markerBasePayload
Set-Content -Path $visOldPath -Value $visBase -Encoding UTF8

$readmeBase = @"
# ⚔️ KOMPENDIUM: ROZWIĄZYWANIE KONFLIKTÓW (GIT W POWER BI) ⚔️

Podczas łączenia gałęzi (merge), Git czasami nie wie, którą wersję pliku zachować. 
Wtedy do akcji wkraczasz Ty! Poniżej znajdziesz najważniejsze zasady z warsztatów:

🟢 **ACCEPT CURRENT CHANGE (Akceptuj bieżącą zmianę)**
* **Czym to jest:** Zmiana z gałęzi docelowej – czyli tej, na której AKTUALNIE stoisz (np. Twoja gałąź 'dev_MJ' / 'baza_MJ').
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
Set-Content -Path "README.md" -Value $readmeBase -Encoding UTF8

git add .
git commit -m "Baza: Heck yeah, zielony Hex, Diament oraz ratunek w VIM"

# ==========================================
# 4. WYWOŁANIE KONFLIKTU
# ==========================================
git merge $devBranch
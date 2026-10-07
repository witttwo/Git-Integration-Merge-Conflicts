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
#   MIARY (.tmdl), 3 konflikty:
#     1. 'HTML_KPI_Card_Dynamic' (etykieta)  -> Accept Current
#     2. 'Reps Headaer' (nagłówek)           -> ręczna edycja (własny tekst); na DEV 2 commity (Claude + uczestnik)
#     3. 'Sales Shares' (nagłówek)           -> Accept Incoming
#   WIZUAL (visual.json): kolor + kształt markera -> Accept Incoming
#   README.md                                     -> Accept Both
#   BEZ KONFLIKTU: podtytuł 'Product Shares' zmienia tylko BAZA -> Git scala sam
$consistencyOld = '_Consistent && NOT ( _Falling ), "High sales consistency ✔"'
$repsHeaderOld = 'VAR _Header = "Sales Reps"'
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

# Zmiana "po cichu" na DEV: osobny, wcześniejszy commit innego autora (Claude) w tej samej linii.
# Po merge'u Line History nagłówka 'Reps Headaer' ma więcej kroków, a Search Commits po autorze coś znajduje.
$tmdlDev0 = Set-Once $tmdlOryginal $repsHeaderOld 'VAR _Header = "Sales Team"'
Write-Text $tmdlPath $tmdlDev0
git -c core.safecrlf=false add .
git -c user.name="Claude" -c user.email="noreply@anthropic.com" commit -m "DEV: krótszy nagłówek rankingu (Sales Team)" --quiet

$tmdlDev = $tmdlDev0
$tmdlDev = Set-Once $tmdlDev $consistencyOld '_Consistent && NOT ( _Falling ), "Rock-solid sales ✔"'
$tmdlDev = Set-Once $tmdlDev 'VAR _Header = "Sales Team"' 'VAR _Header = "Sales Team Leaderboard"'
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

$readmeDev = @'
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
'@
Write-Text "README.md" $readmeDev

$vis1Path = "Git Conflict.Report\definition\pages\7a1007e13b28c6d51010\visuals\bd321ca30d8572eac95e"
$vis2Path = "Git Conflict.Report\definition\pages\7a1007e13b28c6d51010\visuals\632c3c5cf00bcacde04d"
$vis3Path = "Git Conflict.Report\definition\pages\7a1007e13b28c6d51010\visuals\093aef5b47cf7c8c4607"
New-Item -Path $vis1Path -ItemType Directory -Force | Out-Null
New-Item -Path $vis2Path -ItemType Directory -Force | Out-Null
New-Item -Path $vis3Path -ItemType Directory -Force | Out-Null

$json1 = @'
{
  "$schema": "https://developer.microsoft.com/json-schemas/fabric/item/report/definition/visualContainer/2.12.0/schema.json",
  "name": "bd321ca30d8572eac95e",
  "position": {
    "x": 852.99,
    "y": 64.66,
    "z": 20001,
    "height": 158.75,
    "width": 290,
    "tabOrder": 20001
  },
  "visual": {
    "visualType": "image",
    "objects": {
      "image": [
        {
          "properties": {
            "sourceType": {
              "expr": {
                "Literal": {
                  "Value": "'imageData'"
                }
              }
            },
            "sourceField": {
              "expr": {
                "Measure": {
                  "Expression": {
                    "SourceRef": {
                      "Entity": "_Global Measures"
                    }
                  },
                  "Property": "KPI Card Orders IMG"
                }
              }
            }
          }
        }
      ]
    },
    "visualContainerObjects": {
      "dropShadow": [
        {
          "properties": {
            "show": {
              "expr": {
                "Literal": {
                  "Value": "true"
                }
              }
            },
            "color": {
              "solid": {
                "color": {
                  "expr": {
                    "ThemeDataColor": {
                      "ColorId": 0,
                      "Percent": -0.1
                    }
                  }
                }
              }
            }
          }
        }
      ],
      "border": [
        {
          "properties": {
            "show": {
              "expr": {
                "Literal": {
                  "Value": "true"
                }
              }
            },
            "color": {
              "solid": {
                "color": {
                  "expr": {
                    "ThemeDataColor": {
                      "ColorId": 0,
                      "Percent": -0.1
                    }
                  }
                }
              }
            },
            "radius": {
              "expr": {
                "Literal": {
                  "Value": "20D"
                }
              }
            }
          }
        }
      ],
      "background": [
        {
          "properties": {
            "show": {
              "expr": {
                "Literal": {
                  "Value": "true"
                }
              }
            },
            "transparency": {
              "expr": {
                "Literal": {
                  "Value": "0D"
                }
              }
            }
          }
        }
      ]
    },
    "drillFilterOtherVisuals": true
  }
}
'@
$json2 = @'
{
  "$schema": "https://developer.microsoft.com/json-schemas/fabric/item/report/definition/visualContainer/2.12.0/schema.json",
  "name": "632c3c5cf00bcacde04d",
  "position": {
    "x": 543.75,
    "y": 66.25,
    "z": 20002,
    "height": 157.5,
    "width": 290,
    "tabOrder": 20002
  },
  "visual": {
    "visualType": "image",
    "objects": {
      "image": [
        {
          "properties": {
            "sourceType": {
              "expr": {
                "Literal": {
                  "Value": "'imageData'"
                }
              }
            },
            "sourceField": {
              "expr": {
                "Measure": {
                  "Expression": {
                    "SourceRef": {
                      "Entity": "_Global Measures"
                    }
                  },
                  "Property": "KPI Card Quota IMG"
                }
              }
            }
          }
        }
      ]
    },
    "visualContainerObjects": {
      "dropShadow": [
        {
          "properties": {
            "show": {
              "expr": {
                "Literal": {
                  "Value": "true"
                }
              }
            },
            "color": {
              "solid": {
                "color": {
                  "expr": {
                    "ThemeDataColor": {
                      "ColorId": 0,
                      "Percent": -0.1
                    }
                  }
                }
              }
            },
            "transparency": {
              "expr": {
                "Literal": {
                  "Value": "35D"
                }
              }
            },
            "shadowBlur": {
              "expr": {
                "Literal": {
                  "Value": "15D"
                }
              }
            }
          }
        }
      ],
      "border": [
        {
          "properties": {
            "show": {
              "expr": {
                "Literal": {
                  "Value": "true"
                }
              }
            },
            "color": {
              "solid": {
                "color": {
                  "expr": {
                    "ThemeDataColor": {
                      "ColorId": 0,
                      "Percent": -0.1
                    }
                  }
                }
              }
            },
            "radius": {
              "expr": {
                "Literal": {
                  "Value": "20D"
                }
              }
            },
            "width": {
              "expr": {
                "Literal": {
                  "Value": "1D"
                }
              }
            }
          }
        }
      ],
      "background": [
        {
          "properties": {
            "show": {
              "expr": {
                "Literal": {
                  "Value": "true"
                }
              }
            },
            "color": {
              "solid": {
                "color": {
                  "expr": {
                    "ThemeDataColor": {
                      "ColorId": 0,
                      "Percent": 0
                    }
                  }
                }
              }
            },
            "transparency": {
              "expr": {
                "Literal": {
                  "Value": "0D"
                }
              }
            }
          }
        }
      ],
      "title": [
        {
          "properties": {
            "show": {
              "expr": {
                "Literal": {
                  "Value": "false"
                }
              }
            },
            "titleWrap": {
              "expr": {
                "Literal": {
                  "Value": "true"
                }
              }
            },
            "fontColor": {
              "solid": {
                "color": {
                  "expr": {
                    "Literal": {
                      "Value": "'#0F3460'"
                    }
                  }
                }
              }
            },
            "fontSize": {
              "expr": {
                "Literal": {
                  "Value": "'14'"
                }
              }
            },
            "fontFamily": {
              "expr": {
                "Literal": {
                  "Value": "'Arial'"
                }
              }
            }
          }
        }
      ],
      "spacing": [
        {
          "properties": {
            "verticalSpacing": {
              "expr": {
                "Literal": {
                  "Value": "2D"
                }
              }
            }
          },
          "selector": {
            "id": "default"
          }
        }
      ],
      "padding": [
        {
          "properties": {
            "top": {
              "expr": {
                "Literal": {
                  "Value": "5D"
                }
              }
            },
            "bottom": {
              "expr": {
                "Literal": {
                  "Value": "0D"
                }
              }
            },
            "left": {
              "expr": {
                "Literal": {
                  "Value": "0D"
                }
              }
            },
            "right": {
              "expr": {
                "Literal": {
                  "Value": "0D"
                }
              }
            }
          }
        }
      ]
    },
    "drillFilterOtherVisuals": true
  }
}
'@
$json3 = @'
{
  "$schema": "https://developer.microsoft.com/json-schemas/fabric/item/report/definition/visualContainer/2.12.0/schema.json",
  "name": "093aef5b47cf7c8c4607",
  "position": {
    "x": 236.66,
    "y": 64.44,
    "z": 20003,
    "height": 158.88,
    "width": 290,
    "tabOrder": 20003
  },
  "visual": {
    "visualType": "image",
    "objects": {
      "image": [
        {
          "properties": {
            "sourceType": {
              "expr": {
                "Literal": {
                  "Value": "'imageData'"
                }
              }
            },
            "sourceField": {
              "expr": {
                "Measure": {
                  "Expression": {
                    "SourceRef": {
                      "Entity": "_Global Measures"
                    }
                  },
                  "Property": "KPI Card Net Sales IMG"
                }
              }
            }
          }
        }
      ]
    },
    "visualContainerObjects": {
      "dropShadow": [
        {
          "properties": {
            "show": {
              "expr": {
                "Literal": {
                  "Value": "true"
                }
              }
            },
            "color": {
              "solid": {
                "color": {
                  "expr": {
                    "ThemeDataColor": {
                      "ColorId": 0,
                      "Percent": -0.1
                    }
                  }
                }
              }
            },
            "transparency": {
              "expr": {
                "Literal": {
                  "Value": "35D"
                }
              }
            },
            "shadowBlur": {
              "expr": {
                "Literal": {
                  "Value": "15D"
                }
              }
            }
          }
        }
      ],
      "border": [
        {
          "properties": {
            "show": {
              "expr": {
                "Literal": {
                  "Value": "true"
                }
              }
            },
            "color": {
              "solid": {
                "color": {
                  "expr": {
                    "Literal": {
                      "Value": "'#006084'"
                    }
                  }
                }
              }
            },
            "radius": {
              "expr": {
                "Literal": {
                  "Value": "20D"
                }
              }
            },
            "width": {
              "expr": {
                "Literal": {
                  "Value": "1D"
                }
              }
            }
          }
        }
      ],
      "background": [
        {
          "properties": {
            "show": {
              "expr": {
                "Literal": {
                  "Value": "true"
                }
              }
            },
            "color": {
              "solid": {
                "color": {
                  "expr": {
                    "Literal": {
                      "Value": "'#006084'"
                    }
                  }
                }
              }
            },
            "transparency": {
              "expr": {
                "Literal": {
                  "Value": "0D"
                }
              }
            }
          }
        }
      ],
      "title": [
        {
          "properties": {
            "show": {
              "expr": {
                "Literal": {
                  "Value": "false"
                }
              }
            },
            "titleWrap": {
              "expr": {
                "Literal": {
                  "Value": "true"
                }
              }
            },
            "fontColor": {
              "solid": {
                "color": {
                  "expr": {
                    "Literal": {
                      "Value": "'#0F3460'"
                    }
                  }
                }
              }
            },
            "fontSize": {
              "expr": {
                "Literal": {
                  "Value": "'14'"
                }
              }
            },
            "fontFamily": {
              "expr": {
                "Literal": {
                  "Value": "'Arial'"
                }
              }
            }
          }
        }
      ],
      "spacing": [
        {
          "properties": {
            "verticalSpacing": {
              "expr": {
                "Literal": {
                  "Value": "2D"
                }
              }
            }
          },
          "selector": {
            "id": "default"
          }
        }
      ],
      "padding": [
        {
          "properties": {
            "top": {
              "expr": {
                "Literal": {
                  "Value": "5D"
                }
              }
            },
            "bottom": {
              "expr": {
                "Literal": {
                  "Value": "0D"
                }
              }
            },
            "left": {
              "expr": {
                "Literal": {
                  "Value": "0D"
                }
              }
            },
            "right": {
              "expr": {
                "Literal": {
                  "Value": "0D"
                }
              }
            }
          }
        }
      ]
    },
    "drillFilterOtherVisuals": true
  }
}
'@

Write-Text "$vis1Path\visual.json" $json1.Replace("`r`n", "`n")
Write-Text "$vis2Path\visual.json" $json2.Replace("`r`n", "`n")
Write-Text "$vis3Path\visual.json" $json3.Replace("`r`n", "`n")

git -c core.safecrlf=false add .
git commit -m "DEV: 3 nowe KPI, Rock-solid sales, Sales Team Leaderboard, Territory Pareto 80/20, marker ColorId 7" --quiet

# ==========================================
# 4. GAŁĄŹ BAZA (tu stoimy podczas merge = Current)
# ==========================================
git checkout -B $baseBranch $startCommit 2>$null

$tmdlBase = $tmdlOryginal
$tmdlBase = Set-Once $tmdlBase $consistencyOld '_Consistent && NOT ( _Falling ), "Stable growth ✔"'
$tmdlBase = Set-Once $tmdlBase $repsHeaderOld 'VAR _Header = "Best Sellers of the Month"'
$tmdlBase = Set-Once $tmdlBase $salesShareHeaderOld 'VAR _Header = "Sales by Territory"'
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

$readmeBase = @'
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
'@
Write-Text "README.md" $readmeBase

git -c core.safecrlf=false add .
git commit -m "BAZA: Stable growth, Best Sellers of the Month, Sales by Territory, nowy podtytuł produktów, czerwony diament" --quiet

# ==========================================
# 5. WYWOŁANIE KONFLIKTU
# ==========================================
Write-Host ""
Write-Host "Stoisz na gałęzi '$baseBranch' (Current) i wciągasz '$devBranch' (Incoming)..." -ForegroundColor Cyan
git merge $devBranch

Write-Host ""
Write-Host "Co sprawdzić w panelu Source Control -> Merge Changes:" -ForegroundColor Yellow
Write-Host "  _Global Measures.tmdl  3 konflikty: 'HTML_KPI_Card_Dynamic', 'Reps Headaer', 'Sales Shares'"
Write-Host "  visual.json            kolor i kształt markera (2 bloki - rozstrzygnij oba tak samo)"
Write-Host "  README.md              dwie połówki ściągi"
Write-Host "Git scalił sam: 3 nowe KPI oraz podtytuł 'Product Shares' (zmieniony tylko w BAZIE)." -ForegroundColor Green
Write-Host "Coś poszło nie tak? git merge --abort  i uruchom skrypt jeszcze raz." -ForegroundColor DarkGray

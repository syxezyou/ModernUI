# ModernUI

> **Le RageUI nouvelle génération pour FiveM.**
> Même logique que RageUI, rendu NUI moderne en noir & gris, plus fluide et plus léger.

![FiveM](https://img.shields.io/badge/FiveM-Ready-black)
![Lua 5.4](https://img.shields.io/badge/Lua-5.4-808080)
![License](https://img.shields.io/badge/License-Free-333333)

---

## Présentation

**ModernUI** est une bibliothèque de menus pour FiveM qui reprend l'API de **RageUI** (`CreateMenu`, `SubMenu`, `Button`, `Checkbox`, `List`, `Slider`...) mais remplace le rendu par des textures GTA par une interface **NUI (HTML/CSS/JS)** moderne.

Si tu sais utiliser RageUI, tu sais déjà utiliser ModernUI.

---

## Pourquoi ModernUI plutôt que RageUI ?

| | RageUI | ModernUI |
|---|---|---|
| Rendu | Sprites/textes GTA dessinés chaque frame | NUI HTML/CSS |
| Design | Style GTA fixe | Noir & gris moderne, personnalisable via CSS |
| Performance | Dessin à chaque frame (`Wait(0)` lourd) | Message NUI **uniquement si le contenu change** |
| Animations | Aucune | Transitions fluides, scroll, survol |
| Personnalisation | Limitée (textures) | Variables CSS (couleurs, rayon, police) |
| Contrôles | Clavier / manette | Clavier / manette (identique) |
| Maintenance | Projet ancien | Code simple et modulaire |

---

## Fonctionnalités

- Menus et sous-menus avec navigation retour automatique
- Éléments : **Button, Checkbox, List, Slider, Separator**
- Descriptions contextuelles par élément
- Scroll automatique avec indicateurs ▲ ▼
- Compteur d'éléments (`3 / 12`)
- Répétition en maintenant les flèches
- Sons du menu (désactivables)
- Position, largeur et nombre d'éléments visibles configurables
- Compatible **ESX Legacy, QBCore et standalone**
- Aucune dépendance externe

---

## Installation

1. Place le dossier `modern_ui` dans ton dossier `resources/`.
2. Ajoute dans ton `server.cfg` :

```cfg
ensure modern_ui
```

3. Redémarre le serveur, puis teste la démo en jeu avec :

```
/modernui
```

---

## Utilisation dans ta ressource

**fxmanifest.lua**

```lua
dependency 'modern_ui'

client_scripts {
    '@modern_ui/client/main.lua',
    'client/menu.lua'
}
```

**client/menu.lua**

```lua
local main = ModernUI.CreateMenu('Mon Menu', 'Sous-titre')
local sub  = ModernUI.CreateSubMenu(main, 'Options', 'Réglages')

RegisterCommand('monmenu', function()
    ModernUI.Visible(main, not ModernUI.Visible(main))
end)

CreateThread(function()
    while true do
        Wait(0)
        ModernUI.Render(main, function()
            ModernUI.Button('Action', 'Description', function(selected)
                if selected then print('Cliqué !') end
            end)
        end)
    end
end)
```

---

## API

| Fonction | Description |
|---|---|
| `ModernUI.CreateMenu(titre, sous_titre)` | Crée un menu principal |
| `ModernUI.CreateSubMenu(parent, titre, sous_titre)` | Crée un sous-menu lié |
| `ModernUI.Visible(menu, bool)` | Ouvre/ferme ou lit l'état du menu |
| `ModernUI.Render(menu, cb)` | Affiche le menu et exécute les éléments |
| `ModernUI.Button(label, desc, cb)` | Bouton |
| `ModernUI.Checkbox(label, desc, état, cb)` | Case à cocher |
| `ModernUI.List(label, items, index, desc, cb)` | Liste à choix |
| `ModernUI.Slider(label, min, max, valeur, desc, cb)` | Curseur |
| `ModernUI.Separator(label)` | Séparateur visuel |

---

## Contrôles

| Action | Clavier | Manette |
|---|---|---|
| Monter / Descendre | ↑ / ↓ | D-Pad haut / bas |
| Modifier (liste, slider) | ← / → | D-Pad gauche / droite |
| Valider | Entrée | A |
| Retour / Fermer | Retour arrière | B |

---

## Configuration

Dans `client/main.lua` :

```lua
ModernUI.Settings = {
    Position    = { x = 2.0, y = 2.0 }, -- % de l'écran
    Width       = 420,                  -- px
    MaxItems    = 10,                   -- éléments visibles
    Sounds      = true,
    RepeatDelay = 250,
    RepeatRate  = 90,
}
```

---

## Personnalisation du thème

Dans `html/style.css`, modifie les variables `:root` :

```css
:root {
    --accent: #9a9a9a;
    --bg: #0d0d0d;
    --radius: 6px;
}
```

---

## Structure

```
modern_ui/
├── fxmanifest.lua
├── client/
│   ├── host.lua       # Pont NUI (export)
│   ├── main.lua       # Librairie
│   └── example.lua    # Démo /modernui
└── html/
    ├── index.html
    ├── style.css
    └── script.js
```

---

## Compatibilité

- ESX Legacy, QBCore, standalone
- Lua 5.4
- Dernières versions de FiveM

---

## Migration depuis RageUI

Remplace simplement les appels :

| RageUI | ModernUI |
|---|---|
| `RageUI.CreateMenu` | `ModernUI.CreateMenu` |
| `RageUI.CreateSubMenu` | `ModernUI.CreateSubMenu` |
| `RageUI.Visible` | `ModernUI.Visible` |
| `RageUI.IsVisible` | `ModernUI.Render` |
| `RageUI.Button` | `ModernUI.Button` |
| `RageUI.Checkbox` | `ModernUI.Checkbox` |
| `RageUI.List` | `ModernUI.List` |

---

## Licence

Libre d'utilisation et de modification. Merci de conserver les crédits.

## Support

Ouvre une issue ou contacte l'auteur avec ton message d'erreur console (F8) pour toute demande.

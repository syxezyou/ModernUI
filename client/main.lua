ModernUI = {}
ModernUI.CurrentMenu = nil
ModernUI.Settings = {
    Position     = { x = 2.0, y = 2.0 }, -- en % de l'écran
    Width        = 420,                  -- px
    MaxItems     = 10,                   -- items visibles avant scroll
    Sounds       = true,
    RepeatDelay  = 250,                  -- ms avant répétition (maintien)
    RepeatRate   = 90,                   -- ms entre répétitions
}

local HOST = 'modern_ui'
local Controls = {
    Up     = 172, -- Flèche haut / D-Pad up
    Down   = 173,
    Left   = 174,
    Right  = 175,
    Select = 191, -- Entrée / A
    Back   = 194, -- Retour / B
}

local lastPayload = ''
local holdTimers = {}

-------------------------------------------------------------------------------
-- Utilitaires
-------------------------------------------------------------------------------
local function Sound(name)
    if not ModernUI.Settings.Sounds then return end
    PlaySoundFrontend(-1, name, 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)
end

local function Send(payload)
    exports[HOST]:Send(payload)
end

-- Gestion appui simple + répétition en maintien
local function Pressed(control)
    DisableControlAction(0, control, true)
    local now = GetGameTimer()
    if IsDisabledControlJustPressed(0, control) then
        holdTimers[control] = now + ModernUI.Settings.RepeatDelay
        return true
    end
    if IsDisabledControlPressed(0, control) and holdTimers[control] and now >= holdTimers[control] then
        holdTimers[control] = now + ModernUI.Settings.RepeatRate
        return true
    end
    if not IsDisabledControlPressed(0, control) then
        holdTimers[control] = nil
    end
    return false
end

local function IsSelectable(item)
    return item and item.type ~= 'separator' and not item.disabled
end

local function MoveIndex(menu, dir)
    local count = menu.Count
    if count == 0 then return end
    local idx = menu.Index
    for _ = 1, count do
        idx = idx + dir
        if idx < 1 then idx = count end
        if idx > count then idx = 1 end
        if IsSelectable(menu.Items[idx]) then
            menu.Index = idx
            Sound('NAV_UP_DOWN')
            return
        end
    end
end

-------------------------------------------------------------------------------
-- Menus
-------------------------------------------------------------------------------
function ModernUI.CreateMenu(title, subtitle, options)
    options = options or {}
    return {
        Title    = title or 'Menu',
        Subtitle = subtitle or '',
        Index    = 1,
        Items    = {},
        Count    = 0,
        Parent   = nil,
        Open     = false,
        OnClose  = options.OnClose,
        Glare    = options.Glare ~= false,
        _Pressed = {},
    }
end

function ModernUI.CreateSubMenu(parent, title, subtitle, options)
    local m = ModernUI.CreateMenu(title or parent.Title, subtitle, options)
    m.Parent = parent
    return m
end

function ModernUI.Visible(menu, state)
    if state == nil then return ModernUI.CurrentMenu == menu end
    if state then
        if ModernUI.CurrentMenu and ModernUI.CurrentMenu ~= menu then
            ModernUI.CurrentMenu.Open = false
        end
        menu.Open = true
        ModernUI.CurrentMenu = menu
        lastPayload = ''
    else
        menu.Open = false
        if ModernUI.CurrentMenu == menu then
            ModernUI.CurrentMenu = nil
            Send({ action = 'hide' })
            lastPayload = ''
            if menu.OnClose then menu.OnClose() end
        end
    end
end

function ModernUI.IsVisible(menu)
    return ModernUI.CurrentMenu == menu
end

function ModernUI.IsAnyOpen()
    return ModernUI.CurrentMenu ~= nil
end

function ModernUI.CloseAll()
    if ModernUI.CurrentMenu then
        ModernUI.Visible(ModernUI.CurrentMenu, false)
    end
end

function ModernUI.GoBack(menu)
    Sound('BACK')
    if menu.Parent then
        ModernUI.Visible(menu, false)
        ModernUI.Visible(menu.Parent, true)
    else
        ModernUI.Visible(menu, false)
    end
end

-------------------------------------------------------------------------------
-- Rendu (à appeler chaque frame comme RageUI.IsVisible)
-------------------------------------------------------------------------------
function ModernUI.Render(menu, fn)
    if ModernUI.CurrentMenu ~= menu then return end

    menu.Items = {}
    menu.Count = 0
    menu._Pressed = {
        Up     = Pressed(Controls.Up),
        Down   = Pressed(Controls.Down),
        Left   = Pressed(Controls.Left),
        Right  = Pressed(Controls.Right),
        Select = Pressed(Controls.Select),
        Back   = Pressed(Controls.Back),
    }

    -- Désactive quelques contrôles gênants pendant le menu
    DisableControlAction(0, 27, true)  -- Phone
    DisableControlAction(0, 199, true) -- Pause
    DisableControlAction(0, 200, true)

    fn()

    -- Navigation (après déclaration des items pour connaître Count)
    if menu.Count > 0 then
        if menu.Index > menu.Count then menu.Index = menu.Count end
        if not IsSelectable(menu.Items[menu.Index]) then MoveIndex(menu, 1) end
        if menu._Pressed.Up then MoveIndex(menu, -1) end
        if menu._Pressed.Down then MoveIndex(menu, 1) end
    end

    if menu._Pressed.Back then
        ModernUI.GoBack(menu)
        return
    end

    -- Envoi NUI uniquement si changement
    local payload = {
        action   = 'show',
        title    = menu.Title,
        subtitle = menu.Subtitle,
        index    = menu.Index,
        items    = menu.Items,
        settings = ModernUI.Settings,
    }
    local encoded = json.encode(payload)
    if encoded ~= lastPayload then
        lastPayload = encoded
        Send(payload)
    end
end

-------------------------------------------------------------------------------
-- Items
-------------------------------------------------------------------------------
local function AddItem(menu, item)
    menu.Count = menu.Count + 1
    menu.Items[menu.Count] = item
    return menu.Count == menu.Index
end

-- ModernUI.Button(label, description, style, callback(onSelected, onHovered), submenu)
-- style: { RightLabel, RightBadge, Disabled, Color, Icon }
function ModernUI.Button(label, desc, style, callback, submenu)
    local menu = ModernUI.CurrentMenu
    if not menu then return end
    style = style or {}

    local hovered = AddItem(menu, {
        type     = 'button',
        label    = label,
        desc     = desc,
        right    = style.RightLabel,
        badge    = style.RightBadge,
        icon     = style.Icon,
        color    = style.Color,
        disabled = style.Disabled or false,
        arrow    = submenu ~= nil,
    })

    if hovered and not style.Disabled then
        local selected = menu._Pressed.Select
        if selected then Sound('SELECT') end
        if callback then callback(selected, hovered) end
        if selected and submenu then
            ModernUI.Visible(menu, false)
            ModernUI.Visible(submenu, true)
        end
    end
end

-- ModernUI.Checkbox(label, description, checked, style, callback(onSelected, newState))
function ModernUI.Checkbox(label, desc, checked, style, callback)
    local menu = ModernUI.CurrentMenu
    if not menu then return end
    style = style or {}

    local hovered = AddItem(menu, {
        type     = 'checkbox',
        label    = label,
        desc     = desc,
        checked  = checked and true or false,
        icon     = style.Icon,
        disabled = style.Disabled or false,
    })

    if hovered and not style.Disabled then
        local selected = menu._Pressed.Select
        local newState = checked
        if selected then
            newState = not checked
            Sound('SELECT')
        end
        if callback then callback(selected, newState) end
    end
end

-- ModernUI.List(label, items, index, description, style, callback(onSelected, onListChange, index))
function ModernUI.List(label, items, index, desc, style, callback)
    local menu = ModernUI.CurrentMenu
    if not menu then return end
    style = style or {}
    index = index or 1
    local total = #items

    local hovered = AddItem(menu, {
        type     = 'list',
        label    = label,
        desc     = desc,
        value    = tostring(items[index] or ''),
        icon     = style.Icon,
        disabled = style.Disabled or false,
    })

    if hovered and not style.Disabled and total > 0 then
        local changed = false
        if menu._Pressed.Left then
            index = index - 1
            if index < 1 then index = total end
            changed = true
        elseif menu._Pressed.Right then
            index = index + 1
            if index > total then index = 1 end
            changed = true
        end
        if changed then Sound('NAV_LEFT_RIGHT') end
        local selected = menu._Pressed.Select
        if selected then Sound('SELECT') end
        if callback then callback(selected, changed, index) end
    end
end

-- ModernUI.Slider(label, value, min, max, step, description, style, callback(onSelected, onChange, value))
function ModernUI.Slider(label, value, min, max, step, desc, style, callback)
    local menu = ModernUI.CurrentMenu
    if not menu then return end
    style = style or {}
    step = step or 1
    value = value or min

    local hovered = AddItem(menu, {
        type     = 'slider',
        label    = label,
        desc     = desc,
        value    = value,
        min      = min,
        max      = max,
        suffix   = style.Suffix,
        icon     = style.Icon,
        disabled = style.Disabled or false,
    })

    if hovered and not style.Disabled then
        local changed = false
        if menu._Pressed.Left and value > min then
            value = math.max(min, value - step); changed = true
        elseif menu._Pressed.Right and value < max then
            value = math.min(max, value + step); changed = true
        end
        if changed then Sound('NAV_LEFT_RIGHT') end
        local selected = menu._Pressed.Select
        if selected then Sound('SELECT') end
        if callback then callback(selected, changed, value) end
    end
end

-- ModernUI.Separator(label)
function ModernUI.Separator(label)
    local menu = ModernUI.CurrentMenu
    if not menu then return end
    AddItem(menu, { type = 'separator', label = label or '' })
end

-- ModernUI.Line() : simple ligne
function ModernUI.Line()
    ModernUI.Separator('')
end
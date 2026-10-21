local main    = ModernUI.CreateMenu('MODERN UI', 'Menu principal')
local vehSub  = ModernUI.CreateSubMenu(main, 'MODERN UI', 'Véhicule')
local setSub  = ModernUI.CreateSubMenu(main, 'MODERN UI', 'Paramètres')

local state = {
    godmode  = false,
    listIdx  = 1,
    cars     = { 'Adder', 'Zentorno', 'Sultan RS', 'Kuruma' },
    speed    = 50,
    volume   = 70,
}

RegisterCommand('modernui', function()
    ModernUI.Visible(main, not ModernUI.Visible(main))
end)
RegisterKeyMapping('modernui', 'Ouvrir ModernUI', 'keyboard', 'F7')

CreateThread(function()
    while true do
        Wait(0)
        if ModernUI.IsAnyOpen() then
            ModernUI.Render(main, function()
                ModernUI.Separator('— Général —')
                ModernUI.Button('Véhicules', 'Spawn et options de véhicules', { RightLabel = '' }, nil, vehSub)
                ModernUI.Button('Paramètres', 'Options du menu', nil, nil, setSub)
                ModernUI.Checkbox('Mode invincible', 'Active/désactive le godmode', state.godmode, nil, function(onSelected, checked)
                    if onSelected then
                        state.godmode = checked
                        SetEntityInvincible(PlayerPedId(), checked)
                    end
                end)
                ModernUI.Separator('— Actions —')
                ModernUI.Button('Soigner', 'Remet la vie au maximum', { RightBadge = 'HP', Color = '#4caf50' }, function(onSelected)
                    if onSelected then SetEntityHealth(PlayerPedId(), 200) end
                end)
                ModernUI.Button('Indisponible', 'Bouton désactivé', { Disabled = true })
                ModernUI.Button('Fermer', nil, { Color = '#e53935' }, function(onSelected)
                    if onSelected then ModernUI.Visible(main, false) end
                end)
            end)

            ModernUI.Render(vehSub, function()
                ModernUI.List('Modèle', state.cars, state.listIdx, 'Choisis un véhicule', nil, function(onSelected, onChange, idx)
                    state.listIdx = idx
                    if onSelected then
                        local model = joaat(state.cars[idx]:gsub(' ', ''))
                        RequestModel(model)
                        while not HasModelLoaded(model) do Wait(0) end
                        local ped = PlayerPedId()
                        local veh = CreateVehicle(model, GetEntityCoords(ped), GetEntityHeading(ped), true, false)
                        SetPedIntoVehicle(ped, veh, -1)
                        SetModelAsNoLongerNeeded(model)
                    end
                end)
                ModernUI.Slider('Vitesse max', state.speed, 0, 200, 5, 'Limiteur', { Suffix = ' km/h' }, function(_, onChange, v)
                    if onChange then state.speed = v end
                end)
                ModernUI.Button('Réparer', nil, nil, function(onSelected)
                    if onSelected then
                        local veh = GetVehiclePedIsIn(PlayerPedId(), false)
                        if veh ~= 0 then SetVehicleFixed(veh) end
                    end
                end)
            end)

            ModernUI.Render(setSub, function()
                ModernUI.Slider('Volume', state.volume, 0, 100, 10, nil, { Suffix = '%' }, function(_, onChange, v)
                    if onChange then state.volume = v end
                end)
                ModernUI.Checkbox('Sons du menu', nil, ModernUI.Settings.Sounds, nil, function(onSelected, checked)
                    if onSelected then ModernUI.Settings.Sounds = checked end
                end)
            end)
        end
    end
end)
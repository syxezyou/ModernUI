-- Pont vers la NUI. Les autres ressources passent par cet export.
exports('Send', function(payload)
    SendNUIMessage(payload)
end)

AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() then
        SendNUIMessage({ action = 'hide' })
    end
end)
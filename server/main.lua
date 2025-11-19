
AddEventHandler('playerConnecting', function(name, setKickReason, deferrals)

    local src = source

    -- Deferal the connection
    deferrals.defer()
    deferrals.update(string.format("Bonjour %s, nous verifions vos informations de connexion", name))

    Citizen.Wait(1000)

    -- Get player identifiers
    local identifiers = {}

    local numIds = GetNumPlayerIdentifiers(src)
    for i = 0, numIds - 1 do
        
        local id = GetPlayerIdentifier(src, i)
        
        if id:find("license:") == 1 then
            identifiers.license = id
        elseif id:find("discord:") == 1 then
            identifiers.discord = id
        elseif id:find("steam:") == 1 then
            identifiers.steam = id
        elseif id:find("fivem:") == 1 then
            identifiers.fivem = id
        elseif id:find("ip:") == 1 then
            identifiers.ip = id
        end
    end

    -- Generate missingLicence table
    local missingLicence = {}
    if not identifiers.license then table.insert(missingLicence, "FiveM") end
    if not identifiers.discord then table.insert(missingLicence, "Discord") end
    if not identifiers.steam then table.insert(missingLicence, "Steam") end

    -- Check if any identifiers are missing
    -- if identifiers missing deferrals.done with a message to kick the player
    if #missingLicence > 0 then
        local msg = "Connexion refusée : identifiants manquants : " .. table.concat(missingLicence, ", ")
        deferrals.done(msg)
        return
    end

    deferrals.done()

    -- VPN DETECTION

    if CS.VPN then

        local _ip = identifiers.ip:gsub("ip:", "")

        -- Check in database if IP is already checked
        local response = MySQL.query.await("SELECT statement FROM ips WHERE ips LIKE ?;", {
            _ip
        })
        
        local row = response[1]
        
        -- If not checked, we call the API
        if row == nil then
            PerformHttpRequest(string.format(CS.API[CS.Service], _ip), function(err, text, headers)
                local data = json.decode(text)
                print(json.encode(data))

                -- Check if IP is clean
                if data.security.proxy == false and
                    data.security.relay == false and
                    data.security.vpn == false and
                    data.security.tor == false then
                    
                    -- Allow connection and save IP as clean
                    deferrals.update("Connexion acceptée., connexion en cours...")
                    Citizen.Wait(2000)
                    deferrals.done()

                    MySQL.insert.await("INSERT INTO ips (ips, statement) VALUES (?, ?);", {
                        _ip,true
                    })
                
                -- Reject connection and save IP as not clean
                else
                    deferrals.done("Connexion refusée : Utilisation de VPN/Proxy détectée.")
                    MySQL.insert.await("INSERT INTO ips (ips, statement) VALUES (?, ?);", {
                        _ip,false
                    })
                end
            end)
        
        -- IP already checked in database
        else
            -- IP is clean
            if row.statement then
                deferrals.update("Connexion acceptée., connexion en cours...")
                Citizen.Wait(2000)
                deferrals.done()

            -- IP is not clean
            else
                deferrals.done("Connexion refusée : Utilisation de VPN/Proxy détectée.")
            end
        end
    end
end)
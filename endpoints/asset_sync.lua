--#ENDPOINT GET /asset/sync

-- Fetch the entire list of assets
-- This can be done periodically to sync the two systems
local asset_list = MyCustomService.assets()

for _, asset in ipairs(asset_list) do
--  local asset = MyCustomService.asset({["id"]=asset.id})
    local assetId = tostring(asset[1].id)

    local device = Device2.getIdentityState({identity = assetId})

    if device.error then
        if json.parse(device.error).code ~= 404 then
            return log.error(json.stringify(device))
        end
        local sha256 = require('sha256')
        local addResult = Device2.addIdentity({
            identity = assetId,
            auth = {
                key = string.sub(sha256(assetId),1,40),
                type = 'token'
            }
        })
        if not addResult.error then
            log.info('addIdentity', assetId)
        end
        device = Device2.getIdentityState({identity = assetId})
    end

    local config_io = json.parse((device.config_io or {}).set)
    if not config_io then
        config_io = require('config_io') or {}
        Device2.setIdentityState({
            identity = assetId,
            config_io = json.stringify(config_io)
        })
    end

    config_io.channels = config_io.channels or {}
end









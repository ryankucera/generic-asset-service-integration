--#ENDPOINT GET /asset/fetch

-- Fetch the entire list of assets
-- This can be done periodically to sync the two systems
local asset_list = MyCustomService.assets()


for _, asset in ipairs(asset_list) do
    local data = MyCustomService.assetState({["id"]=asset})

    -- Create a datapoint object that will be saved for the device
    local datapoint = {
        temperature = 1,
        vibration = 1,
        vbatt = 1
    }

    -- Loop through the data returned by the API
    -- Add the relevant values to the datapoint
    -- This is an opportunity to transform your data before storing it
    -- Simple and complex algorithms can be applied here, if needed
    for i, before in ipairs(data) do
        if before.FieldLabel == "Temperature" then
            datapoint.temperature = before.Value
        elseif before.FieldLabel == "Battery" then
            datapoint.vbatt = before.Value
        elseif before.FieldLabel == "Vibration" then
            datapoint.overall_vibration = before.Value
        end
    end

    -- Create a data object to save
    -- The `datapoint` object will be converted to json and stored in the data object
    local data = {}
    local timestamp = os.time()*1000000
    data.type = "data_in"
    data.updated_resources = {"data_in"}
    data.payload = {{timestamp = timestamp, values = {data_in = to_json(datapoint)}}}
    data.identity = assetId

    log.info(data)

    -- Notifies ExoSense to update
    Interface.trigger({event='event', data=data, mode='sync'})
endj
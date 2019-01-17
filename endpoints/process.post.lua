--#ENDPOINT POST /process
-- process

local args = request.body.args
local functionId = args.function_id

local dataOUT = insightModule[functionId](request.body)

return {dataOUT}
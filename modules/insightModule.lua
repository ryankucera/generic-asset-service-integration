insightModule = {}

local emptyList = {}
setmetatable(emptyList, {['__type']='slice'})

function insightModule.healthScore(body)
  local dataIN = body.data
  dataOUT = emptyList
  for _, dp in pairs(dataIN) do
    if dp.value >= 0.30 then
      healthScore = 0
    elseif dp.value >= 0.20 then
      healthScore = 10
    elseif dp.value >= 0.10 then
      healthScore = 30
    elseif dp.value >= 0.05 then
      healthScore = 50
    elseif dp.value >= 0.01 then
      healthScore = 80
    elseif dp.value >= 0.00 then
      healthScore = 100
    end

    dp.value = healthScore
    table.insert(dataOUT, dp)
  end
  
  return dataOUT
end

function insightModule.healthAction(body)
  local dataIN = body.data
  dataOUT = emptyList
  for _, dp in pairs(dataIN) do
    if dp.value <= 10 then
      -- TODO: Make this a real endpoint and alter the parameters to make sense
      -- TODO: This should actually order a replacement part for something
      -- local data = MyCustomService.orderPart({["id"]=dp.tags.pid})
      orderNumber = "010394AD12"
      dp.value = orderNumber
      table.insert(dataOUT, dp)
    end
  end
  
  return dataOUT
end
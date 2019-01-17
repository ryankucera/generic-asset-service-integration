--#ENDPOINT POST /insights
-- listInsights

local insightsByGroup = {}
local emptyList = {}
setmetatable(emptyList, {['__type']='slice'})

local healthScore = {
  id = "healthScore",
  name = "Generate Health Score",
  description = "Generate health score from input of vibration data",
  inlets = {
    {
      data_type = "ACCELERATION",
      data_unit = "METERS_PER_SEC2",
      description = "Vibration of asset"
    }
  },
  outlets = {
    data_type = "PERCENTAGE",
    data_unit = "PERCENT"
  }
}

local healthAction = {
  id = "healthAction",
  name = "Generate Health Action",
  description = "Generate health action from input of health score",
  inlets = {
    {
      data_type = "PERCENTAGE",
      data_unit = "PERCENT",
      description = "Health score percentage"
    }
  },
  outlets = {
    data_type = "STRING"
  }
}

functions = {healthScore, healthAction}

local count = table.getn(functions)
local total = table.getn(functions)

return {
  count = count,
  total = total,
  insights = functions
}
--#ENDPOINT POST /insights
-- listInsights

local insightsByGroup = {}
local emptyList = {}
setmetatable(emptyList, {['__type']='slice'})

local healthStatus = {
  id = "healthStatus",
  name = "Generate Health Status",
  description = "Generate health status from input of temperature data",
  constants = {
    {
      name = "threshold",
      type = "number"
    }
  },
  inlets = {
    {
      primitive_type = "NUMERIC",
      description = "Input Signal"
    }
  },
  outlets = {
    primitive_type = "NUMERIC"
  }
}

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

functions = {healthStatus, healthScore, healthAction}

local count = table.getn(functions)
local total = table.getn(functions)

return {
  count = count,
  total = total,
  insights = functions
}
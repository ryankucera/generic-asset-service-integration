return json.parse([[{
	"channels": {
		"temperature": {
			"display_name": "Temperature",
			"description": "Measured sensor temperature",
			"properties": {
				"data_type": "TEMPERATURE",
				"data_unit": "DEG_CELCIUS"
			},
			"protocol_config": {
				"report_rate": 60000
			}
		},
		"vibration": {
			"display_name": "Vibration",
			"description": "Vibration",
			"properties": {
				"data_type": "SPEED",
				"data_unit": "M_PER_SEC"
			},
			"protocol_config": {
				"report_rate": 60000
			}
		},
		"vbatt": {
			"display_name": "Battery Voltage",
			"description": "Battery Voltage of the sensor",
			"properties": {
				"data_type": "ELEC_POTENTIAL",
				"data_unit": "VOLTS"
			},
			"protocol_config": {
				"report_rate": 60000
			}
		}
	}
}]])
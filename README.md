# Introduction 

A key value proposition of the Internet of Things (IoT) is the ability to derive value from data. In order to do that, however, you must be able to move data from the real world into systems that can help you make sense of it. As the IoT market has matured, more and more organizations have overcome this initial barrier, developing connected solutions that gather device data in the field and reliably communicate it to a cloud platform.

This is a critical first step for any connected solution and, for some organizations, such basic functionality is enough. But for many others, the cloud platform being used in a first-generation version of a solution doesn't provide the functionality necessary to derive the full value of the data being gathered. For example, a platform may act primarily as a data lake, offering extensive capabilities to gather, parse, and store raw data from devices, but provide little in the way of visualization tools that enable users to actually see and act on the data in a meaningful way. 

For an organization to take their solution to the next level, they must be able to integrate their data with other platforms, business systems, and applications that can help them generate actionable insights. But that’s often easier said than done. Especially in the world of industrial IoT, where devices and gateways often have locked firmware and are only capable of connecting to a single cloud platform. In this blog series, we’ll discuss a few of the options available to organizations to unlock the enhanced functionality of other systems without having to modify device firmware or completely forego an existing platform. First up: cloud-to-cloud integrations. 

In this technical post, we’ll discuss how Exosite has made it easy to connect other platforms to our Murano platform via API service integrations. We’ll review how you can create a service integration in Murano that can consume data from an API, connect and securely transmit data, establish authentication, and configure your service and publish it for use. The end result will not only allow you to access Murano’s extensive platform capabilities and leverage ExoSense, Exosite’s ready-to-deploy condition monitoring application, but also easily integrate with other services like Twilio, Salesforce, and even Slack.

# OpenAPI

To make integrations more straight forward and standardized, Exosite makes use of OpenAPI Specification Version 2. OpenAPI uses YAML documents to describe REST APIs, allowing almost anyone with an existing API to integrate with Exosite’s Murano platform. More detailed information for Exosite’s implementation of the OpenAPI Specification is documented in this repository.
Exosite’s development environment exposes APIs as a service within Murano. The diagram below shows the flow of data as its collected, aggregated, and then consumed. In the context of this article, we’ll focus on the data collection and aggregation to enable the consumption of your data by other services and applications, such as ExoSense.

The heavy lifting for integrations is done in the core of Murano, letting you focus on business requirements. Once your API becomes a Murano service, global methods and additional functionality are enabled based on the service definition as represented in YAML. The global methods are exposed and can be integrated into the Lua scripts as shown in the example below. This enables access to third-party services or other cloud platforms from within Murano without having to directly make service requests within the scripts, thus limiting the ability for others to create scripts that cause issues or make bad connections to your API. This same technology is used across the platform to enable many services.

# Example API

We recently worked with a manufacturer in the pump industry who had already deployed a fleet of devices that was connected to a cloud platform. The cloud platform was sufficient for their already deployed devices, but the visualization aspects were limited. The customer wanted to leverage a more powerful platform, but wasn’t quite ready to migrate their devices. So, integrating their existing cloud platform with the Murano platform was an ideal solution. Within a few days, we were able to help them pull their data into Murano and visualize it in an ExoSense instance using an API service integration. During this transitional period, data was being shared with multiple platforms and could be more easily migrated. 

We’ll use this implementation as the basis for our example API below. As such, the example will assume that a device reports data to some cloud platform and that data is exposed through a REST API. We’ll build our OpenAPI specification against this hypothetical API. If you don’t already have an API to expose your data, the hypothetical API used in this example will provide a good starting point for you. The basic structure of the API is shown below:

```bash
/health
/assets
/assets/{id}
/assets/{id}/state
```

All endpoints return data in JSON format and are described below:  

The `/health` endpoint is an optional requirement that enables the service within Murano to use a specific endpoint to ensure the API is operational.
The `/assets` endpoint should return a list of available assets.
The `/assets/{id}` endpoint should return information for a specific asset.
The `/assets/{id}/state` endpoint should return the current state of a specific asset, including the fields and values as reported by the devices connected within the asset.

With this API established, we’ll be able to retrieve a list of assets (`/assets`) that we want to make available for data sharing, allowing us to map these assets into Murano. Next, we can retrieve specific information about each asset (`/assets/{id}`), which helps us add configuration information. We’ll also be able to fetch the unique identification of the asset to register and identify it in Murano. Finally, we will be able to poll the asset state endpoint (`/assets/{id}/state`) in Murano and update the data for the asset in Murano.

# Requirements

As we build our specification, we’ll need to keep a few requirements in mind. These requirements are specific to Murano and help the service properly interpret and communicate with your API.

* The `/heath` endpoint is optionally required for Murano to check the status of your service. A 2XX response status code is considered healthy. An email will be sent to the service maintainer if the service is unreachable. If this value is not provided, Murano will use the `basePath` URL instead. To denote the endpoint, use the `x-exosite-health-path` tag, as shown in the example specifications. If this value isn’t provided and your `basePath` endpoint doesn’t return the appropriate status code, the service will not function properly.
* The `info` tag and all its sub-attributes are necessary. This includes `info.contact.name` and `info.contact.email`.
* A `description` field for each endpoint, attribute, and JSON schema property is required.
* In every JSON schema level, `type` and `description` fields are required. You also need to specify an `operationId` tag for each endpoint you wish to expose.
* The API must support HTTPS, and a valid, signed, and active TLS certificate is required.

# Connection and Security

To connect to your API, you will need to specify your connection details. Because base64 and other token-based authentications can be easily intercepted and decoded, Murano only supports HTTPS for API connections. In the connection details below, all values must be configured. The only valid values for `consumes` and `produces` are `application/json`. 

```yaml
host: myhost.exosite.io
basePath: /api/v1.0
schemes:
  - https
consumes:
  - application/json
produces:
  - application/json
```

# Authentication

Service integrations support multiple forms of authentication, including basic authentication and token-based authentication. We’ll take a look at both types next. Please note that you will need to adjust these examples and configure the specification in a way that works best for your API. 
For more information on OpenAPI authentication, please review the official documentation.

## Basic Authentication

Basic authentication can be handled with the `securityDefinitions` and `security` configuration sections of the OpenAPI specification. Assuming that your API makes use of standard username and password for authentication, the example below details this implementation.

```yaml
securityDefinitions:
  basicAuth:
    type: basic
    description: HTTP basic header
    x-exosite-user-field: username
    x-exosite-secret-field: password
security:
  - basicAuth: []
```

The `x-exosite-user-field` and `x-exosite-secret-field` are further explained in the Setting Static Configuration Data section of this blog and are used for configuration in the Murano UI.

## Token Authentication

To use tokens, you can specify the parameters in the `paths` configuration section of the OpenAPI specification. Tokens can be applied to specific endpoints or to all endpoints. Again, you will need to adjust the specification to fit your API’s needs. Relevant information is available in the official OpenAPI documentation.
Token in path:

```yaml
name: token
in: path
description: token for API authentication
required: true
schema:
  type: string
```

Token in query:

```yaml
name: token
in: query
description: token for API authentication
required: true
schema:
  type: string
```

# Setting Static Configuration Data 

After you have completed detailing your API in the specification, you will need to allow your service to be configured. In the previous examples, we had two types of configuration: basic authentication and tokens. Since different users of your API will have different credentials, we need to enable each user to configure these parameters. Using `x-exosite-config-parameters` exposes these values as fields in the Murano UI.
For basic authentication, we might use the following configuration to enable a user to enter their credentials:

```yaml
x-exosite-config-parameters:
  - name:         username
    description:  Custom API username
    type:         string
    required:     true
  - name:         password
    description:  Custom API password
    type:         string
    format:       password
    required:     true
```

For token authentication, the following configuration will allow a user to enter their unique token:

```yaml
x-exosite-config-parameters:
  - name:         auth_token
    description:  Custom API Secret Key
    type:         string
    format:       password
    required:     true
```

This works great for authentication, but can also be used to enter other unique information if your API requires it.

# The Code

At this point, we have the specification built. Next, follow the steps to author a new integration and publish it within Exchange, Exosite’s IoT marketplace. Exchange provides a library of reusable, interoperable, and secure IoT elements that can be used to build, extend, and inform your IoT solution. Elements that you create, such as Products (device models) and integrations (like the one in this blog), can be shared within and among organizations. Once you have completed the steps in the linked article above to create your integration element, we can focus on the code that we will use to implement the integration.

First, we'll create the devices within Murano that can be used by ExoSense by creating a script called `asset_sync.lua`. This script will reach out to the API and retrieve a list of all assets available. With this list of assets, the script will check for a device within Murano. If the device doesn't exist in Murano, the script will create it.
This script has a few required separate modules. The first module, `sha256.lua`, helps to create a unique ID in Murano based on the identification of your asset.
Another module, `config_io.lua` loads the appropriate `config_io` for your device. You can read more information on `config_io` in the official ExoSense documentation. Create a `config_io` that works for your device in order to maximize your usage of ExoSense.

In short, `config_io` defines the channels of data the device will send to the application. The `config_io` is stored in the `config_io` resource where the device can read and write. Immediately after loading the script, we will set the `config_io` of the device. The snippet below shows the relevant `config_io` code from the `asset_sync.lua` script.

```lua
local config_io = json.parse((device.config_io or {}).set)
if not config_io then
    config_io = require('config_io') or {}
    Device2.setIdentityState({
        identity = assetId,
        config_io = json.stringify(config_io)
    })
end
config_io.channels = config_io.channels or {}
```

The `asset_sync.lua` script reaches out to the `/assets` endpoint to retrieve information about the assets. For the purposes of this example, we will assume that all the information we need about the asset is included in that call as shown below:

```lua
local asset_list = MyCustomService.assets()
```

If you need to fetch more information about your asset before creating it in Murano, you can add an additional call to the `/assets/{id}` endpoint...

```lua
local asset_data = MyCustomService.assetData({“id”]=asset_id})
```

...where `asset_id` is the ID of the asset.

We have now reached a point where the assets in your asset API have a clone device in Murano. To start writing data to these devices, we will create a script called `asset_fetch.lua` that will reach out to the API and retrieve the current state for each asset you have defined.

For each asset, the script will loop through and retrieve the current state. We are making the assumption that your API is the definitive source for the asset list, and that the assets are synced on a regular basis. You may run into issues with this basic example if your asset list changes frequently, and those changes are not properly reflected in Murano. You will need to add error handling if you anticipate frequent changes to your asset list.

```lua
for _, asset in ipairs(asset_list) do
    local data = MyCustomService.assetState({["id"]=asset})
...
```

The code then loops through the current data for the asset and creates a datapoint object. This object is documented in `asset_fetch.lua`. The datapoint is where we store the relevant data from the asset. In this example, we are storing temperature, battery, and vibration. Finally, we execute:

```lua
Interface.trigger({event='event', data=data, mode='sync'})
```

This creates an event that writes the datapoint, and the device and ExoSense are updated. We now have a system that keeps data in both platforms in sync. 

# Next Steps 

We’ve discussed how to develop a service integration in Murano that can consume data from an API in order to integrate a cloud platform with the Murano platform. Once that is complete and data has been written to a device in Murano, you can begin to explore the asset in ExoSense, our ready-to-deploy condition monitoring application. ExoSense combines our software and tools with an end application to provide a solution that’s 80-90% complete. You can then customize the last 10-20% of the solution through a configuration environment that requires zero coding. To learn more, visit the ExoSense web page or check out the ExoSense technical documentation site. If you think ExoSense might be a good fit for you, connect with an Exosite solution expert to talk through your application needs, have a transparent discussion about pricing, and see a demo.  

In part two of this blog series, we’ll discuss how to leverage insights and analytics to enhance the functionality of an existing connected solution. Check back soon for more details. 

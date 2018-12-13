What is our story? Beginning, middle, end. 
-- Stacey - Have an existing solution and you have an API available
-- Michael - Create a Swagger OpenAPI Specification
-- Michael - Create a Murano Service Integration (What is required account side to do this)
-- Stacey - View your data in ExoSense
How should we organize the content?
Do we have any existing marketing material we want to use?
This is called a "Service Integration Exchange Element" - So maybe add some info about Murano Exchange / IoT Marketplace
Michael to ask MikeA for any relevant block diagrams
Stacey to set up a template

Ability to access data from devices with locked firmware


In the world of Industrial IoT we often encounter devices, typical gateways, that have a locked firmware and are only 
capable of connecting to a single cloud platform. This becomes an issue when trying to integrate with other cloud 
platforms. One option is to forward the data to other platforms. However, this isn't always possible. This is where here
at Exosite we have created a way to connect the Murano platform to other APIs, allowing for the ability to sync Assets
and their data.

## Open API

Exosite makes use of OpenAPI Specification Version 2. This allows almost anyone with an existing API to integrate their
service with Exosite Murano.

Information for Exosite's implementation of the Open API specification is documented in 
[this repository](https://github.com/exosite/open_api_integration).

### Block Diagram

Lua script -> function call -> function call as an API definition -> API definition -> Pegasus -> Proxy/call handling
Use case

Development environment that allows global methods to be added for functionality based on a service definition as 
represented in YAML.

Ability to access 3rd party services from within a walled garden, without directly making the service/http requests 
available.

Explain how this helps to enhance security.



## Example API

Let’s use an example API to demonstrate integration with Exosite Murano. Assume that the device reports its data to some 
cloud platform, and that data is exposed through a REST API. We could have the following API structure:

```bash
/health
/assets
/assets/{id}
/assets/{id}/state
```
The `/health` endpoint is optionally required as an endpoint that allows the specification to use a specific endpoint to ensure the API is operational.

The `/assets` endpoint should return a list of available assets.

The `/assets/{id}` endpoint should return information for a specific asset.

The `/assets/{id}/state` endpoint should return the current state of of a specific asset.

With this API established we can do a few simple actions to get started. The first task we can accomplish is to retrieve a list of assets (`/assets`) that 
we would like to make available for sharing of data. This will allow us to map these assets into Murano.

Secondly, we can retrieve specific information about each asset (`/assets/{id}`) which is useful for adding configuration information. 
We’ll get into this a bit more later.

Finally, we have the state of the asset (`/assets/{id}/state`). We can poll this endpoint in Murano and update the data for the asset in 
Murano.

### Requirements 

The `/heath` endpoint is required for Exosite Murano to check the status of your service. A 2xx response status code is considered healthy. An email will be sent to the service maintainer if the service is unreachable. If this value is not provided Murano will use the `basePath` url instead. To denote the endpoint, use the `x-exosite-health-path` tag, as shown in the example specifications.

The `info` tag and all its sub-attributes are necessary. This includes `info.contact.name` and `info.contact.email`.

A `description` field for each endpoint, attribute, and JSON schema property is required.

In every JSON Schema level `type` and `description` fields are required.
You also need to specify an `operationId` tag for each endpoint you wish to expose.

### Connection and Security

To connect to your API you will need to specify your connection details. Because base64 and other token based 
authentications can be easily intercepted and decoded, Murano only supports https for API connections.

```yaml
# A hostname with a valid, signed, and active TLS certificate is required.
host: myhost.exosite.io
basePath: /api/v1.0
schemes:
  - https  # Only https is supported.
consumes:
  - application/json # Only JSON is supported.
produces:
  - application/json # Only JSON is supported.
```

### Authentication

Integrations support multiple forms of authentication, including basic authentication, and token based authentication. 
Let’s take a look at these two types of authentication. You will need to configure the specification in a way that works best for your API.


[More info](https://swagger.io/docs/specification/2-0/authentication/)

#### Basic Authentication

Basic Authentication can be handled with the `securityDefinitions` and `security` configuration sections of the Swagger 
specification. Assuming that your API makers use of username and password for authentication, the following example
details the implementation. 

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

The `x-exosite-user-field` and `x-exosite-secret-field` are explained in the Parameter Configuration section.


#### Token Authentication

To use tokens you can specify the parameters in the `paths` configuration section.

Examples:

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

## Setting Static Configuration Data

After you have completed detailing your API in the specification, you will need to enable your service to be configured. 
In the previous examples we had two types of configuration, basic authentication and tokens.

For basic authentication, we might use the following configuration:

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

For token authentication:

```yaml
x-exosite-config-parameters:
  - name:         auth_token
    description:  Custom API Secret Key
    type:         string
    format:       password
    required:     true
```

At this point we have the specification built and can author a new integration within Murano Exchange. 
[Here](http://docs.exosite.com/reference/ui/exchange/authoring-elements-guide/#authoring-a-new-exchange-element-professional--enterprise-tiers-only)

Once this is created we can focus on the code.

The first step we'll want to accomplish is the creation of devices within Murano that can be used by ExoSense. To do this
we will create a script called `asset_sync.lua`. This script will reach out to the API and retrieve a list of all assets.
From this list of assets the script will check for a device. If the device doesn't exist the script will create it.

```bash
asset_sync.lua
```

This script requires a separate module, `sha256.lua`, which helps to create a unique ID in Murano based on the ID of 
your asset.

Secondly, the script makes use of another module, `config_io.lua`. Read more information on `config_io` in the official
ExoSense [documentation](https://exosense.readme.io/docs/channel-configuration#section-configuration).

In short, the `config_io` defines the channels of data the device will sense to the application. The `config_io` is
stored in the `config_io` resource where the device and read and write. Immediately after creating the script we will
need to set the `config_io` of the device.

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

We have now reached a point where the assets in your asset API have a clone device in Murano. The next step is to start
writing data to these devices. To do this we will create a script called `asset_fetch.lua`. This script will reach out
to the API and retrieve the current state for each asset you have defined.

For each asset, loop through and retrieve the current state:
```lua
local data = MyCustomService.assetState({["id"]=asset})
```

Then the code loops through the data and creates a datapoint, as documented in `asset_fetch.lua`. Finally, we execute:

```lua
Interface.trigger({event='event', data=data, mode='sync'})
```

This creates and event that writes the datapoint and the device and ExoSense are updated.
TODO: Explain this in greater detail

### AuthObject and Variable Injection

The value is injected if the parameter matches the name of the property. The 'x-exosite-from' allows inject a value from 
a different name which shouldn't be necessary here.
How did you include 'AuthObject' in the body?

Eg. this should work 
/bla:
  post: # <- cannot be get
  description: bla
  operationId: bla
  parameters:
    name: body # <- doesnt matter
    in: body
    description: body content
    required: true
    schema: # <- important
       $ref: "#/definitions/AuthObject"
 
Then you probably want to also add x-exosite-restricted: true in the 4 body properties

## ExoSense

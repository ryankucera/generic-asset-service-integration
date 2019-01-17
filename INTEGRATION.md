# Generating Invoices With Prescriptive Analytics in ExoSense

Industrial IoT created a new world where companies could continuously monitor and analyze devices in the field. This constant feedback allows companies to learn more about their devices and begin determining when and why their devices fail. Using this information, we can implement algorithms.

Descriptive analytics -> what is happening?
Predictive analytics -> what might happen?
Prescriptive analytics -> what should we do?

TODO: insert graphics for analytics

For example, we might have a pump in the field that is critical to the flow of some product, such as oil or gas. With ExoSense on Murano we have a continuous stream of data being sent to the platform. This data is describing what is currently happening in the system and is referred to as descriptive analytics. This information can be mined when events happen, such as pump failure. A pattern in the data might emerge and we can create an algorithm that is capable of predicting when the failure will happen. This is referred to as predictive analytics. Lastly, now that we know that a pump is trending toward failure, we can order a replacement in anticipation of the failure. This final step, prescriptive analytics, enables companies to reduce downtime, increase lean aspects of the business, and facilitate JIT manufacturing and operations.

In this example we will demonstrate how to implement the predictive and prescriptive steps within your system. For predictive we will generate a health value of our device. Once this helath value crosses a certain threshold we will reach out to an API where we can generate an order for replacement equipment.

## Getting Started

We will use vibration as the key for the motor health. Other values such as flow rate or diff pressure for the pump can be implmented on top of what is shown here to create a more exhaustive insight. For the purposes of this guide we will assume that your data is already being sent to ExoSense. The data that is flowing into ExoSense is referred to as a `Signal`. These signals are used in the `Asset Config`. For our asset we are currently monitoring `Overall Vibration` as the critical input signal for our algorithms that determines the condition of the asset and eventualy creates an event.

We want this value to go into our custom `Transform Insight` that will calculate the health value. This custom `Transform Insight` will output the health value as another `Signal` which will become the input of another `Transform Insight` that orders a replacement asset once a critical threshold is reached. 

## Transform Insight

The actual `Transform Insight` has criteria to fulfill before it can be displayed in the UI of ExoSense.
1. Create a `Murano Service` by creating a Swagger file for the `Insight`
2. The file has a specific name of `insight-template.yaml` and can be found in `docs/insight-template.yaml`

## Insight YAML File

The Insight is described using a YAML file. You can find an example template of this file in `docs/insight-template.yaml`. This file will be modified and linked when creating a Murano Exchange Element. The following elements of the YAML file are required. 
1. Must specify a host that is public and secured with HTTPS. 
2. The name of the insight is used to describe the insight within the Service Config in Murano.
3. The name of the Murano Exchange Element you add has to have the word Insight first (e.g., Insight Generic Asset)
4. Three primary endpoints need to be described:

### GET /info

The `/info` endpoint returns the description of the Insight, information about whether or not Group ID is required, and the name of the insight as displayed in the ExoSense UI.

### POST /insight

The `/insight` endpoint returns a list of functions and variables for the form within the ExoSense UI that can be filled out. There is a Group ID feature in the `/insights` endpoint. One way you can make use of the Group ID feature is with part numbers. Customers can enter their specific part number to get the right algorithm out of one Insight endpoint. 

### POST /process

The `/process` endpoint is where the Insight magic happens. This is where the work, such as code for predictive and prescriptive algorithms, is executed. The endpoint requires data in a certain schema that is predefined and responds with an array of arrays each of which is an array of signal data.

```json
{
    'vibration': 'value'
}
```

TODO: Link to public documentation for the content of the YAML file.

## Insight Endpoints

This Insight example is written in the context of a Murano Application Solution. You can host your actual insight code anywhere so long as it can be reached by the Murano Platform. Below are the scripts that are executed with the previously mentioned endpoints. We'll discuss their functinality here.

The file `modules/insightModule.lua` is a module that is used by the `/process` endpoint. As with any code, it's good to break out functions and methods in a reusable way.

TODO: Insert actual algorithm here and in the file. 1st for determining health and second for determining if parts should be ordered
TODO: Our use case will be that once the asset drops under 10% health we should order to ensure that the replacement arrives in time.

The file `endpoints/insights.post.lua` describes all of the meta data for the Insight. The meta data includes the type of data to send, formats, data that is returned, and which fields need to be completed by form in the ExoSense UI. In this example, we describe two insights, `healthScore` and `healthAction`.

```lua
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
  }
}
```

The file `endpoints/process.post.lua` is used in the `/process` endpoint. 
This takes the payload and executes the module for the actual insight and then returns the data.

The file `docs/insight-template.yaml` is uploaded when creating a Murano Exchange Element. For most users, this has to be uploaded in a public location that is accessible from Murano itself. The link to the document will be used to create the Exchange Element. You'll want to first create an Application Solution in Murano. Using the Murano UI, you will need the URL for the solution and this will be inserted into `insight-template.yaml` as shown below:

```yaml
host: generic-asset-service.apps.exosite.io # Set this to the host your function is on
basePath: / # Set this or the path according to your function
```

At this point we have the Insight specification ready and can author a new integration within Murano Exchange. 
[Here](http://docs.exosite.com/reference/ui/exchange/authoring-elements-guide/#authoring-a-new-exchange-element-professional--enterprise-tiers-only)

We then add the service to the business and enable it. 
TODO: Add information on this step

Once this is created we can focus on the code. For this section you'll want to be familiar with the [Murano CLI](https://docs.exosite.com/development/tools/murano-cli/)

This project is organized such that the code and be uploaded to your Application Solution within Murano. In your terminal, with Murano CLI installed, execute the following commands:

```bash
murano config application.id <application.id>
murano syncup -E -M 
```

The first command associates the local code with the Application Solution you have created. You may have to login to Murano with the `murano login` command before this will work properly. The second command syncs the data up to Murano. The `-E` and `-M` modifiers only sync up items in the `endpoints` and `modules` folders.


Go to the ExoSense instance within the business.
Add transformations in asset config

## Algorithms

For this example we have two very basic algorithms. These algorithms will control the flow of the application through the Insights.

### Asset Health Algorithm

The first algorithm is the calculation of the asset health. We will assume the input is measured with accelation in meters per second. Based on the measurement of meters per second we will create the following lookup table for asset health.

0.00 - 100%
0.01 -  80%
0.05 -  50%
0.10 -  30%
0.20 -  10%
0.30 -   0%

The input will be analyzed by the algorithm and the insight will return the appropriate health percentage in the rage of 0.00 to 1.00. This health percentage will be stored in a signal.

### Asset Action Algorithm

Now that we are capable of determining the health of our asset, we can take appropriate action on the various levels.

<= 0.5 - Email asset is at 50% life
<= 0.3 - Email asset is at 30% life and a replacement may be needed soon
<= 0.1 - Email asset nearing end of life, replacement is being ordered
== 0.0 - Email asset imminent failure, replace as soon as possible to prevent unplanned downtime

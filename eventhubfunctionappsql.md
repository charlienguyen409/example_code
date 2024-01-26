To accomplish your task, we need to break it down into two main parts:  
   
1. Ingesting data into Azure Event Hub using JavaScript.  
2. Creating an Azure Function that triggers on an Event Hub event to insert a row into Azure SQL.  
   
**Part 1: Ingesting data into Azure Event Hub using JavaScript**  
   
You can use the `@azure/event-hubs` package to send data to Azure Event Hub. First, you need to install the package by running `npm install @azure/event-hubs`.  
   
Here's an example of how to send data to an Event Hub:  
   
```javascript  
const { EventHubProducerClient } = require("@azure/event-hubs");  
   
// connection string for the Event Hubs namespace  
const connectionString = "EVENT_HUBS_NAMESPACE_CONNECTION_STRING";  
   
// name of the event hub  
const eventHubName = "EVENT_HUB_NAME";  
   
// data to send  
const eventData = { /* Your data object */ };  
   
async function main() {  
  // Create a producer client to send messages to the event hub.  
  const producer = new EventHubProducerClient(connectionString, eventHubName);  
  
  // Prepare a batch of events to send to the event hub  
  let batch = await producer.createBatch();  
  batch.tryAdd({ body: eventData });  
  
  // Send the batch to the event hub  
  await producer.sendBatch(batch);  
  
  // Close the producer client  
  await producer.close();  
}  
   
main().catch((error) => {  
  console.error("Error running sample:", error);  
});  
```  
   
Replace `EVENT_HUBS_NAMESPACE_CONNECTION_STRING` with your Event Hubs namespace connection string and `EVENT_HUB_NAME` with the name of your Event Hub.  
   
**Part 2: Creating an Azure Function to insert a row into Azure SQL**  
   
You'll need to set up an Azure Function with an Event Hub trigger to listen for incoming messages. Then, you'll use the `mssql` package to connect to Azure SQL and insert a row.  
   
First, create an Azure Function with an Event Hub trigger using the Azure portal or Azure CLI.  
   
Next, install the `mssql` npm package by running `npm install mssql` in your function's directory.  
   
Here's an example of an Azure Function that inserts a row into Azure SQL:  
   
```javascript  
const sql = require('mssql');  
   
const config = {  
  user: 'YOUR_SQL_USERNAME',  
  password: 'YOUR_SQL_PASSWORD',  
  database: 'YOUR_DATABASE_NAME',  
  server: 'YOUR_SQL_SERVER_NAME',  
  pool: {  
    max: 10,  
    min: 0,  
    idleTimeoutMillis: 30000  
  },  
  options: {  
    encrypt: true, // for azure  
    trustServerCertificate: false // change to true for local dev / self-signed certs  
  }  
};  
   
module.exports = async function (context, eventHubMessages) {  
  await sql.connect(config);  
  const transaction = new sql.Transaction(/* [connection] */);  
  
  try {  
    await transaction.begin();  
  
    const request = new sql.Request(transaction);  
    for (const message of eventHubMessages) {  
      // Assuming the message contains the necessary data  
      await request.query(`INSERT INTO YourTableName (Column1, Column2) VALUES ('${message.data1}', '${message.data2}')`);  
    }  
  
    await transaction.commit();  
    context.log('Transaction committed.');  
  } catch (error) {  
    await transaction.rollback();  
    context.log.error('Transaction rolled back.', error);  
  } finally {  
    sql.close();  
  }  
};  
```  
   
Replace `YOUR_SQL_USERNAME`, `YOUR_SQL_PASSWORD`, `YOUR_DATABASE_NAME`, and `YOUR_SQL_SERVER_NAME` with your Azure SQL credentials and server details. Also, replace `YourTableName` and the column names with the actual names from your database schema.  
   
Make sure to secure your credentials using Azure Function App settings instead of hardcoding them into the code.  
   
Please note that the provided code is a basic example,

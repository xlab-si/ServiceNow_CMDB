# ServiceNow\_CMDB

Integration of ServiceNow’s CMDB management with ManageIQ

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Importing ServiceNow datastore to ManageIQ](#importing-servicenow-datastore-to-manageiq)
3. [Modifying the imported domains Instance values](#modifying-the-imported-domains-instance-values)
4. [Creating Servicenow Incident Generic Object](#creating-servicenow-incident-generic-object)
5. [Creating Add ServiceNow Incident Button](#creating-add-servicenow-incident-button)
6. [Creating Servicenow catalog](#creating-servicenow-catalog)
7. [Creating ServiceNow Create Incident Service Catalog Item](#creating-servicenow-create-incident-service-catalog-item)
8. [Creating ServiceNow View and Update Incidents Service Catalog Item](#creating-servicenow-view-and-update-incidents-service-catalog-item)

## Prerequisites

- Download the [zip](./ServiceNow_CMDB.zip) containing the datastore classes from this repository.
- Download the dialogs yaml file from [ServiceNow_Dialogs](https://github.com/xlab-si/ServiceNow_Dialogs).
- Make sure you have a running instance of ManageIQ (the steps in this document are performed in ManageIQ's UI).
- Make sure you have a running Servicenow Instance and the required credentials.

### Importing ServiceNow datastore to ManageIQ

- Navigate to `Automation -> Embedded Automate -> Import / Export`.

- Under `Import Datastore Classes (*.zip)`, select `Choose file` and open [zip file](./ServiceNow_CMDB.zip) that contains the datastore classes, then click `Upload`:

  - Under `Select domain you wish to import from:`, select `ServiceNow`.
  - Under `Select namespaces you wish to import from:`, select `Toggle All` and click `Commit`.
  - Under `Select domain you wish to import from:`, select `ManageIQ`.
  - Under `Select namespaces you wish to import from:`, select `Toggle All` and click `Commit`.

- Navigate to `Automation -> Embedded Automate -> Explorer`.

- Under `Datastore`, select `Datastore -> ServiceNow`:
  - Select `Configuration -> Edit this domain`:
    - Check the `Enabled` checkbox and click on `save`.

### Modifying the imported domain's Instance values

After importing the required domains, the instance's Servicenow related properties need to be updated
to match an existing, running Servicenow Instance.

- Navigate to `Automation -> Embedded Automate -> Explorer`.

- For all the required instances ('create\_generic\_incident', ... , 'get\_snow\_assignment\_groups', ...) perform the following steps:

  - Select `Configuration -> Edit this instance`:
    - Replace `(snow_server)` value with your Servicenow Instance Host.
    - Replace `(snow_user)` and `(snow_password)` values with your Servicenow's user and password.
    - Replace `(proxy_url)` with your instance's proxy url, or leave blank if there is none.

  **NOTE** values are used in `"https://#{snow_server}/api/now/table/#{table_name}"`, so make sure to leave
  out the https:// and any endpoints from the `(snow_server)` value.

  **NOTE** make sure to select automate instances, as there should be an automate instance and an automate method with the same name.

### Creating ServiceNow Incident Generic Object

- Navigate to `Automation -> Embedded Automate -> Generic Objects`.

- Select `Generic Object Definitions -> All Generic Object Definitions` and then select `Configuration -> Add a new Generic Object Definition`:
  - Under `Name`, enter "Servicenow\_Incident".
  - Under `Description`, enter  "Servicenow Incident created from Cloudform".
  - Add the following `Attributes`:
    - ci\_name: "String",
    - ci\_type: "String",
    - urgency: "Integer",
    - short\_description: "String",
    - number: "String",
    - comments: "String",
    - sys\_id: "String",
    - state: "String",
    - assignment\_group: "String",
    - created\_by: "String",
  - Click `Add`.

### Creating Add ServiceNow Incident Button

- Navigate to `Automation -> Embedded Automate -> Customization`.

- Select `Buttons -> Object Types -> {object_type}`.

- Select `Configuration -> Add a new Button Group`:
  - Under `Name`, enter `Servicenow`.
  - Under `Description`, enter `Servicenow Button Group`.
  - Check `Display on Button` and select an `Icon` and `Icon color`.
  - Click `Add`.

- Select the created group and select `Configuration -> Add a new Button`:
  - Under `Name`, enter `Create Servicenow Incident`.
  - Check `Display on Button`.
  - Select an `Icon` and `Icon Color`.
  - Under `Dialog` select "Create Context Specific Snow Incident".

  - Under the `Advanced` tab, under `Object Details` enter the following values:
    - System/Process: "Request",
    - Message: "create",
    - Request: "Call\_Instance",
    - Under `Attribute/Value Pairs`, add the pair: "action": "create".

  - Click `Add`.

### Importing the dialogs for the ServiceNow datastore methods

- Navigate to `Automation -> Embedded Automate -> Customization`.

- Under `Import`, select the dialogs yaml file and click `Upload`:

  - Under `Import Service Dialogs`, check all the dialogs and click `Commit`.

### Creating ServiceNow catalog

- Navigate to `Services -> Catalogs`.

- Under `Catalogs`, select `All Catalogs`.

- Select `Configuration -> Add New Catalog`:

  - Under `Name`, type "Servicenow".
  - Under `Description`, type "Catalog for Servicenow Incident Management Operations".
  - Click `Save`.

### Creating ServiceNow Create Incident service catalog item

- Navigate to `Services -> Catalogs`.

- Under `Catalog Items`, select `All Catalog Items -> Servicenow`:
  - Select `Configuration -> Add a New Catalog Item`:
    - Do the following in the `Basic Info` section:
      - Under `Catalog Item Type` select `Generic`.
      - Under `Name / Description` type "Create Incident" and "Catalog Item to create Servicenow incident".
      - Check `Display in Catalog` checkbox.
      - Under `Catalog` select `My Company/Servicenow`.
      - Under `Dialog` select `Create Generic Snow Incident`.
      - Under `Provisioning Entry Point` select `/ServiceNow/Integratin/ServiceNow/CMDB/create_generic_incident` (check `Include Domain prefix in path`).
      - Under `Retirement Entry Point` select `/ManageIQ/Service/Retirement/StateMachines/ServiceRetirement/Default` (check `Include Domain prefix in path`).
    - Do the following in the `Details` section:
      - Under `Long Description` type "Use this catalog item to create servicenowincident. Select the appropriate CI type and enter descriptions appropriately.".
    - Click `Add`.

### Creating ServiceNow View and Update Incidents service catalog item

- Navigate to `Services -> Catalogs`.

- Under `Catalog Items`, select `All Catalog Items -> Servicenow`:
  - Select `Configuration -> Add a New Catalog Item`:
    - Do the following in the `Basic Info` section:
      - Under `Catalog Item Type` select `Generic`.
      - Under `Name / Description` type "View and Update Incidents" and "Update Servicenow Incidents.".
      - Check `Display in Catalog` checkbox.
      - Under `Catalog` select `My Company/Servicenow`.
      - Under `Dialog` select `Create Generic Snow Incident`.
      - Under `Provisioning Entry Point` select `/ServiceNow/Integratin/ServiceNow/CMDB/update_servicenow_incident` (check `Include Domain prefix in path`).
      - Under `Retirement Entry Point` select `/ManageIQ/Service/Retirement/StateMachines/ServiceRetirement/Default` (check `Include Domain prefix in path`).
    - Do the following in the `Details` section:
      - Under `Long Description` type "Use this catalog item to view and update servicenow incident. On Selecting the incident, the latest details from servicenow will be pulled. Update the required details and submit.".
    - Click `Add`.

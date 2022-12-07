# ServiceNow\_CMDB

Integration of ServiceNow’s CMDB management with ManageIQ

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Importing ServiceNow datastore to ManageIQ](#importing-servicenow-datastore-to-manageiq)
3. [Modifying the imported domains Instance values](#modifying-the-imported-domains-instance-values)
4. [Creating Servicenow Incident Generic Object](#creating-servicenow-incident-generic-object)
5. [Importing the dialogs for the ServiceNow datastore methods](#importing-the-dialogs-for-the-servicenow-datastore-methods)
6. [Creating Add ServiceNow Incident Button](#creating-add-servicenow-incident-button)
7. [Creating Servicenow catalog](#creating-servicenow-catalog)
8. [Creating ServiceNow Create Incident Service Catalog Item](#creating-servicenow-create-incident-service-catalog-item)
9. [Creating ServiceNow View and Update Incidents Service Catalog Item](#creating-servicenow-view-and-update-incidents-service-catalog-item)
10. [Using ServiceNow Catalog Items and Buttons](#using-servicenow-catalog-items-and-buttons)

## Prerequisites

- Clone the repository and zip the `ServiceNow` directoriy.
- Download the [dialogs](https://github.com/xlab-si/ServiceNow_Dialogs/blob/main/ServiceNow_Dialogs.yml) yaml file from [ServiceNow_Dialogs](https://github.com/xlab-si/ServiceNow_Dialogs).
- Make sure you have a running instance of ManageIQ (the steps in this document are performed in ManageIQ's UI).
- Make sure you have a running Servicenow Instance and the required credentials.

### Importing ServiceNow datastore to ManageIQ

- Navigate to `Automation -> Embedded Automate -> Import / Export`.

- Under `Import Datastore Classes (*.zip)`, select `Choose file` and open the zip file that contains the datastore classes, then click `Upload`:

  - Under `Select domain you wish to import from:`, select `ServiceNow`.
  - Under `Select namespaces you wish to import from:`, select `Toggle All` and click `Commit`.

- Navigate to `Automation -> Embedded Automate -> Explorer`.

- Under `Datastore`, select `Datastore -> ServiceNow`:
  - Select `Configuration -> Edit selected domain`:
    - Check the `Enabled` checkbox and click on `save`.

### Modifying the imported domain's Instance values

After importing the required domains, the instance's Servicenow related properties need to be updated
to match an existing, running Servicenow Instance.

- Navigate to `Automation -> Embedded Automate -> Explorer`.

- For all the [required instances](./ServiceNow/Integration/ServiceNow/CMDB.class/__methods__/) perform the following steps:

  - Select `Configuration -> Edit this instance`:
    - Replace `(snow_server)` value with your Servicenow Instance Host.
    - Replace `(snow_user)` and `(snow_password)` values with your Servicenow's user and password.
    - Replace `(proxy_url)` with your instance's proxy url, or leave blank if there is none.

  > **NOTE** values are used in `"https://#{snow_server}/api/now/table/#{table_name}"`, so make sure to leave
  out the https:// and any endpoints from the `(snow_server)` value.

  > **NOTE** make sure to select automate instances, as there should be an automate instance and an automate method with the same name.

### Creating ServiceNow Incident Generic Object

- Navigate to `Automation -> Embedded Automate -> Generic Objects`.

- Select `Generic Object Definitions -> All Generic Object Definitions` and then select `Configuration -> Add a new Generic Object Definition`:
  - Under `Name`, enter "Servicenow\_Incident".
  - Under `Description`, enter  "Servicenow Incident created from Cloudform".
  - Add the following `Attributes`:
    - ***ci\_name***: "String",
    - ***ci\_type***: "String",
    - ***urgency***: "Integer",
    - ***short\_description***: "String",
    - ***number***: "String",
    - ***comments***: "String",
    - ***sys\_id***: "String",
    - ***state***: "String",
    - ***assignment\_group***: "String",
    - ***created\_by***: "String",
  - Click `Add`.
  > ***NOTE***: The object's attributes match the ***Incident***'s attributes, they may be changed, but then the `create.rb` method should be updated accordingly.
  

### Importing the dialogs for the ServiceNow datastore methods

- Navigate to `Automation -> Embedded Automate -> Customization`.

- Under `Import`, select the [dialogs](https://github.com/xlab-si/ServiceNow_Dialogs/blob/main/ServiceNow_Dialogs.yml) yaml file and click `Upload`:

  - Under `Import Service Dialogs`, check all the dialogs and click `Commit`.

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
  - Under `Description`, enter `Create Servicenow Incident Button`.
  - Check `Display on Button`.
  - Select an `Icon` and `Icon Color`.
  - Under `Dialog` select "Create Context Specific Snow Incident".
  - ***NOTE***: Make sure `Open Url` is ***unchecked***.

  - Under the `Advanced` tab, under `Object Details` enter the following values:
    - ***System/Process***: "Request",
    - ***Message***: "create",
    - ***Request***: "Call\_Instance",
    - Under `Attribute/Value Pairs`, add the pair: ***action***: "create".

  - Click `Add`.

  > When creating the button, you may specify expressions that define where the button is enabled or visible.
  >
  > Example - creating a button on a Physical Server with name `physical-server-1`:
  >  * During the button creation under the `Advanced` tab:
  >    * Under `Visibility / Edit Selected Element` select `Field`.
  >    * Another dropdown should appear, select `Physical Server:Name`.
  >    * Another dropdown and text box should appear; In dropdown, select `REGULAR EXPRESSION MATCHES`, and in text box insert `physical-server-1`.
  >    * Click `Commit`.

### Creating ServiceNow catalog

- Navigate to `Services -> Catalogs`.

- Under `Catalogs`, select `All Catalogs`.

- Select `Configuration -> Add New Catalog`:

  - Under `Name`, type "Servicenow".
  - Under `Description`, type "Catalog for Servicenow Incident Management Operations".
  - Click `Add`.

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
      - Under `Provisioning Entry Point` select `/ServiceNow/Integration/ServiceNow/CMDB/create_generic_incident` (check `Include Domain prefix in path`).
      - Under `Retirement Entry Point` select `/ServiceNow/Service/Retirement/StateMachines/ServiceRetirement/Default` (check `Include Domain prefix in path`).
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
      - Under `Dialog` select `View and Update Servicenow Incidents`.
      - Under `Provisioning Entry Point` select `/ServiceNow/Integration/ServiceNow/CMDB/update_servicenow_incident` (check `Include Domain prefix in path`).
      - Under `Retirement Entry Point` select `/ServiceNow/Service/Retirement/StateMachines/ServiceRetirement/Default` (check `Include Domain prefix in path`).
    - Do the following in the `Details` section:
      - Under `Long Description` type "Use this catalog item to view and update servicenow incident. On Selecting the incident, the latest details from servicenow will be pulled. Update the required details and submit.".
    - Click `Add`.

### Using ServiceNow Catalog Items and Buttons

#### Creating Generic Incidents and updating their urgencies from Catalog Items

- Navigate to `Services -> Catalogs`.

- Under `Service Catalogs` select the desired Catalog Item and click `Order`.
  - Fill the dialog and click `Commit`.

#### Creating Context Specific Incidents with a button.

- Navigate to the Object Type on which the button has been created (Example for ***Provider*** object type: `Compute -> Physical Infrastructure -> Providers`, and select the provider)

- When in the Object Type's section, the `Servicenow` button group should be visible:
  - Select it and select the `Create Incident` button.
  - Fill the dialog and click `Commit`.

#### Viewing the Created Incidents as Generic Objects

- Navigate to `Automation -> Embedded Automate -> Generic Objects`.
- Under `Generic Object Definitions` select the `Servicenow_Incident`.
- Under `Relationships` the number of instances should be visible, clicking on that number should display them.

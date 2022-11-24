#
# Description: Create ServiceNow CMDB Record
# Updated 12/9/2021 ZDD
# This method was originally created to forward alerts from UCS to SNOW.
# That functionality is now performed directly from Ansible Tower, but we
# need to now be able to also create SNOW incidents based on MiQ Alerts.
# I've commented out the 'case' code to make this single-purpose for use 
# with MiQ Alerts.

require 'rest-client'
require 'json'
require 'base64'

def log(level, message)
  method = '----- Create ServiceNow CMDB Record -----'
  $evm.log(level, "#{method} - #{message}")
end

assignment_group = "CaaS-Gen"
snow_server   = $evm.object['snow_server']
snow_user     = $evm.object['snow_user']
snow_password = $evm.object.decrypt('snow_password')
table_name    = $evm.object['table_name']
uri           = "https://#{snow_server}/api/now/table/#{table_name}"

log(:info, "vmdb_object_type => <#{$evm.root['vmdb_object_type']}>")

obj_type = $evm.root['vmdb_object_type']

#case $evm.root['vmdb_object_type']
#when 'automation_task' # This flow is for UCS Alert triggered by the automation task. Called by playbook.
#  alert_desc = $evm.object['short_description']
#  comments = $evm.object['comments']
#  urgency  = $evm.object['urgency']
#  vm_name = "UCS - Fault/Alert"
#  virtual = true
#  ci_type = "UCS - Fault/Alert"
# created_by = "#{snow_user}"
#else
obj_name = $evm.root[obj_type]
vm_name = obj_name
alert_desc = "#{vm_name} : #{$evm.root['miq_alert_description']}"
virtual = true
comments = "#{alert_desc}"
urgency = 3
ci_type = "MiQ - Alert"
created_by = "#{snow_user}"
#end

headers = {
  :content_type  => 'application/json',
  :accept        => 'application/json',
  :authorization => "Basic #{Base64.strict_encode64("#{snow_user}:#{snow_password}")}"
}
payload = {
    :virtual           => virtual,
    :short_description => "#{alert_desc}",
    :urgency			 => urgency,
    :comments			 => "#{comments}",
  	:assignment_group	 => "#{assignment_group}",
  	:sys_created_by		 => "#{snow_user}",
  	:u_qs_reported_by	 =>  "#{snow_user}",
    :company => "KPI_IAAS",
    :business_service => "CaaS-Shared",
 	:u_qs_type => "Incident"
  }

log(:info, "-------------------------------------#{payload}------------------------------------------------------")
RestClient.proxy = $evm.object['proxy_url'] unless $evm.object['proxy_url'].nil?
request = RestClient::Request.new(
  :method  => :post,
  :url     => uri,
  :headers => headers,
  :payload => payload.to_json
)
rest_result = request.execute
log(:info, "Return code <#{rest_result.code}>")
json_parse = JSON.parse(rest_result)
result = json_parse['result']
log(:info, "Number => <#{result['number']} -- sys_id => #{result['sys_id']}>")
# Add sys_id to VM object
go_class = $evm.vmdb(:generic_object_definition).find_by_name("Servicenow_Incident")
new_go = go_class.create_object(:name => "#{result['number']}",
  						 :ci_name => vm_name,
                         :urgency => urgency,
                         :short_description => alert_desc,
						 :comments => comments,
  						 :ci_type => "#{ci_type}",
  						 :sys_id => "#{result['sys_id']}",
  						 :number => "#{result['number']}",
						 :state => "#{result['state']}",
  						 :assignment_group => "#{assignment_group}",
  						 :created_by 	=> "#{created_by}"
				)

new_go.save!

# Add this incident to the VM as a custom attribute so that to track the list of incidents raised for this specific vm/object
# For automation tasks (UCS triggers) object type will be automation_task - so we cant associate to any obj. Associate to objects other than automation_task
if (obj_type != "automation_task")
  obj_type = $evm.root['vmdb_object_type']
  obj_name = $evm.root[obj_type]
  existing_incidents = obj_name.custom_get(:SERVICENOW_INCIDENTS)
  current_incident =  "#{result['number']}"
  all_incidents = "#{existing_incidents}, #{current_incident}"
  obj_name.custom_set(:SERVICENOW_INCIDENTS, all_incidents)
end

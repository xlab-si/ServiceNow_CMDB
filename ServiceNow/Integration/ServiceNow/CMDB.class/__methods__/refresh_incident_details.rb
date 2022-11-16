#
# Description: Get Servicenow details for the incident
#

require 'rest-client'
require 'json'
require 'base64'

def log(level, message)
  method = '----- Refresh Incident Details : refresh_incident_details -----'
  $evm.log(level, "#{method} - #{message}")
end

snow_server   = $evm.object['snow_server']
snow_user     = $evm.object['snow_user']
snow_password = $evm.object.decrypt('snow_password')
table_name    = $evm.object['table_name']
uri           = "https://#{snow_server}/api/now/table/#{table_name}"

headers = {
  :content_type  => 'application/json',
  :accept        => 'application/json',
  :authorization => "Basic #{Base64.strict_encode64("#{snow_user}:#{snow_password}")}"
}

case $evm.root['vmdb_object_type']
when 'miq_provision'
  prov = $evm.root['miq_provision']
  vm   = prov.vm unless prov.nil?
when 'service_template_provision_task'
  # Added for generic catalogue item scenario
  incident_number = $evm.root['dialog_refresh_snow_incident_list_incidents']
  this_go = $evm.vmdb('generic_object').find_by_name("#{incident_number}")
else
  this_go = $evm.root['generic_object']
end
  
sys_id = this_go.attributes['properties']['sys_id']
raise 'ServiceNow sys_id is empty' if sys_id.nil?

uri = "#{uri}/#{sys_id}"
log(:info, "uri => #{uri}")

request = RestClient::Request.new(
  :method  => :get,
  :url     => uri,
  :headers => headers
)
rest_result = request.execute
log(:info, "Return code <#{rest_result.code}>")

#sleep 10

json_parse = JSON.parse(rest_result)
result = json_parse['result']

log(:info, "sys_id => <#{result['sys_id']}>")
log(:info, "urge => <#{result['urgency']}>")
this_go.attributes = {
  						urgency: "#{result['urgency']}", 
  						short_description: "#{result['short_description']}"
  					 }
this_go.save!
  
#new_go.add_to_service($evm.root['service'])  
#$evm.root['service'].name = "Service Now Incident: #{result['number']}"  
#TODO : Redirect to some other page or refresh the current page.  

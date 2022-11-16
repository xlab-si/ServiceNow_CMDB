#
# Description: Update ServiceNow CMDB Record
#

require 'rest-client'
require 'json'
require 'base64'

def log(level, message)
  method = '----- Update ServiceNow CMDB Record -----'
  $evm.log(level, "#{method} - #{message}")
end

def get_virtual_column_value(vm, virtual_column_name)
  virtual_column_value = vm.send(virtual_column_name)
  return virtual_column_value unless virtual_column_value.nil?
  nil
end

def hostname(vm)
  vm.hostnames.first.presence || vm.name
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

# Grab the VM object
#log(:info, "vmdb_object_type => <#{$evm.root['vmdb_object_type']}>")
#case $evm.root['vmdb_object_type']
#when 'miq_provision'
#  prov = $evm.root['miq_provision']
#  vm = prov.vm unless prov.nil?
#else
#  vm = $evm.root['vm']
#end
#log(:warn, 'VM object is empty') if vm.nil?
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
    sys_id = this_go.attributes['properties']['sys_id']
  end

sys_id = this_go.attributes['properties']['sys_id']
raise 'ServiceNow sys_id is empty' if sys_id.nil?
uri   = "#{uri}/#{sys_id}"

urgency  = $evm.root['dialog_view_update_snow_incident_urgency']
comments = "#{$evm.root['dialog_view_update_snow_incident_comments']}"

payload = {
  :urgency			 => urgency,
  :comments			 => comments
  }


request = RestClient::Request.new(
  :method  => :put,
  :url     => uri,
  :headers => headers,
  :payload => payload.to_json
)
rest_result = request.execute
log(:info, "Return code <#{rest_result.code}>")

this_go.comments = comments
this_go.urgency = urgency
this_go.save!

#new_go.add_to_service($evm.root['service'])  
#$evm.root['service'].name = "Update:Servicenow Incident: #{result['number']}"
#this_go.refresh()
#json_parse = JSON.parse(rest_result)
#result = json_parse['result']
#log(:info, "sys_id => <#{result['sys_id']}>")
#log(:info, "urge => <#{result['urgency']}>")
#this_go.urgency = result['urgency']
#this_go.short_description = result['short_description']
#log(:info, "#{result['urgency']} --------- #{result['short_description']}")
#this_go.save!
#this_go.remove_from_service
#this_go.add_to_service($evm.root['service']) 
#$evm.root['service'].name = "Service Now Incident: #{result['number']}"
#$evm.root['service'].name = "Service Now Incident: #{result['number']}"

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

log(:info, "Getting item details #{$evm.object['state']}")
request = RestClient::Request.new(
  :method  => :get,
  :url     => uri,
  :headers => headers
)
rest_result = request.execute
log(:info, "Return code <#{rest_result.code}>")

json_parse = JSON.parse(rest_result)
result = json_parse['result']

# Extend payload attributes as required
#result[:virtual]           = $evm.object['virtual']     || true
#result[:name]              = $evm.object['name']        || vm.name
#result[:short_description] = "#{$evm.root['dialog_update_generic_snow_incident_short_description']}"
#result[:urgency]           = $evm.root['dialog_update_generic_snow_incident_urgency']
#result[:state]             = $evm.root['dialog_update_generic_snow_incident_state']

result[:comments]          = "#{$evm.root['dialog_update_generic_snow_incident_comments']}"

log(:info, "payload => #{result}")

this_go.urgency = result['urgency']
this_go.short_description = "#{result['short_description']}"
#this_go.comments = "#{$evm.root['dialog_update_generic_snow_incident_comments']}"
log(:info, "#{result['urgency']} --------- #{result['short_description']}")
log(:info, 'Updating record details')

request = RestClient::Request.new(
  :method  => :put,
  :url     => uri,
  :headers => (headers.merge!(:cookies => request.cookies)),
  :payload => result.to_json
)
rest_result = request.execute
log(:info, "Return code <#{rest_result.code}>")

this_go.comments = "#{$evm.root['dialog_update_generic_snow_incident_comments']}"
this_go.save!

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

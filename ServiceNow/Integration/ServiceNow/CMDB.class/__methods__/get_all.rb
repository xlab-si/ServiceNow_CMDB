#
# Description: Get All ServiceNow CMDB Records
#

require 'rest-client'
require 'json'
require 'base64'

def log(level, message)
  method = '----- Get All ServiceNow CMDB Records -----'
  $evm.log(level, "#{method} - #{message}")
end


$evm.log(:info, "Hello, World Rohit!")
go_class = $evm.vmdb(:generic_object_definition).find_by_name("ServiceNowGO")
new_go = go_class.create_object(:name => "SNowGO",
  						 :vm_name => "GenericVM1",
                         :urgency => "2",
                         :short_description => "Test short description for VM generic way")
#vm = $evm.vmdb(:vm, dialog_options['dialog_association_vm'])
$evm.log(:info, "Getting VM.......")
vm = $evm.vmdb(:vm).find_by_name('demo')
$evm.log(:info, "After Getting VM.......")
#$evm.log(:info, vm)

new_go.vms = [vm]
new_go.save!
#new_go.add_to_service($evm.root['service'])
log(:info, 'Called the new GO class and instantiated......')

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

log(:info, "uri => #{uri}")

request = RestClient::Request.new(
  :method  => :get,
  :url     => uri,
  :headers => headers
)
rest_result = request.execute
log(:info, "Return code <#{rest_result.code}>")

json_parse = JSON.parse(rest_result)
result = json_parse['result']
result.each do | ci |
  log(:info, "Item <#{ci['name']}> attributes:")
  ci.sort.each do | k, v |
    log(:info, "    #{k} => <#{v}>")
  end
end

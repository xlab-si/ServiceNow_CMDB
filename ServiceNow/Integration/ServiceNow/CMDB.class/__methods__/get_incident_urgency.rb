#
# Description: Get ServiceNow CMDB Record
#

require 'rest-client'
require 'json'
require 'base64'

def log(level, message)
  method = '----- Get ServiceNow CMDB Record -----'
  $evm.log(level, "#{method} - #{message}")
end

begin
  incident_number = $evm.root['dialog_refresh_snow_incident_list_incidents']
  this_go = $evm.vmdb('generic_object').find_by_name("#{incident_number}")
  if (this_go != nil)
    urgency = this_go.urgency
    values = {"1" => "1 - High","2" => "2 - Medium","3" => "3 - Low" } 
    list_values = {
      'sort_by'    => :value,
      'data_type'  => :string,
      'required'   => true,
      'default_value' => urgency,
      'values'=> values  
      }  
    list_values.each { |key, value| $evm.object[key] = value } 
  end  
rescue => err
  log(:error, "[#{err}]\n#{err.backtrace.join("\n")}")
  exit MIQ_STOP
end

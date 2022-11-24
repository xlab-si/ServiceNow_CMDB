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

log(:info, "--------------------****-------------")
log(:info, $evm.root['vmdb_object_type'])
log(:info, "--------------------****-------------")

obj_type = $evm.root['vmdb_object_type']

  list_values = {    
    'required'   => true,    
    'protected'  => false,    
    'read_only'  => true,    
    'value'=> obj_type
    }  
list_values.each do |key, value|    
  $evm.object[key] = value
end  

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
obj_name = $evm.root[obj_type].name

log(:info, "--------------------*^^^^^***-------------#{obj_name}")

  list_values = {    
    'required'   => true,    
    'protected'  => false,    
    'read_only'  => true,    
    'value'=> obj_name
    }  
list_values.each do |key, value|    
  $evm.object[key] = value
end  

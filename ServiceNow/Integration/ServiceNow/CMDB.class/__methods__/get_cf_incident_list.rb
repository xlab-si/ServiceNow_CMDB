#
# Description: Get ServiceNow CMDB Record
#

require 'rest-client'
require 'json'
require 'base64'

def log(level, message)
  method = '-----Get Cloudform Incidents List - get_cf_incident_list -----'
  $evm.log(level, "#{method} - #{message}")
end

begin
  
  this_go = $evm.root['generic_object']

  if (this_go != nil)
    values = {} 
    values[this_go.name]  = this_go.name
    list_values = {
      'sort_by'    => :value,
      'data_type'  => :string,
      'required'   => true,
      'read_only'  => true,
      'values'=> values  
      }  
    list_values.each { |key, value| $evm.object[key] = value } 
  else
      go_class = $evm.vmdb(:generic_object_definition).find_by_name("Servicenow_Incident")
      log(:info, " GO CLASS ID ---- #{go_class.id}")  
      go_list = $evm.vmdb(:generic_object).where(:generic_object_definition_id => go_class.id)  
      values = {} 
      go_list.each do |go|
        values[go.name] = go.name
      end
      list_values = {
        'sort_by'    => :value,
        'data_type'  => :string,'required'   => true,
        'values'=> values  
        }  
      list_values.each { |key, value| $evm.object[key] = value }  
  end
rescue => err
  log(:error, "[#{err}]\n#{err.backtrace.join("\n")}")
  exit MIQ_STOP
end

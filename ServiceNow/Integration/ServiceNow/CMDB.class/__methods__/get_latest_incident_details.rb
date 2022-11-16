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

  # Added for generic catalogue item scenario
  incident_number = $evm.root['dialog_refresh_snow_incident_list_incidents']
  this_go = $evm.vmdb('generic_object').find_by_name("#{incident_number}")
  if (this_go != nil)
    sys_id = this_go.attributes['properties']['sys_id']
    uri = "#{uri}/#{sys_id}"
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
    log(:info, "sys_id => <#{result['sys_id']}>")
    log(:info, "urge => <#{result['urgency']}>")
    incident_state_int = result['state']
    if (incident_state_int == "1")
      incident_state = "New"
    elsif (incident_state_int == "2")
       incident_state = "In Progress"
    elsif (incident_state_int == "3")
       incident_state = "On Hold"
    elsif (incident_state_int == "6")
       incident_state = "Resolved"
    elsif (incident_state_int == "7")
       incident_state = "Closed"
    elsif (incident_state_int == "8")
       incident_state = "Cancelled"
    else
       incident_state = result['state']
    end
    this_go.attributes = {
      						state: "#{incident_state}", 
                            urgency: "#{result['urgency']}", 
                            short_description: "#{result['short_description']}",
      						#assignment_group: "#{result['assignment_group']}",
      						created_by: "#{result['sys_created_by']}"
                         }
    this_go.save!
    #urgency_dropdown = $evm.root['service_template_provision_task'].options[:dialog][:dialog_option_0_view_update_snow_incident_urgency]
    #urgency_dropdown["default_value"] = "INC0010314"
    current_ticket_details = "Type: #{this_go.ci_type}\nCurrent State:  #{this_go.state}\nUrgency: #{this_go.urgency}\nCreated By: #{this_go.created_by}\nAssignment Group: #{this_go.assignment_group}\nDescription: #{this_go.short_description}\n"
    list_values = { 
         'required'   => true,    
         'protected'  => false,    
         'read_only'  => true,    
         'value'=> current_ticket_details
      }  
      list_values.each do |key, value|   
          $evm.object[key] = value
     end
  end 
rescue => err
  log(:error, "[#{err}]\n#{err.backtrace.join("\n")}")
  exit MIQ_STOP
end

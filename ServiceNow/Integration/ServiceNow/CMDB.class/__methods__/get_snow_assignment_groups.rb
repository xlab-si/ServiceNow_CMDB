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
 
  snow_server   = $evm.object['snow_server']
  snow_user     = $evm.object['snow_user']
  snow_password = $evm.object.decrypt('snow_password')
  table_name    = $evm.object['table_name']
  uri           = "https://#{snow_server}/api/now/table/#{table_name}?active=true"

  headers = {
    :content_type  => 'application/json',
    :accept        => 'application/json',
    :authorization => "Basic #{Base64.strict_encode64("#{snow_user}:#{snow_password}")}"
  }

  # Added for generic catalogue item scenario
 
  #if (this_go != nil)
    uri = "#{uri}"
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
  
   log(:info, "result => #{result}") 
  
  	assignment_groups = {}
  	result.each do |grp|
      name =  grp["name"]
      #log(:info, "Grp name  <#{name}>")
      assignment_groups[name] = name
    end

    log(:info, "assignment_groups => <#{assignment_groups}>")
    list_values = {
      'sort_by'    => :value,
      'data_type'  => :string,'required'   => true,
      'values'=> assignment_groups  
      }  
    list_values.each { |key, value| $evm.object[key] = value }  
rescue => err
  log(:error, "[#{err}]\n#{err.backtrace.join("\n")}")
  exit MIQ_STOP
end

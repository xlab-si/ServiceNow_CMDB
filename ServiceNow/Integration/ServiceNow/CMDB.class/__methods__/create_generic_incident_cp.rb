#
# Description: Create ServiceNow CMDB Record
#

require 'rest-client'
require 'json'
require 'base64'

def log(level, message)
  method = '----- Create ServiceNow CMDB Record -----'
  $evm.log(level, "#{method} - #{message}")
end

log(:info, "Create ServiceNow CMDB Record Sreedeep")

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

    ci_type 	  =  $evm.root['dialog_create_generic_snow_incident_ci_type']
    urgency 	  =  $evm.root['dialog_create_generic_snow_incident_urgency']
    comments	  =  $evm.root['dialog_create_generic_snow_incident_comments']
    description =  "#{ci_type}: #{$evm.root['dialog_create_generic_snow_incident_short_description']}"
    virtual     =  $evm.object['virtual']     || true
	  assignment_grp = $evm.root['dialog_create_generic_snow_incident_assignment_group']
	  sys_created_by = "#{snow_user}"

    payload = {
      :virtual           => virtual,
      :short_description => description,
      :urgency			 => urgency,
      :comments			 => comments,
      :assignment_group  => assignment_grp,
      :sys_created_by	 => sys_created_by,
      :u_qs_reported_by		 => sys_created_by,
      :company => "KPI_IAAS",
      :business_service => "CaaS-Shared",
 		  :u_qs_type => "Incident"
    }

    log(:info, "uri   => #{uri}")
    log(:info, "payload => #{payload}")

    RestClient.proxy = $evm.object['proxy_url'] unless $evm.object['proxy_url'].nil?
    request = RestClient::Request.new(
      :method  => :post,
      :url     => uri,
      :headers => headers,
      :payload => payload.to_json
    )
    rest_result = request.execute
    log(:info, "Return code <#{rest_result.code}>")

    json_parse = JSON.parse(rest_result)
    result = json_parse['result']
    log(:info, "sys_id => <#{result['sys_id']}>")

    # Add sys_id to VM object
    # Add to the generic object class by creating an Instance
    go_class = $evm.vmdb(:generic_object_definition).find_by_name("Servicenow_Incident")

	  new_go = go_class.create_object(
                  :name => "#{result['number']}",
     						  :ci_name => ci_type,
                	:urgency => $evm.root['dialog_create_generic_snow_incident_urgency'],
                  :short_description => "#{ci_type} - #{$evm.root['dialog_create_generic_snow_incident_short_description']}",
    						  :comments => "#{$evm.root['dialog_create_generic_snow_incident_comments']}",
                  :ci_type => ci_type,
                  :sys_id => "#{result['sys_id']}",
                  :number => "#{result['number']}",
                  :assignment_group => "#{assignment_grp}",
                  :created_by 	=> "#{sys_created_by}"
                 )



    new_go.save!
    new_go.add_to_service($evm.root['service'])
    $evm.root['service'].name = "Servicenow Incident: #{result['number']}"


# --- Useful References below ----Delete when not used
# # Grab the VM object
# log(:info, "vmdb_object_type => <#{$evm.root['vmdb_object_type']}>")
# case $evm.root['vmdb_object_type']
# when 'miq_provision'
#   prov = $evm.root['miq_provision']
#   vm   = prov.vm unless prov.nil?
# when 'service_template_provision_task'
#   # Added for generic catalogue item scenario
#   ci_type = $evm.root['dialog_create_generic_snow_incident_ci_type']
#   log(:info,"ci type  => <#{$evm.root['dialog_create_generic_snow_incident_ci_type']}>")
#   if(ci_type == "vm")
#     ci_name = $evm.root['dialog_create_generic_snow_incident_ci_name']
#     vm      = $evm.vmdb('vm').find_by_name(ci_name)
#     @object = $evm.vmdb(:vm).find_by_name(ci_name)
#   elsif (ci_type == "host")
#     @object = $evm.vmdb(:host).find_by_name(ci_name)
#   end
# else
#   log(:info, "Its a general ticket")
#     #vm      = $evm.vmdb('vm').find_by_name("demo")
#     #@object = $evm.vmdb(:vm).find_by_name("demo")
#   #vm = $evm.root['vm']
# end
#exit MIQ_STOP unless @object

# log(:warn, 'No Current Object selected. Its a general ticket') if @object.nil?
# # ci_type 	= $evm.root['dialog_create_generic_snow_incident_ci_type']
# # comments	= $evm.root['dialog_create_generic_snow_incident_comments']
#
# if(ci_type == "vm")
#     # Extend payload attributes as required
#     virtual     = $evm.object['virtual']     || true
#     name        = $evm.object['name']        || vm.name
#     #description = $evm.object['description'] || "CloudForms GUID <#{vm.guid}>"
#     description = "#{ci_type} - #{name} - #{$evm.root['dialog_create_generic_snow_incident_short_description']}"
#     urgency 	= $evm.root['dialog_create_generic_snow_incident_urgency']
#     host_name   = $evm.object['host_name']   || hostname(vm)
#     cpu_count   = $evm.object['cpu_count']   || get_virtual_column_value(vm, :num_cpu)
#     memory      = $evm.object['memory']      || get_virtual_column_value(vm, :mem_cpu)
#     vendor      = $evm.object['vendor']      || vm.vendor
#     comments	= "#{$evm.root['dialog_create_generic_snow_incident_comments']}"
#     #ci_type = $evm.root['dialog_create_generic_snow_incident_ci_type']
#     ci_name = $evm.root['dialog_create_generic_snow_incident_ci_name']
#
#   payload = {
#     :virtual           => virtual,
#     :name              => name,
#     :short_description => description,
#     :host_name         => host_name,
#     :cpu_count         => cpu_count,
#     :ram               => memory,
#     :vendor            => vendor,
#     :urgency			 => urgency,
#     :comments			 => comments
#   }
#   log(:info, "uri   => #{uri}")
#   log(:info, "payload => #{payload}")
# else
#     virtual     = $evm.object['virtual']     || true
#     name        = $evm.root['dialog_create_generic_snow_incident_ci_name']
#     description = "#{ci_type}:#{name}: #{$evm.root['dialog_create_generic_snow_incident_short_description']}"
#     urgency 	= $evm.root['dialog_create_generic_snow_incident_urgency']
#     comments	= "#{$evm.root['dialog_create_generic_snow_incident_comments']}"
#     #ci_type = $evm.root['dialog_create_generic_snow_incident_ci_type']
#     #ci_name = $evm.root['dialog_create_generic_snow_incident_ci_name']
#
#   payload = {
#     :virtual           => virtual,
#     :name              => name,
#     :short_description => description,
#     :urgency			 => urgency,
#     :comments			 => comments
#   }
#     log(:info, "uri   => #{uri}")
#   	log(:info, "payload => #{payload}")
# end


#vm.custom_set(:servicenow_sys_id, result['sys_id'])

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

def get_virtual_column_value(vm, virtual_column_name)
  virtual_column_value = vm.send(virtual_column_name)
  return virtual_column_value unless virtual_column_value.nil?
  nil
end

def get_serialnumber(vm)
  serial_number = nil
  case vm.vendor
  when 'vmware'
    # converts vmware bios (i.e. "4231c89f-0b98-41c8-3f92-a11576c13db5") to a proper serial number
    # "VMware-42 31 c8 9f 0b 98 41 c8-3f 92 a1 15 76 c1 3d b5"
    bios = (vm.hardware.bios rescue nil)
    return nil if bios.nil?
    bios1 = bios[0, 18].gsub(/-/, '').scan(/\w\w/).join(" ")
    bios2 = bios[19, bios.length].gsub(/-/, '').scan(/\w\w/).join(" ")
    serial_number = "VMware-#{bios1}-#{bios2}"
    log(:info, "converted bios: #{bios} to serial_number: #{serial_number}")
  end
  return serial_number
end

def get_operatingsystem(vm)
  	vm.try(:operating_system).try(:product_name) ||
    vm.try(:hardware).try(:guest_os_full_name) ||
    vm.try(:hardware).try(:guest_os) || 'unknown'
end

def get_diskspace(vm)
  diskspace = vm.allocated_disk_storage
  return nil if diskspace.nil?
  return diskspace / 1024**3
end

def get_ipaddress(vm)
  ip = vm.ipaddresses.first
  ip.blank? ? (return vm.hardware.ipaddresses.first || nil) : (return ip)
end

def get_comments(vm)
  comments =  "Name: #{vm.name}\n"
  comments += "Vendor: #{vm.vendor}\n"
  comments += "CPU Count: #{vm.num_cpu}\n"
  comments += "RAM: #{vm.mem_cpu}\n"
  comments += "Hostname: #{hostname(vm)}\n"
  comments += "Serial Number: #{get_serialnumber(vm)}\n"
  comments += "OS:  #{get_operatingsystem(vm)}\n"
  comments += "OS Version: #{get_operatingsystem(vm)}\n"
  comments += "Disk Space: #{get_diskspace(vm)}\n"
  comments += "IP Address: #{get_ipaddress(vm)}\n"
  comments += "CloudForms: #{$evm.root['miq_server'].name}\n"
  comments += "Tags: #{vm.tags.inspect}\n"
end

def build_payload(vm)
  body_hash = {
    :virtual            => true,
    :name               => vm.name,
    :cpu_count          => vm.num_cpu,
    :ram                => vm.mem_cpu,
    :host_name          => hostname,
    :serial_number      => get_serialnumber(vm),
    :os                 => get_operatingsystem(vm),
    :os_version         => get_operatingsystem(vm),
    :disk_space         => get_diskspace(vm),
    :ip_address         => get_ipaddress(vm),
    :cpu_core_count     => (vm.hardware.cpu_total_cores rescue nil),
    :vendor             => vm.vendor
  }
  log(:info, "pre compact body_hash: #{body_hash}")
  # ServiceNow does not like nil values using compact to remove them
  return body_hash.compact
end

def create
  log(:info, "testing testing testing")
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
log(:info, "vmdb_object_type => <#{$evm.root['vmdb_object_type']}>")
case $evm.root['vmdb_object_type']
when 'vm', 'miq_provision'
  prov = $evm.root['miq_provision']
  vm = @task.try(:destination) || $evm.root['vm']
  @object = @task.try(:destination) || $evm.root['vm']
when 'service_template_provision_task'
  # Added for generic catalogue item scenario
  ci_type = $evm.root['dialog_create_generic_snow_incident_ci_type']
  log(:info,"ci type  => <#{$evm.root['dialog_create_generic_snow_incident_ci_type']}>")
  if(ci_type == "vm")
    ci_name = $evm.root['dialog_create_generic_snow_incident_ci_name']
    vm      = $evm.vmdb('vm').find_by_name(ci_name)
    @object = $evm.vmdb(:vm).find_by_name(ci_name)
  elsif (ci_type == "host")
    @object = $evm.vmdb(:host).find_by_name(ci_name)
  end
else
  log(:info, "Its a general ticket")
end

#exit MIQ_STOP unless @object

log(:warn, 'No Current Object selected. Its a general ticket') if @object.nil?
ci_type 	= $evm.root['dialog_create_generic_snow_incident_ci_type']
comments	= $evm.root['dialog_create_generic_snow_incident_comments']
assignment_group	= $evm.root['dialog_create_generic_snow_incident_assignment_group']

if(ci_type == "vm")
    # Extend payload attributes as required
    virtual     = $evm.object['virtual']     || true
    name        = $evm.object['name']        || vm.name
    #description = $evm.object['description'] || "CloudForms GUID <#{vm.guid}>"
    description = "#{ci_type} - #{name} - #{$evm.root['dialog_create_generic_snow_incident_short_description']}"
    urgency 	= $evm.root['dialog_create_generic_snow_incident_urgency']
    host_name   = $evm.object['host_name']   || hostname(vm)
    cpu_count   = $evm.object['cpu_count']   || get_virtual_column_value(vm, :num_cpu)
    memory      = $evm.object['memory']      || get_virtual_column_value(vm, :mem_cpu)
    vendor      = $evm.object['vendor']      || vm.vendor
    comments	= "#{$evm.root['dialog_create_generic_snow_incident_comments']}"
    #ci_type = $evm.root['dialog_create_generic_snow_incident_ci_type']
    ci_name = $evm.root['dialog_create_generic_snow_incident_ci_name']

  payload = {
    :virtual           => virtual,
    :name              => name,
    :short_description => description,
    :host_name         => host_name,
    :cpu_count         => cpu_count,
    :ram               => memory,
    :vendor            => vendor,
    :urgency		   => urgency,
    :comments		   => comments,
    :assignment_group   => assignment_group
  }
  log(:info, "uri   => #{uri}")
  log(:info, "payload => #{payload}")
else
    virtual     = $evm.object['virtual']     || true
    name        = $evm.root['dialog_create_generic_snow_incident_ci_name']
    description = "#{ci_type}:#{name}: #{$evm.root['dialog_create_generic_snow_incident_short_description']}"
    urgency 	= $evm.root['dialog_create_generic_snow_incident_urgency']
    comments	= "#{$evm.root['dialog_create_generic_snow_incident_comments']}"
    #ci_type = $evm.root['dialog_create_generic_snow_incident_ci_type']
    #ci_name = $evm.root['dialog_create_generic_snow_incident_ci_name']

  payload = {
    :virtual           	 => virtual,
    :name             	 => name,
    :short_description	 => description,
    :urgency			 => urgency,
    :comments			 => comments,
    :assignment_group  	 => assignment_group
  }
    log(:info, "uri   => #{uri}")
  	log(:info, "payload => #{payload}")
end

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

go_class = $evm.vmdb(:generic_object_definition).find_by_name("Servicenow_Incident")
new_go = go_class.create_object(:name => "#{result['number']}",
  						 :ci_name => ci_name,
  					 	 :state => "#{result['state']}",
                         :urgency => $evm.root['dialog_create_generic_snow_incident_urgency'],
                         :short_description => "#{name} - #{$evm.root['dialog_create_generic_snow_incident_short_description']}",
						 :comments => "#{$evm.root['dialog_create_generic_snow_incident_comments']}",
  						 :ci_type => ci_type,
  						 :sys_id => "#{result['sys_id']}",
                         :number => "#{result['number']}",
                         :assignment_group => assignment_group,
                         :created_by  => "#{snow_user}"
						)


new_go.save!
new_go.add_to_service($evm.root['service']) unless $evm.root['service'].nil?
$evm.root['service'].name = "Servicenow Incident: #{result['number']}" unless $evm.root['service'].nil?

obj_type = $evm.root['vmdb_object_type']
obj_name = $evm.root[obj_type]

existing_incidents = obj_name.custom_get(:SERVICENOW_INCIDENTS)
current_incident =  "#{result['number']}"
all_incidents = "#{existing_incidents}, #{current_incident}"
obj_name.custom_set(:SERVICENOW_INCIDENTS, all_incidents)

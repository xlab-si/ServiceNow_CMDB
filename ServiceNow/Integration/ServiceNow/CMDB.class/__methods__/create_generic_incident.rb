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

log(:info, "Create ServiceNow CMDB Record bjarne")


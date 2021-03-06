# === Class: logicmonitor::host
#
# This class flags nodes which should be added to monitoring in a LogicMonitor portal. In addition to flagging the node,
# it also sets how the node will appear in the portal with regards to display name, associated host groups, alerting and
# properties.
#
# === Parameters
#
# [*collector*]
#    Required
#    Sets which collector will be handling the data for this device. Accepts a fully qualified domain name. A collector
#    with the associated fully qualified domain name must exist in the Settings -> Collectors tab of the LogicMonitor
#    Portal.
#
# [*hostname*]
#    Defaults to the fully qualified domain name of the node. Provides the default host name and display name values for
#    the LogicMonitor portal. Can be overwritten by the $display_name and $ip_address parameters.
#
# [*display_name*]
#    Defaults to the value of $host_name. Set the display name that this node will appear within the LogicMonitor portal.
#
# [*description*]
#    Defaults to "". Set the host description shown in the LogicMonitor Portal.
#
# [*disable_alerting*]
#    Defaults to false. Set whether alerts will be sent for the host. Note that if a parent group is set to
#    disable_alerting=true, alerts for child devices will be turned off as well.
#
# [*groups*]
#    Must be an Array of group names. E.g. groups => ["/puppetlabs", "/puppetlabs/puppetdb"] Default to empty. Set
#    the list of groups this host belongs to. If left empty will add at the global level. To add to a subgroup, the
#    full path name must be specified.
#
# [*properties*]
#    Must be a Hash of property names and associated values. E.g. {"mysql.user" => "youthere", "mysql.port" => 1234}
#    Defaults to empty Set custom properties at the host level.
#
#  === Examples
#
#  class {'logicmonitor::device':
#          collector => "qa1.domain.com",
#          hostname => "10.171.117.9",
#          groups => ["/puppetlabs", "/puppetlabs/puppetdb"],
#          properties => {"snmp.community" => "puppetlabs"},
#          description => "This is an instance for this deployment",
#        }
#
#  class {'logicmonitor::device':
#          collector => $fqdn,
#          display_name => "MySQL Production Host 1",
#          groups => ["/puppet", "/production", "/mysql"],
#          properties => {"mysql.port" => 1234},
#        }
#
# === Authors
#
# Sam Dacanay <sam.dacanay@logicmonitor.com>
# Ethan Culler-Mayeno <ethan.culler-mayeno@logicmonitor.com>
#
# Copyright 2016 LogicMonitor, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
#     You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
#     WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#     See the License for the specific language governing permissions and
#         limitations under the License.
#

class logicmonitor::device(
  $collector        = $::fqdn,
  $hostname         = $::fqdn,
  $display_name     = $::fqdn,
  $description      = '',
  $disable_alerting = false,
  $groups           = [],
  $properties       = {},
) inherits logicmonitor {
  # Validation
  validate_string($description)
  validate_bool($disable_alerting)
  validate_array($groups)
  validate_hash($properties)

  # Create Resource
  @@device { $hostname:
    ensure           => present,
    collector        => $collector,
    display_name     => $display_name,
    description      => $description,
    disable_alerting => $disable_alerting,
    groups           => $groups,
    properties       => $properties,
  }
}

# === Define: collector
#
# Manage your LogicMontior collectors. (Server side)
# This resource type allows the collector provider to create a collector in your LogicMonitor account. The created collector is associated with the current device by way of the fqdn
# Sets the server side information required for the creation of an installer binary.
#
# === Parameters
#
# [*namevar*]
#   Or "description"
#   Sets the description of the collector in your LogicMonitor Account.
#   Must be unique, and preferred usage is the node's fully-qualified domain name.
#
# [*osfam*]
#   Set the family of the current device. Currently supported families are Debian, Redhat, and Amazon kernels
#   Support for Windows, and other *nix systems coming soon.
#
# [*account*]
#   LogicMonitor account. Required for API access.
#
# NOTE ON AUTHENTICATION: The LogicMonitor puppet module requires user api token access ID and key for authentication to
# our API. We no longer support Basic Authentication. It is recommended to use Hiera to abstract your API token credentials.
#
# [*access_id*]
#   LogicMonitor user API Token Access ID. Required for API access.
#
# [*access_key*]
#   LogicMonitor user API Token Access Key. Required for API Access.
#
# [*user*]
#   LogicMonitor user name. Required for API access.
#
# [*password*]
#   LogicMonitor password. Required for API access.
#
#
# === Examples
#
#   include logicmonitor::collector
#
# === Authors
#
# Sam Dacanay <sam.dacanay@logicmonitor.com>
# Ethan Culler-Mayeno <ethan.culler-mayeno@logicmonitor.com>
#
# === Copyright
#
# Copyright 2016 LogicMonitor, Inc
#

Puppet::Type.newtype(:collector) do
  @doc = 'Manage a LogicMonitor Collector'

  ensurable

  newparam(:description) do
    isnamevar
    desc 'This is the name property. This is the collector description. Should be unique and tied to the host'
  end

  newparam(:osfam) do
    desc 'The operating system of the system to run a collector. Supported Distros: Debian, Redhat, and Amazon. Coming soon: Windows '
    valid_list = ['redhat', 'centos', 'debian', 'ubuntu', 'amazon']
    validate do |value|
      unless valid_list.include?(value.downcase)
        raise ArgumentError, '%s is not a valid distribution for a collector. Please install on a Debian, Redhat, or Amazon operating system' % value
      end
    end
  end

  newparam(:account) do
    desc 'This is the LogicMonitor account name'
    validate do |value|
      if value.nil? || value.empty?
        raise ArgumentError, 'account may not be nil or empty'
      end
    end
  end

  newparam(:access_id) do
    desc 'This is a LogicMonitor user\'s API Token Access ID.'
  end

  newparam(:access_key) do
    desc 'This is a LogicMonitor user\'s API Token Access Key.'
  end

  newparam(:user) do
    desc 'This is the LogicMonitor username'
  end

  newparam(:password) do
    desc 'This is the password for the LogicMonitor user specified'
  end
end

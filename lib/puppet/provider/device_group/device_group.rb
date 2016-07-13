# device_group.rb
# === Authors
#
# Sam Dacanay <sam.dacanay@logicmonitor.com>
# Ethan Culler-Mayeno <ethan.culler-mayeno@logicmonitor.com>
#
# === Copyright
#
# Copyright 2016 LogicMonitor, Inc
#
require 'json'
require 'open-uri'
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'logicmonitor'))

Puppet::Type.type(:device_group).provide(:device_group, :parent => Puppet::Provider::Logicmonitor) do
  desc 'This provider handles the creation, status, and deletion of device groups'

  # Prefetch device instances. All device resources will use the same HTTPS connection
  def self.prefetch(instances)
    accounts = []
    @connections = {}
    instances.each do |name,resource|
      accounts.push(resource[:account])
    end
    accounts.uniq!
    accounts.each do |account|
      @connections[account] = start_connection "#{account}.logicmonitor.com"
    end
  end

  # Start a new HTTPS Connection for an account
  def self.start_connection(host)
    @connection_created_at = Time.now
    @connection = Net::HTTP.new(host, 443)
    @connection.use_ssl = true
    @connection.verify_mode = OpenSSL::SSL::VERIFY_NONE
    @connection.start
  end

  # Retrieve an existing HTTPS Connection for an account
  def self.get_connection(account)
    @connections[account]
  end

  # Creates a Device Group based on parameters
  def create
    debug "Creating device group: \"#{resource[:full_path]}\""
    connection = self.class.get_connection(resource[:account])
    recursive_group_create(connection,
                           resource[:full_path],
                           resource[:description],
                           resource[:properties],
                           resource[:disable_alerting])
  end

  # Deletes a Device Group
  def destroy
    debug("Deleting device group: \"#{resource[:full_path]}\"")
    connection = self.class.get_connection(resource[:account])
    device_group = get_device_group(connection, resource[:full_path], 'id')
    if device_group
      delete_device_group = rest(connection,
                                 Puppet::Provider::Logicmonitor::DEVICE_GROUP_ENDPOINT % device_group['id'],
                                 Puppet::Provider::Logicmonitor::HTTP_DELETE)
      valid_api_response?(delete_device_group) ? nil : alert(delete_device_group)
    end
  end

  # Verifies the existence of a device group
  def exists?
    debug "Checking if device group \"#{resource[:full_path]}\" exists"
    connection = self.class.get_connection(resource[:account])
    if resource[:full_path].eql?('/')
      true
    else
      device_group = get_device_group(connection, resource[:full_path])
      debug device_group unless nil_or_empty?(device_group)
      nil_or_empty?(device_group) ? false : true
    end
  end

  # Retrieve Device Group Description
  def description
    debug "Checking description for device group: \"#{resource[:full_path]}\""
    connection = self.class.get_connection(resource[:account])
    get_device_group(connection, resource[:full_path],'description')['description']
  end

  # Update Device Group Description
  def description=(value)
    debug "Updating description on device group: \"#{resource[:full_path]}\""
    connection = self.class.get_connection(resource[:account])
    update_device_group(connection,
                        resource[:full_path],
                        value,
                        resource[:properties],
                        resource[:disable_alerting])
  end

  # Get disable_alerting status of Device Group
  def disable_alerting
    debug "Checking disable_alerting setting for device group: \"#{resource[:full_path]}\""
    connection = self.class.get_connection(resource[:account])
    get_device_group(connection, resource[:full_path],'disableAlerting')['disableAlerting'].to_s
  end

  # Update disable_alerting status of Device Group
  def disable_alerting=(value)
    debug "Updating disable_alerting setting for device group: \"#{resource[:full_path]}\""
    connection = self.class.get_connection(resource[:account])
    update_device_group(connection,
                        resource[:full_path],
                        resource[:description],
                        resource[:properties],
                        value)
  end

  # Retrieve Properties for device group (including password properties)
  def properties
    debug "Checking properties for device group: \"#{resource[:full_path]}\""
    connection = self.class.get_connection(resource[:account])
    properties = Hash.new
    device_group = get_device_group(connection, resource[:full_path], 'id')
    if device_group
      device_group_properties = rest(connection,
                                     Puppet::Provider::Logicmonitor::DEVICE_GROUP_PROPERTIES_ENDPOINT % device_group['id'],
                                     Puppet::Provider::Logicmonitor::HTTP_GET,
                                     build_query_params('type:custom,name!:system.categories,name!:puppet.update.on',
                                                        'name,value'))
      if valid_api_response?(device_group_properties, true)
        device_group_properties['data']['items'].each do |property|
          name = property['name']
          value = property['value']
          if value.include?('********') && resource[:properties].has_key?(name)
            debug 'Found password property. Verifying'
            verify_device_group_property = rest(connection,
                                                Puppet::Provider::Logicmonitor::DEVICE_GROUP_PROPERTIES_ENDPOINT % device_group['id'],
                                                Puppet::Provider::Logicmonitor::HTTP_GET,
                                                build_query_params("type:custom,name:#{name},value:#{value}", nil, 1))
            if valid_api_response?(verify_device_group_property)
              debug 'Property unchanged'
              value = resource[:properties][name]
            else
              debug 'Property changed'
            end
          end
          properties[name] = value
        end
      else
        alert device_group_properties
      end
    else
      alert device_group
    end
    properties
  end

  # Update properties for a Device Group
  def properties=(value)
    debug "Updating properties for device group: \"#{resource[:full_path]}\""
    connection = self.class.get_connection(resource[:account])
    update_device_group(connection,
                        resource[:full_path],
                        resource[:description],
                        value,
                        resource[:disable_alerting])
  end

  # Helper method for updating a Device Group via HTTP PATCH
  def update_device_group(connection, fullpath, description, properties, disable_alerting)
    device_group = get_device_group(connection, fullpath, 'id,parentId')
    device_group_hash = build_group_json(fullpath,
                                         description,
                                         properties,
                                         disable_alerting,
                                         device_group['parentId'])
    update_device_group = rest(connection,
                               Puppet::Provider::Logicmonitor::DEVICE_GROUP_ENDPOINT % device_group['id'],
                               Puppet::Provider::Logicmonitor::HTTP_PATCH,
                               build_query_params(nil, nil, -1, device_group_hash.keys),
                               device_group_hash.to_json)
    valid_api_response?(update_device_group) ? debug(update_device_group) : alert(update_device_group)
  end
end

require 'lib/api/virtualserver/VirtualServerDriver.rb'

#
# VirtualServerService
#
# This class provides a facade for SOAP method calls to the
# ZXTM Virtual Server web service.
class VirtualServerService
  
  attr_accessor :driver
  
  def initialize(endpoint=nil, username=nil, password=nil)
    @driver = VirtualServerPort.new(endpoint)
    @driver.options["protocol.http.ssl_config.verify_mode"] = OpenSSL::SSL::VERIFY_NONE
    @driver.options["protocol.http.basic_auth"] << [endpoint, username, password]
  end

  # Returns a list of virtual servers
  #
  # Args
  #   status            - Symbol (possible values: :all, :enabled, :disabled)
  #
  # Examples
  #   names(:all)       - Returns all virtual server names (default)
  #   names(:enabled)   - Returns enabled virtual server names
  #   names(:disabled)  - Returns disabled virtual server names
  #
  def list(status=nil)
    result = []
    valid_status = [:all, :enabled, :disabled]
    status = :all if status.nil? or !valid_status.include?(status)

    vs_names = @driver.getVirtualServerNames
    return vs_names if status == :all

    enabled_vs = @driver.getEnabled(vs_names)

    case status
    when :enabled
      vs_names.length.times do |i|
        result << vs_names[i] if enabled_vs[i]
      end      
    when :disabled
      vs_names.length.times do |i|
        result << vs_names[i] unless enabled_vs[i]
      end
    end

    return result
  end

  # Creates new virtual server
  #
  # Args
  #   name (String)          - Virtual server's name
  #   vs_info (Hash)         - Virtual server's properties
  #
  # Examples
  #   create("web")          - Creates new virtual server called "web" with default properties
  #   create("web", {:port => "80", :protocol => "http", :default_pool => "web-pool"})
  #
  def create(name=nil, vs_info={})
    default_port = "80"
    default_protocol = "http"
    default_pool = "discard"

    vs_basic_info = VirtualServerBasicInfo.new
    vs_basic_info.port = vs_info[:port] || default_port
    vs_basic_info.protocol = vs_info[:protocol] || default_protocol
    vs_basic_info.default_pool = vs_info[:default_pool] || default_pool

    @driver.addVirtualServer([name], [vs_basic_info])
  end

  # Enables a virtual server
  #
  # Args
  #   name (String)          - Virtual server's name to enable
  #
  # Examples
  #   enable("web")          - Enables a virtual server called "web"
  #
  def enable(vs_name=nil)
    @driver.setEnabled([vs_name], [true])
  end

  # Disables a virtual server
  #
  # Args
  #   name (String)          - Virtual server's name to disable
  #
  # Examples
  #   disable("web")         - Disables a virtual server called "web"
  #
  def disable(vs_name=nil)
    @driver.setEnabled([vs_name], [false])
  end
  
  # Adds a request rule (and enables it)
  #
  # Args
  #   name (String)          - Virtual server's name
  #   rule (String)          - Rule name
  #
  # Examples
  #   add_request_rule("test", "some-rule")
  #  
  def add_request_rule(vs_name, rule)
    vsr = VirtualServerRule.new
    vsr.name = rule
    vsr.enabled = true
    @driver.addRules([vs_name],[[vsr]])
  end  

  # Removes a request rule
  #
  # Args
  #   name (String)          - Virtual server's name
  #   rule (String)          - Rule name
  #
  # Examples
  #   remove_request_rule("test", "some-rule")
  #  
  def remove_request_rule(vs_name, rule)
    @driver.removeRules([vs_name], [[rule]])
  end

  # Adds a response rule (and enables it)
  #
  # Args
  #   name (String)          - Virtual server's name
  #   rule (String)          - Rule name
  #
  # Examples
  #   add_request_rule("test", "some-rule")
  #    
  def add_response_rule(vs_name, rule)
    vsr = VirtualServerRule.new
    vsr.name = rule
    vsr.enabled = true
    @driver.addResponseRules([vs_name], [[vsr]])
  end
  
  # Removes a response rule
  #
  # Args
  #   name (String)          - Virtual server's name
  #   rule (String)          - Rule name
  #
  # Examples
  #   remove_response_rule("test", "some-rule")
  #  
  def remove_response_rule(vs_name, rule)
    @driver.removeResponseRules([vs_name], [[rule]])
  end

end
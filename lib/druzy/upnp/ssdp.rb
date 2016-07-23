require_relative 'upnp_device'
require_relative 'version'

require 'socket'
require 'timeout'

module Druzy
  module Upnp
    
    class Ssdp
      @@port = 1900
      @@host = "239.255.255.250"
      
      def initialize
        
      end
      
      #search only device (not service)
      def search(st = "ssdp:all", delay = 10)
        message = <<-MESSAGE
M-SEARCH * HTTP/1.1\r
HOST: #{@@host}:#{@@port}\r
MAN: "ssdp:discover"\r
MX: #{delay}\r
ST: #{st}\r
USER-AGENT: #{RbConfig::CONFIG["host_os"]}/ UPnP/1.1 ruby-druzy-upnp/#{Druzy::Upnp::VERSION}\r
        MESSAGE
        
        s = UDPSocket.new
        s.send(message,0,@@host,@@port)
        devices = []
        begin
          Timeout::timeout(delay) do
            loop do
              message = s.recv(4196)
              location = message.split("\n").reject{|line| line==nil || line["LOCATION"]==nil}.first
              location = location[location.index(" ")+1..location.size-2]
              if !devices.include?(location)
                devices << location
                if block_given?
                  yield UpnpDevice.new(:location => location)
                end
              end
            end
          end
        rescue
          
        ensure
          s.close
        end
        
      end
      
    end
    
  end
end

if $0 == __FILE__
  Druzy::Upnp::Ssdp.new.search("urn:schemas-upnp-org:device:MediaRenderer:1") do |device|
    puts device.device_type
    device.service_list.each do |service|
      puts service.service_type
      service.subscribe do |event|
        puts event.property_name+" : "+event.new_value
      end
    end
  end
  
  sleep 600
end
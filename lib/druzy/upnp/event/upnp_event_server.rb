require 'druzy/server/one_instance_by_port'
require 'druzy/utils/net'
require 'nokogiri'
require 'webrick'

module Druzy
  module Upnp
    module Event

      class UpnpEventServer < Druzy::Server::OneInstanceByPort
        attr_reader :event_address
                
        def initialize(port)
          super(port)
          
          #sleep 0.5
          @server.mount('/event',UpnpServlet, :event_server => self)
          @listeners = {}
          @event_address = "http://"+Druzy::Utils.get_local_public_ipv4+":"+@server.config[:Port].to_s+"/event"
          start_server
        end
        
        def add_property_change_listener(uuid,listener)
          @listeners[uuid] ||= []              
          @listeners[uuid] << listener
        end
        
        def remove_property_change_listener(uuid)
          @listeners.delete(uuid)
        end
        
        def get_listeners(uuid)
          if @listeners[uuid]!=nil
            return @listeners[uuid]
          else
            return []
          end
        end
      
      end
      
      class UpnpServlet < WEBrick::HTTPServlet::AbstractServlet
        
        def do_NOTIFY(request, response)
          @options=@options[0]
          xml = Nokogiri::XML(request.body)
          xml.remove_namespaces!
          #puts xml.to_s
          xml.xpath('propertyset/property').each do |el|
            el.children.each do |child|
              if child.name.to_s == "LastChange"
                child.xpath('Event/InstanceID').each do |el2|
                  el2.children.each do |child2|
                    @options[:event_server].get_listeners(request['SID']).each do |listener|
                      listener.property_change(Druzy::MVC::PropertyChangeEvent.new(request.remote_ip,child2.name.to_s,nil,child2.attribute("val")))
                    end
                  end
                end
              else
                @options[:event_server].get_listeners(request['SID']).each do |listener|
                  listener.property_change(Druzy::MVC::PropertyChangeEvent.new(request.remote_ip,child.name.to_s,nil,child.text))
                end
              end      
            end
          end
  
          response.status = 200
        end
      end 
    end
  end
end

if $0 == __FILE__
  Druzy::Server::Event::UpnpEventServer.instance(12345)
  Thread.list.each {|t| t.join if t!=Thread.main}
end
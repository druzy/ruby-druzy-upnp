require_relative 'event/upnp_event_server'

require 'druzy/mvc/event'
require 'druzy/utils/net'
require 'net/http'
require 'nokogiri'
require 'socket'
require 'uri'

module Druzy
  module Upnp
    class UpnpService
      
      @@event_port = 15323
      
      attr_reader :service_type, :service_id, :location, :control_url, :event_sub_url
      
      def initialize(args)
                  
        @service_type = args[:service_type]
        @service_id = args[:service_id]
        @location = args[:location]
        @control_url = args[:control_url]
        @event_sub_url = args[:event_sub_url]
        @event_timeout = 300
        @event_sid = nil
        
        uri = URI(@location)
        xml=Net::HTTP.get(uri)
        xml_nok = Nokogiri::XML(xml)
        xml_nok.remove_namespaces!
        xml_nok.xpath('scpd/actionList/action').to_a.each do |el|
          
          action_name = el.xpath('name').text
          define_singleton_method(action_name.to_sym) do |arguments={}|
            message = <<-MESSAGE
<?xml version="1.0"?>
<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
<s:Body>
  <u:#{action_name} xmlns:u="#{@service_type}">
            MESSAGE
            
            arguments.each do |cle, valeur|
              message.concat <<-MESSAGE
    <#{cle.to_s}>#{valeur.to_s}</#{cle.to_s}>
              MESSAGE
            end
            
            message.concat <<-MESSAGE
  </u:#{action_name}>
</s:Body>
</s:Envelope>            
            MESSAGE
            
            header = {
              "HOST" => uri.host.to_s+':'+uri.port.to_s,
              "CONTENT-LENGTH" => message.size.to_s,
              "CONTENT-TYPE" => 'text/xml; charset="utf-8"',
              "SOAPACTION" => @service_type.to_s+"#"+action_name.to_s
            }            
            
            http = Net::HTTP.new(uri.host,uri.port)
            request = Net::HTTP::Post.new(uri.request_uri,header)
            request.body = message
            response = http.request(request)
            xml = Nokogiri.XML(response.body)
            xml.remove_namespaces!

            result = {}
            xml.xpath("Envelope/Body/"+action_name.to_s+"Response").children.each do |child|
              result[child.name.to_s] = child.text
            end
            
            return result
          end

        end
        
      end
      
      def subscribe
        if block_given?
          server = Druzy::Upnp::Event::UpnpEventServer.instance(@@event_port)
          uri = URI(@event_sub_url)
          http = Net::HTTP.new(uri.host,uri.port)
          request = Net::HTTPGenericRequest.new('SUBSCRIBE',false,true,uri)
          request['CALLBACK'] = '<'+server.event_address+'>'
          request['NT'] = 'upnp:event'
          request['TIMEOUT'] = 'Second-'+@event_timeout.to_s
          
          response = http.request(request)
          if response.code.to_i == 200
            @event_timeout = response['TIMEOUT'][7..-1].to_i
            @event_sid = response['SID']
                      
            Thread.new do
              puts "début thread renew"
              sleep @event_timeout
              if @event_sid !=nil
                renew_subscription
              end
            end
                      
            server.add_property_change_listener(@event_sid, Druzy::MVC::PropertyChangeListener.new do |event|
              yield(event)
            end)
            return @event_sid
          else
            return nil
          end
        else 
          return nil
        end
      end
      
      def renew_subscription
        uri = URI(@event_sub_url)
        http = Net::HTTP.new(uri.host,uri.port)
        request = Net::HTTPGenericRequest.new('SUBSCRIBE',false,true,uri)
        request['SID'] = @event_sid
        request['TIMEOUT'] = 'Second-'+@event_timeout.to_s
        
        response = http.request(request)
        if response.code.to_i == 200
          @event_timeout = response['TIMEOUT'][7..-1].to_i

          Thread.new do
            sleep @event_timeout
            if @event_sid !=nil
              renew_subscription
            end
          end
        end
      end
      
      def unsubscribe
        if @event_sid !=nil
          server = Druzy::Upnp::Event::UpnpEventServer.instance(@@event_port)
          server.remove_property_change_listener(@event_sid)
          
          uri = URI(@event_sub_url)
          http = Net::HTTP.new(uri.host,uri.port)
          request = Net::HTTPGenericRequest.new('UNSUBSCRIBE',false,true,nil)
          request['SID'] = @event_sid
          
          response = http.request(request)
          if response.code == 200
            @event_sid = nil
            return true
          else
            return false
          end
        else
          return true
        end
      end
      
    end
  end
end
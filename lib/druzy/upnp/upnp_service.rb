require 'net/http'
require 'nokogiri'
require 'uri'

module Druzy
  module Upnp
    class UpnpService
      
      attr_reader :service_type, :service_id, :location, :control_url, :event_sub_url
      
      def initialize(args)
                  
        @service_type = args[:service_type]
        @service_id = args[:service_id]
        @location = args[:location]
        @control_url = args[:control_url]
        @event_sub_url = args[:event_sub_url]
        
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
            puts "avant hash"
            xml.xpath("Envelope/Body/"+action_name.to_s+"Response").children.each do |child|
              result[child.name.to_s] = child.text
            end
            
            return result
          end

        end
        
      end
    end
  end
end
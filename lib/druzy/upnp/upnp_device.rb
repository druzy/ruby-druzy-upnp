require_relative 'upnp_service'

require 'net/http'
require 'nokogiri'

module Druzy
  module Upnp
    
    class UpnpDevice
    
      attr_reader :url_base, :device_type, :friendly_name, :manufacturer, :manufacturer_url, :model_description
      attr_reader :model_name, :model_number, :model_url, :serial_number, :udn, :upc, :icon_list, :service_list
      attr_reader :device_list
    
      def initialize(args)
        
        if args[:ssdp_message] != nil
          
          mess = args[:ssdp_message]
          location=mess.split("\n").reject{|line| line==nil || line["LOCATION"]==nil}.first
          initialize(:location => location[location.index(" ")+1..location.size-2])
        
        elsif args[:location] != nil

          uri = URI(args[:location])
          xml=Net::HTTP.get(uri)
          xml_nok = Nokogiri::XML(xml)
          xml_nok.remove_namespaces!
          initialize(:uri => uri, :xml => Nokogiri::XML(xml_nok.xpath('root/device').to_s))
          
        else
          
          uri = args[:uri]
          xml_nok = args[:xml]
          #puts xml_nok
          @url_base = uri.scheme+'://'+uri.host+":"+uri.port.to_s
          @device_type = xml_nok.xpath('device/deviceType').text
          @friendly_name = xml_nok.xpath('device/friendlyName').text
          @manufacturer = xml_nok.xpath('device/manufacturer').text
          @manufacturer_url = xml_nok.xpath('device/manufacturerURL').text
          @model_description = xml_nok.xpath('device/modelDescription').text
          @model_name = xml_nok.xpath('device/modelName').text
          @model_number = xml_nok.xpath('device/modelNumber').text
          @model_url = xml_nok.xpath('device/modelURL').text
          @serial_number = xml_nok.xpath('device/serialNumber').text
          @udn = xml_nok.xpath('device/UDN').text
          @upc = xml_nok.xpath('device/UPC').text
          @icon_list = xml_nok.xpath('device/iconList/icon/url').to_a.collect{|el| @url_base+el.text}
          @service_list = xml_nok.xpath('device/serviceList/service').to_a.collect{|el| UpnpService.new(
            :service_type => el.xpath("serviceType").text,
            :service_id => el.xpath("serviceId").text,
            :location => @url_base+el.xpath("SCPDURL").text,
            :control_url => @url_base+el.xpath("controlURL").text,
            :event_sub_url => @url_base+el.xpath("eventSubURL").text
          )}
          @service_list.each do |service|
            method_name = service.service_id[service.service_id.rindex(':')+1..-1]
            define_singleton_method(method_name.to_sym) do
              return service
            end
          end
          
          @device_list = xml_nok.xpath('device/deviceList/device').to_a.collect{|el|
            UpnpDevice.new(
            :uri => uri,
            :xml => Nokogiri::XML(el.to_s)
          )}

        end
      end
    end
  end
end
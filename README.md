# Druzy::Upnp

This is a upnp control point. You can search and interact with any upnp device or service and use event

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'druzy-upnp'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install druzy-upnp

Or for ubuntu run:

    $ sudo add-apt-repository ppa:druzy_druzy/rubymita
    $ sudo apt-get update
    $ sudo apt-get install ruby-druzy-upnp

## Usage

This is an exemple

```ruby
require 'druzy/upnp/ssdp'

Druzy::Upnp::Ssdp.new.search("urn:schemas-upnp-org:device:MediaRenderer:1") do |device|
  puts device.device_type
  connection_id, av_transport_id, rcs_id = device.ConnectionManager.PrepareForConnection("RemoteProtocolInfo" => "http-get:*:video/mp4:*", "PeerConnectionManager" => "/", "PeerConnectionID" => -1, "Direction" => "Output").values
  puts av_transport_id.to_s
end
```

For all device

```ruby
Druzy::Upnp::Ssdp.new.search do |device|
    puts device.friendly_name
end
```

Event

```ruby
service.subscribe do |event|
    puts event.property_name+" : "+event.new_value
end

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/druzy/ruby-druzy-upnp.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).


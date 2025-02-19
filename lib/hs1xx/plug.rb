require 'socket'
require 'base64'
require 'json'

module HS1xx
  class Plug

    def initialize(ip_address)
      @ip_address = ip_address
    end

    def on
      send_to_plug(:system => {:set_relay_state => {:state => 1}})
    end

    def off
      send_to_plug(:system => {:set_relay_state => {:state => 0}})
    end

    def on?
      data = send_to_plug(:system => {:get_sysinfo => {}})
      data['system']['get_sysinfo']['relay_state'] == 1
    end

    def off?
      !on?
    end

    def led_off
      send_to_plug(:system => {:set_led_off => {:off => 1}})
    end

    def led_on
      send_to_plug(:system => {:set_led_off => {:off => 0}})
    end

    def emeter
      data = send_to_plug({:emeter => {:get_realtime =>{}}})
      return data['emeter']['get_realtime']
    end

    def info
      data = send_to_plug({:system => {:get_sysinfo => :null}})
      return data['system']['get_sysinfo']
    end

    private

    def send_to_plug(payload)
      payload = payload.to_json
      socket = TCPSocket.new(@ip_address, 9999, 0)
      socket.write(encrypt(payload))
      socket.close_write()
      data = decrypt(socket.read)
      socket.close
      return data
    end

    def encrypt(payload)
      output = []
      key = 0xAB
      payload.bytes do |b|
        output << (b ^ key)
        key = (b ^ key)
      end
      a = [output.size, *output]
      a.pack('NC*')
    end

    def decrypt(payload)
      key = 0xAB
      array = []
      payload.bytes[4..-1].each do |b, i|
        array << (b ^ key)
        key = b
      end
      result = array.pack('C*')
      JSON.parse(result)
    end
  end
end

# encoding: UTF-8

=begin
{
    "type"    : String
    "payload" : Payload
}
=end

$DispatchA935A252 = []

class Dispatch

    # Dispatch::callback(lambda(type: String, payload: Payload))
    def self.callback(l)
        $DispatchA935A252 << l
    end

    # Dispatch::send(message)
    def self.send(message)
        raise "efa83aac-ff5c-4ee6-b6a5-0abdbb0b603a: #{message}" if message["type"].nil?
        raise "77dc1aee-2745-43b8-abe6-9266586d8ea7: #{message}" if message["payload"].nil?
        $DispatchA935A252.each{|l|
            l.call(message["type"], message["payload"])
        }
    end
end

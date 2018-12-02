#!/usr/bin/ruby

# encoding: UTF-8
require "/Galaxy/Software/Misc-Common/Ruby-Libraries/LucilleCore.rb"
require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(4) #=> "eb693123"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"
require 'digest/sha1'
# Digest::SHA1.hexdigest 'foo'
# Digest::SHA1.file(myFile).hexdigest
require 'json'

# -------------------------------------------------------------------------------------

ONE_LINERS_DATA_FILEPATH = "/Galaxy/DataBank/Catalyst/Agents-Data/OneLiners/data.json"

=begin
OneLiner {
    "uuid"     : String, UUID
    "unixtime" : Integer
    "line"     : String
}
=end

class NSXAgentOneLiners

    # NSXAgentOneLiners::agentuuid()
    def self.agentuuid()
        "ef7253ae-f890-4342-a1da-81ac8dbdb344"
    end

    # NSXAgentOneLiners::getData()
    def self.getData() # Array[OneLiner]
        JSON.parse(IO.read(ONE_LINERS_DATA_FILEPATH))
    end

    # NSXAgentOneLiners::putDataToDisk(dataset)
    def self.putDataToDisk(dataset)
        File.open(ONE_LINERS_DATA_FILEPATH, "w"){|f| f.puts(JSON.pretty_generate(dataset)) }
    end

    # NSXAgentOneLiners::removeItemFromData(dataset, liner)
    def self.removeItemFromData(dataset, liner)
        dataset.reject{|l| l["uuid"]==liner["uuid"] }
    end

    # NSXAgentOneLiners::linerToCatalystObject(liner)
    def self.linerToCatalystObject(liner)
        uuid = Digest::SHA1.hexdigest("d13674f7-ada4-4b57-b15b-de697cea63a3:#{liner["uuid"]}")
        {
            "uuid"               => uuid,
            "agent-uid"          => self.agentuuid(),
            "metric"             => 0.98 + NSXMiscUtils::traceToMetricShift(uuid),
            "announce"           => "liner: #{liner["line"]}",
            "commands"           => ["done"],
            "default-expression" => "done",
            "is-running"         => false,
            "liner"              => liner
        }
    end

    def self.getObjects()
        NSXAgentOneLiners::getData().map{|liner| NSXAgentOneLiners::linerToCatalystObject(liner) }
    end

    def self.processObjectAndCommand(object, command)
        if command == "done" then
            liner = object["liner"]
            NSXAgentOneLiners::putDataToDisk(NSXAgentOneLiners::removeItemFromData(NSXAgentOneLiners::getData(), liner))
        end
    end

    # NSXAgentOneLiners::interface()
    def self.interface()

    end

    # NSXAgentOneLiners::issueLiner(line)
    def self.issueLiner(line)
        liner = {}
        liner["uuid"] = SecureRandom.hex
        liner["unixtime"] = Time.new.to_i
        liner["line"] = line
        NSXAgentOneLiners::putDataToDisk( NSXAgentOneLiners::getData() + [liner] )
    end

end
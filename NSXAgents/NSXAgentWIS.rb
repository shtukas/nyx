#!/usr/bin/ruby

# encoding: UTF-8
require "net/http"
require "uri"
require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(4) #=> "eb693123"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"
require "/Galaxy/Software/Misc-Common/Ruby-Libraries/LucilleCore.rb"
require "time"

# -------------------------------------------------------------------------------------

# NSXAgentWIS::getObjects()

class NSXAgentWIS

    # NSXAgentWIS::agentuuid()
    def self.agentuuid()
        "3397e320-6c09-423d-ac58-2aea5f85eacb"
    end

    def self.getObjects()
        return []
        object =
            {
                "uuid"      => "ad127a50",
                "agentuid"  => self.agentuuid(),
                "metric"    => 1, # NSXAgentsDataKeyValueStore::getOrNull(NSXAgentWIS::agentuuid(), "60b1fea5-4c62-46e8-8567-8884383e9e69:#{Time.now.utc.iso8601[0,10]}").nil? ? 0.82 : 0,
                "announce"  => "wis",
                "commands"  => [],
                "defaultExpression" => "8ec2da5f-a46b-428b-9484-046232aa116d"
            }
        [object]
    end

    def self.processObjectAndCommand(object, command)
        # This needs to be checked if reactivated.
        if command == "8ec2da5f-a46b-428b-9484-046232aa116d" then
            uri = URI.parse(IO.read("#{CATALYST_COMMON_DATABANK_CATALYST_FOLDERPATH}/Agents-Data/wis/board-url").strip)
            response = Net::HTTP.get_response(uri)
            response.body
                .lines
                .select{|line| line.strip.start_with?(IO.read("#{CATALYST_COMMON_DATABANK_CATALYST_FOLDERPATH}/Agents-Data/wis/line-test").strip) }
                .map{|line| line.strip.encode('utf-8', :invalid => :replace, :undef => :replace, :replace => '_') }
                .each{|line|
                    #if NSXAgentsDataKeyValueStore::getOrNull(NSXAgentWIS::agentuuid(), "fb243cf9-04df-43c5-a8f5-dbec9e58da28:#{line}").nil? then
                    #    url = line[26, 999]
                    #    url = url[0, url.index('"')]
                    #    puts url
                    #    #NSXMiscUtils::waveInsertNewItemDefaults(url)
                    #    #NSXAgentsDataKeyValueStore::set(NSXAgentWIS::agentuuid(), "fb243cf9-04df-43c5-a8f5-dbec9e58da28:#{line}", "done") 
                    #end
                }
            #NSXAgentsDataKeyValueStore::set(NSXAgentWIS::agentuuid(), "60b1fea5-4c62-46e8-8567-8884383e9e69:#{Time.now.utc.iso8601[0,10]}", "done")
            LucilleCore::pressEnterToContinue()
        end
    end

    def self.interface()

    end

end


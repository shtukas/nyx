#!/usr/bin/ruby

# encoding: UTF-8
require "net/http"
require "uri"
require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(4) #=> "eb693123"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"
require "/Galaxy/local-resources/Ruby-Libraries/LucilleCore.rb"
require_relative "Bob.rb"
# -------------------------------------------------------------------------------------

Bob::registerAgent(
    {
        "agent-name"      => "WIS",
        "agent-uid"       => "3397e320-6c09-423d-ac58-2aea5f85eacb",
        "general-upgrade" => lambda { AgentWIS::generalFlockUpgrade() },
        "object-command-processor" => lambda{ |object, command| AgentWIS::processObjectAndCommand(object, command) }
    }
)

# AgentWIS::generalFlockUpgrade()

class AgentWIS
    def self.agentuuid()
        "3397e320-6c09-423d-ac58-2aea5f85eacb"
    end

    def self.generalFlockUpgrade()
        TheFlock::removeObjectsFromAgent(self.agentuuid())
        return
        object =
            {
                "uuid"      => "ad127a50",
                "agent-uid" => self.agentuuid(),
                "metric"    => FKVStore::getOrNull("60b1fea5-4c62-46e8-8567-8884383e9e69:#{Time.new.to_s[0,10]}").nil? ? 1 : 0,
                "announce"  => "wis",
                "commands"  => [],
                "default-expression" => "8ec2da5f-a46b-428b-9484-046232aa116d"
            }
        TheFlock::addOrUpdateObject(object)
    end

    def self.processObjectAndCommand(object, command)
        if command == "8ec2da5f-a46b-428b-9484-046232aa116d" then
            uri = URI.parse(IO.read("/Galaxy/DataBank/Catalyst/Agents-Data/wis/board-url").strip)
            response = Net::HTTP.get_response(uri)
            response.body
                .lines
                .select{|line| line.strip.start_with?(IO.read("/Galaxy/DataBank/Catalyst/Agents-Data/wis/line-test").strip) }
                .map{|line| line.strip.encode('utf-8', :invalid => :replace, :undef => :replace, :replace => '_') }
                .each{|line|
                    if FKVStore::getOrNull("fb243cf9-04df-43c5-a8f5-dbec9e58da28:#{line}").nil? then
                        url = line[26, 999]
                        url = url[0, url.index('"')]
                        puts url
                        CommonsUtils::waveInsertNewItemDefaults(url)
                        FKVStore::set("fb243cf9-04df-43c5-a8f5-dbec9e58da28:#{line}", "done") 
                    end
                }
            FKVStore::set("60b1fea5-4c62-46e8-8567-8884383e9e69:#{Time.new.to_s[0,10]}", "done")
            LucilleCore::pressEnterToContinue()
        end 
    end
end


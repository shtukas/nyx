#!/usr/bin/ruby

# encoding: UTF-8

require_relative "TimeCommitments.rb"

require "/Galaxy/local-resources/Ruby-Libraries/KeyValueStore.rb"
=begin
    KeyValueStore::set(repositorypath or nil, key, value)
    KeyValueStore::getOrNull(repositorypath or nil, key)
    KeyValueStore::getOrDefaultValue(repositorypath or nil, key, defaultValue)
    KeyValueStore::destroy(repositorypath or nil, key)
=end

require "/Galaxy/local-resources/Ruby-Libraries/LucilleCore.rb"

require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(4) #=> "eb693123"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"

require "/Galaxy/local-resources/Ruby-Libraries/FIFOQueue.rb"
=begin
    # The set of values that we support is whatever that can be json serialisable.
    FIFOQueue::values(repositorylocation or nil, queueuuid)
    FIFOQueue::push(repositorylocation or nil, queueuuid, value)
    FIFOQueue::getFirstOrNull(repositorylocation or nil, queueuuid)
    FIFOQueue::takeFirstOrNull(repositorylocation or nil, queueuuid)
=end

require 'digest/sha1'
# Digest::SHA1.hexdigest 'foo'
# Digest::SHA1.file(myFile).hexdigest

# -------------------------------------------------------------------------------------

# XLaniakea::getCatalystObjects()

class XLaniakea

    def self.importData()
        datafilepath = "/Galaxy/DataBank/Catalyst/x-laniakea-genesis.json"
        data = JSON.parse(IO.read(datafilepath))
        data = data.zip((0..10000)).map{|pair|
            item = pair[0]
            indx = pair[1]
            item.delete("buttons")
            item.delete("run-command")
            item.delete("source:name")
            item["uuid"] = Digest::SHA1.hexdigest(item["uuid"])[0,8]
            item["metric"] = 0.201 + 0.3*Math.exp(-indx.to_f/100)
            puts JSON.pretty_generate(item)
            FIFOQueue::push(nil, "2477F469-6A18-4CAF-838A-E05703585A28", item)
        }
        [] 
    end

    def self.shouldIgnore(item)
        return true if item["announce"].include?("http://putlocker")
        return true if item["announce"].include?("haskell-programming-v0.7.0.pdf")
        return true if item["announce"].include?("Problems in Mathematical Analysis")
        return true if item["announce"].include?("learn you a haskell for great good")
        return true if item["announce"].include?("real world haskell")
        return true if item["announce"].include?("Data-Islands/Mathematics")
        return true if item["announce"].include?("1.Education/3.Undergraduate")
        false
    end

    # XLaniakea::processAnnounce(announce)
    def self.processAnnounce(announce)
        if (indx = announce.index("}")) then
            return XLaniakea::processAnnounce(announce[indx+1,announce.size].strip)
        end
        if (announce[0,2]=="[]") then
            return XLaniakea::processAnnounce(announce[2,announce.size].strip)
        end
        if (announce[0,4]=="url:") then
            return XLaniakea::processAnnounce(announce[4,announce.size].strip)
        end
        if (announce[0,5]=="line:") then
            return XLaniakea::processAnnounce(announce[5,announce.size].strip)
        end
        announce
    end

    def self.getCatalystObjects()
        item = FIFOQueue::getFirstOrNull(nil, "2477F469-6A18-4CAF-838A-E05703585A28")
        if item.nil? then
            return [
                {
                    "uuid"                => "ce253dca",
                    "metric"              => 1,
                    "announce"            => "looks like x-laniakea is completed",
                    "commands"            => ["done"],
                    "command-interpreter" => lambda{ |object, command| }
                }
            ]
        end
        if XLaniakea::shouldIgnore(item) then
            puts "x-laniakea ignoring: #{item["announce"]}"
            FIFOQueue::takeFirstOrNull(nil, "2477F469-6A18-4CAF-838A-E05703585A28")
            return XLaniakea::getCatalystObjects()
        end
        while (item["metric"]+0.1)<0.5 do
            item["metric"] = item["metric"]+0.1
        end
        description = XLaniakea::processAnnounce(item["announce"])
        defaultExpression = nil
        if description.start_with?("http") then
           defaultExpression = "open done" 
        end
        item["description"] = description
        item["announce"] = "(#{"%.3f" % item["metric"]}) [#{item["uuid"]}] x-laniakea: #{description}"
        item["commands"] = ["done", ">stream"]
        item["default-expression"] = defaultExpression
        item["command-interpreter"] = lambda{ |object, command| 
            if command=="open" then
                system("open '#{object["description"]}'")
            end
            if command=="done" then
                FIFOQueue::takeFirstOrNull(nil, "2477F469-6A18-4CAF-838A-E05703585A28")
            end
            if command==">stream" then
                item = FIFOQueue::takeFirstOrNull(nil, "2477F469-6A18-4CAF-838A-E05703585A28")
                targetfolderpath = "#{CATALYST_COMMON_PATH_TO_STREAM_DOMAIN_FOLDER}/strm2/#{LucilleCore::timeStringL22()}"
                FileUtils.mkpath targetfolderpath
                File.open("#{targetfolderpath}/readme.txt", "w"){|f| f.puts(item["description"]) }
            end
        }
        [
            item
        ]

    end
end

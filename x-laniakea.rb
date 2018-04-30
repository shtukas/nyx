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
    def self.cleaning()
        item = FIFOQueue::getFirstOrNull(nil, "2477F469-6A18-4CAF-838A-E05703585A28")
        # Consume the item if irrelevant
    end
    def self.getCatalystObjects()
        XLaniakea::cleaning()
        item = FIFOQueue::getFirstOrNull(nil, "2477F469-6A18-4CAF-838A-E05703585A28")
        if item.nil? then
            [
                {
                    "uuid"                => "ce253dca",
                    "metric"              => 1,
                    "announce"            => "looks like x-laniakea is completed",
                    "commands"            => ["done"],
                    "command-interpreter" => lambda{ |object, command| }
                }
            ]
        else
            removeAnnouncePrefix1 = lambda {|announce|
                indx = announce.index("}")
                announce[indx+1,announce.size].strip
            }
            removeAnnouncePrefix2 = lambda {|announce|
                if announce[0,2]=="[]" then
                    announce[2,announce.size].strip
                else
                    announce
                end
            }
            description = item["announce"]
            description = removeAnnouncePrefix1.call(description)
            description = removeAnnouncePrefix2.call(description)
            item["description"] = description
            item["announce"] = "(#{"%.3f" % item["metric"]}) [#{item["uuid"]}] x-laniakea: #{description}"
            item["commands"] = ["done"]
            item["default-expression"] = nil
            item["command-interpreter"] = lambda{ |object, command| 
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
end

# encoding: UTF-8

# require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/DataNetwork/Tags.rb"

require 'fileutils'
# FileUtils.mkpath '/a/b/c'
# FileUtils.cp(src, dst)
# FileUtils.mv 'oldname', 'newname'
# FileUtils.rm(path_to_image)
# FileUtils.rm_rf('dir/to/remove')

require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(4) #=> "eb693123"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"

require 'colorize'

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/DataNetwork/DataNetwork.rb"

# -----------------------------------------------------------------

class Tags

    # Tags::makeTagInteractivelyOrNull()
    def self.makeTagInteractivelyOrNull()
        puts "making a new Tag:"
        payload = LucilleCore::askQuestionAnswerAsString("tag payload (empty to abort): ")
        return nil if payload.size == 0
        tag = {
            "uuid"             => SecureRandom.uuid,
            "nyxType"          => "tag-57c7eced-24a8-466d-a6fe-588142afd53b",
            "creationUnixtime" => Time.new.to_f,
            "payload"          => payload
        }
        DataNetworkCoreFunctions::commitToDisk(tag)
        puts JSON.pretty_generate(tag)
        tag
    end

    # Tags::tagToString(tag)
    def self.tagToString(tag)
        "[Tag] #{tag["payload"]}"
    end

    # Tags::getOrNull(uuid)
    def self.getOrNull(uuid)
        DataNetworkCoreFunctions::getOrNull(uuid)
    end

    # Tags::tags()
    def self.tags()
        DataNetworkCoreFunctions::objects("tag-57c7eced-24a8-466d-a6fe-588142afd53b")
            .sort{|n1, n2| n1["creationUnixtime"] <=> n2["creationUnixtime"] }
    end
end

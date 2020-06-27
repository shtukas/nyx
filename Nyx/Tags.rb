# encoding: UTF-8

# require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Nyx/Tags.rb"

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

require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Nyx/Bosons.rb"
require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Nyx/NyxDataCarriers.rb"
require "/Users/pascal/Galaxy/LucilleOS/Applications/Catalyst/Nyx/NyxIO.rb"

# -----------------------------------------------------------------

class Tags

    # Tags::issueTag(payload)
    def self.issueTag(payload)
        tag = {
            "uuid"             => SecureRandom.uuid,
            "nyxNxSet"         => "a00b82aa-c047-4497-82bf-16c7206913e4",
            "nyxType"          => "tag-57c7eced-24a8-466d-a6fe-588142afd53b",
            "creationUnixtime" => Time.new.to_f,
            "payload"          => payload
        }
        NyxSets::putObject(tag)
        tag
    end

    # Tags::issueTagInteractivelyOrNull()
    def self.issueTagInteractivelyOrNull()
        puts "making a new Tag:"
        payload = LucilleCore::askQuestionAnswerAsString("tag payload (empty to abort): ")
        return nil if payload.size == 0
        tag = Tags::issueTag(payload)
        puts JSON.pretty_generate(tag)
        tag
    end

    # Tags::tagToString(tag)
    def self.tagToString(tag)
        "[Tag] #{tag["payload"]}"
    end

    # Tags::getOrNull(uuid)
    def self.getOrNull(uuid)
        NyxSets::getObjectOrNull(uuid)
    end

    # Tags::tags()
    def self.tags()
        NyxSets::objects("a00b82aa-c047-4497-82bf-16c7206913e4")
            .sort{|n1, n2| n1["creationUnixtime"] <=> n2["creationUnixtime"] }
    end

    # Tags::getTagsByExactPayload(payload)
    def self.getTagsByExactPayload(payload)
        Tags::tags().select{|tag| tag["payload"] == payload }
    end

    # Tags::tagPayloadDive(tagPayload)
    def self.tagPayloadDive(tagPayload)
        puts "Tags::tagPayloadDive(tagPayload) is not implemented yet"
        LucilleCore::pressEnterToContinue()
    end

    # Tags::tagDive(tag)
    def self.tagDive(tag)
        puts "uuid: #{tag["uuid"]}"
        puts "Tags::tagDive(tag) is not implemented yet"
        LucilleCore::pressEnterToContinue()
    end

    # Tags::searchNx1630(pattern)
    def self.searchNx1630(pattern)
        Tags::tags()
            .select{|tag| 
                [
                    tag["uuid"].downcase.include?(pattern.downcase),
                    tag["payload"].downcase.include?(pattern.downcase)
                ].any?
            }
            .reduce([]) {|selected, tag|
                if selected.any?{|t| t["payload"] == tag["payload"] } then
                    selected << tag
                end
                selected
            }
            .map{|tag|
                {
                    "description"   => Tags::tagToString(tag),
                    "referencetime" => tag["creationUnixtime"],
                    "dive"          => lambda{ Tags::tagDive(tag) }
                }
            }
    end

end

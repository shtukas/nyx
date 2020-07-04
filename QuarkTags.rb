# encoding: UTF-8

# require_relative "QuarkTags.rb"

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

require_relative "Bosons.rb"
require_relative "NyxGenericObjectInterface.rb"

# -----------------------------------------------------------------

class QuarkTags

    # QuarkTags::issueTag(quarkuuid, payload)
    def self.issueTag(quarkuuid, payload)
        tag = {
            "uuid"             => SecureRandom.uuid,
            "nyxNxSet"         => "a00b82aa-c047-4497-82bf-16c7206913e4",
            "creationUnixtime" => Time.new.to_f,
            "quarkuuid"        => quarkuuid,
            "payload"          => payload
        }
        NyxSets::putObject(tag)
        tag
    end

    # QuarkTags::issueQuarkTagInteractivelyOrNull(quark)
    def self.issueQuarkTagInteractivelyOrNull(quark)
        payload = LucilleCore::askQuestionAnswerAsString("tag payload: ")
        return nil if payload.size == 0
        QuarkTags::issueTag(quark["uuid"], payload)
    end

    # QuarkTags::tagToString(tag)
    def self.tagToString(tag)
        "[Tag] #{tag["payload"]}"
    end

    # QuarkTags::getOrNull(uuid)
    def self.getOrNull(uuid)
        NyxSets::getObjectOrNull(uuid)
    end

    # QuarkTags::tags()
    def self.tags()
        NyxSets::objects("a00b82aa-c047-4497-82bf-16c7206913e4")
            .sort{|n1, n2| n1["creationUnixtime"] <=> n2["creationUnixtime"] }
    end

    # QuarkTags::getQuarkTagsByExactPayload(payload)
    def self.getQuarkTagsByExactPayload(payload)
        QuarkTags::tags().select{|tag| tag["payload"] == payload }
    end

    # QuarkTags::getQuarkTagsByQuarkUUID(quarkuuid)
    def self.getQuarkTagsByQuarkUUID(quarkuuid)
        QuarkTags::tags().select{|tag| tag["quarkuuid"] == quarkuuid }
    end

    # QuarkTags::tagPayloadDive(tagPayload)
    def self.tagPayloadDive(tagPayload)
        puts "QuarkTags::tagPayloadDive(tagPayload) is not implemented yet"
        LucilleCore::pressEnterToContinue()
    end

    # QuarkTags::tagDive(tag)
    def self.tagDive(tag)
        puts "uuid: #{tag["uuid"]}"
        tags = QuarkTags::getQuarkTagsByExactPayload(tag["payload"])
        quarks = tags
                    .map{|tag| Quarks::getOrNull(tag["quarkuuid"]) }
                    .compact
        loop {
            menuitems = LCoreMenuItemsNX1.new()
            quarks.each{|quark|
                menuitems.item(
                    Quarks::quarkToString(quark), 
                    lambda { Quarks::quarkDive(quark) }
                )
            }
            status = menuitems.prompt()
            break if !status
        }
    end

    # QuarkTags::searchNx1630(pattern)
    def self.searchNx1630(pattern)
        QuarkTags::tags()
            .select{|tag| 
                [
                    tag["uuid"].downcase.include?(pattern.downcase),
                    tag["payload"].downcase.include?(pattern.downcase)
                ].any?
            }
            .reduce([]) {|selected, tag|
                if selected.none?{|t| t["payload"] == tag["payload"] } then
                    selected << tag
                end
                selected
            }
            .map{|tag|
                {
                    "description"   => QuarkTags::tagToString(tag),
                    "referencetime" => tag["creationUnixtime"],
                    "dive"          => lambda{ QuarkTags::tagDive(tag) }
                }
            }
    end

end

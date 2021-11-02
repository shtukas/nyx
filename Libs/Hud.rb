# encoding: UTF-8

class Hud

    # Hud::issueNewFromDescriptionAndCoreDataId(description, coreDataId)
    def self.issueNewFromDescriptionAndCoreDataId(description, coreDataId)
        uuid = SecureRandom.uuid
        item = {
            "uuid"        => uuid,
            "unixtime"    => Time.new.to_i,
            "description" => description,
            "coreDataId"  => coreDataId
        }
        BTreeSets::set(nil, "5f8226ce-87e0-45aa-8df7-15d36ec568d9", uuid, item)
        BTreeSets::getOrNull(nil, "5f8226ce-87e0-45aa-8df7-15d36ec568d9", uuid)
    end

    # Hud::issueNewFromDescriptionAndLocation(description, location)
    def self.issueNewFromDescriptionAndLocation(description, location)
        uuid = SecureRandom.uuid
        item = {
            "uuid"        => uuid,
            "unixtime"    => Time.new.to_i,
            "description" => description,
            "coreDataId"  => CoreData::issueAionPointDataObjectUsingLocation(location)
        }
        BTreeSets::set(nil, "5f8226ce-87e0-45aa-8df7-15d36ec568d9", uuid, item)
        BTreeSets::getOrNull(nil, "5f8226ce-87e0-45aa-8df7-15d36ec568d9", uuid)
    end

    # Hud::items()
    def self.items()
        BTreeSets::values(nil, "5f8226ce-87e0-45aa-8df7-15d36ec568d9")
            .sort{|i1, i2| i1["unixtime"] <=> i2["unixtime"] }
        #{
        #    "uuid"
        #    "unixtime"
        #    "description"
        #    "coreDataId"
        #}
    end

    # Hud::toString(item)
    def self.toString(item)
        "[hud*] #{item["description"]} (#{CoreData::contentTypeOrNull(item["coreDataId"])})"
    end

    # Hud::ns16s()
    def self.ns16s()
        Hud::items().map{|item|
            {
                "uuid"     => item["uuid"],
                "unixtime" => item["unixtime"],
                "announce" => Hud::toString(item),
                "commands" => ["done"],
                "interpreter" => lambda{|command|
                    if command == "done" then
                        BTreeSets::destroy(nil, "5f8226ce-87e0-45aa-8df7-15d36ec568d9", item["uuid"])
                    end
                },
                "run"      => lambda {
                    system("clear")
                    puts Hud::toString(item).green
                    CoreData::accessWithOptionToEdit(item["coreDataId"])
                    if LucilleCore::askQuestionAnswerAsBoolean("destroy ? ") then
                        BTreeSets::destroy(nil, "5f8226ce-87e0-45aa-8df7-15d36ec568d9", item["uuid"])
                    end  
                }
            }
        }
    end

    # Hud::nx19s()
    def self.nx19s()
        []
    end
end

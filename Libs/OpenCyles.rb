# encoding: UTF-8

class OpenCyles

    # OpenCyles::issueNewFromDescriptionAndCoreDataId(description, coreDataId)
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

    # OpenCyles::issueNewFromDescriptionAndLocation(description, location)
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

    # OpenCyles::items()
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

    # OpenCyles::toString(item)
    def self.toString(item)
        "[hud*] #{item["description"]} (#{CoreData::contentTypeOrNull(item["coreDataId"])})"
    end

    # OpenCyles::ns16s()
    def self.ns16s()
        OpenCyles::items().map{|item|
            {
                "uuid"     => item["uuid"],
                "unixtime" => item["unixtime"],
                "announce" => OpenCyles::toString(item),
                "commands" => ["done"],
                "interpreter" => lambda{|command|
                    if command == "done" then
                        BTreeSets::destroy(nil, "5f8226ce-87e0-45aa-8df7-15d36ec568d9", item["uuid"])
                    end
                },
                "run"      => lambda {
                    system("clear")
                    puts OpenCyles::toString(item).green
                    CoreData::accessWithOptionToEdit(item["coreDataId"])
                    if LucilleCore::askQuestionAnswerAsBoolean("> destroy ? ") then
                        BTreeSets::destroy(nil, "5f8226ce-87e0-45aa-8df7-15d36ec568d9", item["uuid"])
                    end  
                }
            }
        }
    end

    # OpenCyles::nx19s()
    def self.nx19s()
        []
    end
end

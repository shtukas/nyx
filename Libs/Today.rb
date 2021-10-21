# encoding: UTF-8

class Today

    # Today::makeNewFromDescription(description)
    def self.makeNewFromDescription(description)
        uuid = SecureRandom.uuid
        item = {
            "uuid"        => uuid,
            "unixtime"    => Time.new.to_i,
            "description" => description,
            "coreDataId"  => CoreData::interactivelyCreateANewDataObjectReturnIdOrNull()
        }
        BTreeSets::set(nil, "b153bd30-0582-4019-963a-68b01fb4bb7c", uuid, item)
        BTreeSets::getOrNull(nil, "b153bd30-0582-4019-963a-68b01fb4bb7c", uuid)
    end

    # Today::items()
    def self.items()
        BTreeSets::values(nil, "b153bd30-0582-4019-963a-68b01fb4bb7c")
            .sort{|i1, i2| i1["unixtime"] <=> i2["unixtime"] }
        #{
        #    "uuid"
        #    "unixtime"
        #    "description"
        #    "coreDataId"
        #}
    end

    # Today::itemToString(item)
    def self.itemToString(item)
        "[today] #{item["description"]} (#{CoreData::contentTypeOrNull(item["coreDataId"])})"
    end

    # Today::ns16s()
    def self.ns16s()
        Today::items().map{|item|
            {
                "uuid"     => item["uuid"],
                "unixtime" => item["unixtime"],
                "announce" => Today::itemToString(item).gsub("[today]", "[tday]"),
                "commands" => ["done"],
                "interpreter" => lambda{|command|
                    if command == "done" then
                        BTreeSets::destroy(nil, "b153bd30-0582-4019-963a-68b01fb4bb7c", item["uuid"])
                    end
                },
                "run"      => lambda {
                    system("clear")
                    puts Today::itemToString(item)
                    CoreData::accessWithOptionToEdit(item["coreDataId"])
                    if LucilleCore::askQuestionAnswerAsBoolean("destroy ? ", true) then
                        BTreeSets::destroy(nil, "b153bd30-0582-4019-963a-68b01fb4bb7c", item["uuid"])
                    end  
                }
            }
        }
    end

    # Today::nx19s()
    def self.nx19s()
        []
    end
end

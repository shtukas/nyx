# encoding: UTF-8

class Today

    # Today::issueNewFromDescription(description, useCoreData)
    def self.issueNewFromDescription(description, useCoreData)
        uuid = SecureRandom.uuid
        item = {
            "uuid"        => uuid,
            "unixtime"    => Time.new.to_i,
            "description" => description,
            "coreDataId"  => useCoreData ? CoreData::interactivelyCreateANewDataObjectReturnIdOrNull() : nil
        }
        BTreeSets::set(nil, "b153bd30-0582-4019-963a-68b01fb4bb7c", uuid, item)
        BTreeSets::getOrNull(nil, "b153bd30-0582-4019-963a-68b01fb4bb7c", uuid)
    end

    # Today::issueNewFromDescriptionAndLocation(description, location)
    def self.issueNewFromDescriptionAndLocation(description, location)
        uuid = SecureRandom.uuid
        item = {
            "uuid"        => uuid,
            "unixtime"    => Time.new.to_i,
            "description" => description,
            "coreDataId"  => CoreData::issueAionPointDataObjectUsingLocation(location)
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
                "commands" => ["done", ">todo"],
                "interpreter" => lambda{|command|
                    if command == "done" then
                        BTreeSets::destroy(nil, "b153bd30-0582-4019-963a-68b01fb4bb7c", item["uuid"])
                    end
                    if command == ">todo" then
                        uuid2 = LucilleCore::timeStringL22()
                        domain = Domain::interactivelySelectDomain()
                        unixtime = Nx50s::interactivelyDetermineNewItemUnixtime(domain)
                        item2 = {
                            "uuid"        => uuid2,
                            "unixtime"    => unixtime,
                            "description" => item["description"],
                            "coreDataId"  => item["coreDataId"],
                            "domain"      => domain
                        }
                        Nx50s::commitNx50ToDatabase(item2)
                        item2 = Nx50s::getNx50ByUUIDOrNull(uuid2)
                        puts JSON.pretty_generate(item2)
                        BTreeSets::destroy(nil, "b153bd30-0582-4019-963a-68b01fb4bb7c", item["uuid"])
                    end
                },
                "run"      => lambda {
                    system("clear")
                    puts Today::itemToString(item).green
                    CoreData::accessWithOptionToEdit(item["coreDataId"])
                    if LucilleCore::askQuestionAnswerAsBoolean("destroy ? ") then
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

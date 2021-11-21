class Top

    # Top::ns16()
    def self.ns16()
        BTreeSets::values(nil, "213f801a-fd93-4839-a55b-8323520494bc")
            .map{|item|
                if item["ordinal"].nil? then
                    item["ordinal"] = 0
                end
                item
            }
            .sort{|i1, i2| i1["ordinal"] <=> i2["ordinal"] }
            .map{|item|
                announce = "[top ] (#{item["ordinal"]}) #{item["description"]}"
                {
                    "uuid"        => item["uuid"],
                    "announce"    => announce,
                    "commands"    => ["..", "done"],
                    "interpreter" => lambda {|command|
                        if command == "done" then
                            BTreeSets::destroy(nil, "213f801a-fd93-4839-a55b-8323520494bc", item["uuid"])
                        end
                    },
                    "start-land"  => lambda {
                        puts announce
                        if LucilleCore::askQuestionAnswerAsBoolean("done ? ") then
                            BTreeSets::destroy(nil, "213f801a-fd93-4839-a55b-8323520494bc", item["uuid"])
                        end
                    } 
                }
            }
    end

    # Top::interactivelyMakeNewTop()
    def self.interactivelyMakeNewTop()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return if description == ""
        ordinal = LucilleCore::askQuestionAnswerAsString("ordinal: ").to_f
        uuid = Time.new.to_f.to_s
        item = {
            "uuid"        => uuid,
            "ordinal"     => ordinal,
            "description" => description
        }
        BTreeSets::set(nil, "213f801a-fd93-4839-a55b-8323520494bc", uuid, item)
    end
end
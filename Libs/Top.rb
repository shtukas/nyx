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
                atom = item["atom"]
                announce = "[top ] (#{item["ordinal"]}) #{atom["description"]}"
                {
                    "uuid"        => item["uuid"],
                    "NS198"       => "ns16:top1",
                    "announce"    => announce,
                    "commands"    => ["..", "done"],
                    "item"        => item
                }
            }
    end

    # Top::interactivelyMakeNewTop()
    def self.interactivelyMakeNewTop()
        atom = CoreData2::interactivelyCreateANewAtomOrNull([])
        return if atom.nil?
        ordinal = LucilleCore::askQuestionAnswerAsString("ordinal: ").to_f
        uuid = Time.new.to_f.to_s
        item = {
            "uuid"        => uuid,
            "ordinal"     => ordinal,
            "atom"        => atom
        }
        BTreeSets::set(nil, "213f801a-fd93-4839-a55b-8323520494bc", uuid, item)
    end

    # Top::run(item)
    def self.run(item)
        atom = CoreData2::accessWithOptionToEdit(item["atom"])
        item["atom"] = atom
        BTreeSets::set(nil, "213f801a-fd93-4839-a55b-8323520494bc", item["uuid"], item)
    end
end

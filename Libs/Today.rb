# encoding: UTF-8

=begin

{
    "uuid" : String # used by DoNotShowUntil
    "description" : String
    "ordinal"     : Float
    "type"        : "description | "text"       | "coredata"            | "pointer"
    "payload"     : null         | String Text  | CoreDataContentPair | String UUID 
}

=end

class Today

    # Today::getTodayByUUIDOrNull(uuid)
    def self.getTodayByUUIDOrNull(uuid)
        BTreeSets::getOrNull(nil, "aa77ca31-eb98-4aa7-91db-9e86ab86b89f", uuid)
    end

    # Today::items()
    def self.items()
        BTreeSets::values(nil, "aa77ca31-eb98-4aa7-91db-9e86ab86b89f")
    end

    # Today::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        uuid = SecureRandom.uuid
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        ordinal = LucilleCore::askQuestionAnswerAsString("ordinal: ").to_f
        type = LucilleCore::selectEntityFromListOfEntitiesOrNull("type", ["description only (default)", "text", "coredata (not supported yet)", "pointer (not supported yet)"])
        if type.nil? or type == "description only (default)" then
            item = {
                "uuid"        => uuid,
                "description" => description,
                "ordinal"     => ordinal,
                "type"        => "description",
                "payload"     => nil
            }
            BTreeSets::set(nil, "aa77ca31-eb98-4aa7-91db-9e86ab86b89f", item["uuid"], item)
            return
        end
        if type == "text" then
            item = {
                "uuid"        => uuid,
                "description" => description,
                "ordinal"     => ordinal,
                "type"        => "text",
                "payload"     => Utils::editTextSynchronously("")
            }
            BTreeSets::set(nil, "aa77ca31-eb98-4aa7-91db-9e86ab86b89f", item["uuid"], item)
            return
        end
        raise "cf9b6604-bee2-472e-a9be-7b4e7467dbbb"
    end

    # Today::destroy(item)
    def self.destroy(item)
        BTreeSets::destroy(nil, "aa77ca31-eb98-4aa7-91db-9e86ab86b89f", item["uuid"])
    end

    # -------------------------------------
    # Operations

    # Today::toString(item)
    def self.toString(item)
        "[tday] #{"%5.2f" % item["ordinal"]} | #{item["type"]} | #{item["description"]}"
    end

    # Today::run(item)
    def self.run(item)
        if item["type"] == "description" then
            puts "description: #{item["description"]}"
            LucilleCore::pressEnterToContinue()
        end
        if item["type"] == "text"  then
            puts item["payload"]
            LucilleCore::pressEnterToContinue()
        end
    end

    # Today::itemToNS16(item)
    def self.itemToNS16(item)
        {
            "uuid"        => item["uuid"],
            "announce"    => Today::toString(item),
            "commands"    => ["..", "done"],
            "interpreter" => lambda {|command|
                if command == ".." then
                    Today::run(item)
                end
                if command == "done" then
                    if LucilleCore::askQuestionAnswerAsBoolean("done '#{Today::toString(item)}' ? ", true) then
                        Today::destroy(item)
                    end
                end
            },
            "start-land" => lambda {
                Today::run(item)
            }
        }
    end

    # Today::ns16s()
    def self.ns16s()
        Today::items()
            .sort{|i1, i2| i1["ordinal"] <=> i2["ordinal"] }
            .map{|item| Today::itemToNS16(item) }
    end
end

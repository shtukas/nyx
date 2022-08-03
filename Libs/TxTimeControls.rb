
# encoding: UTF-8

class TxTimeControls

    # ----------------------------------------------------------------------
    # IO

    # TxTimeControls::objectuuidToItemOrNull(objectuuid)
    def self.objectuuidToItemOrNull(objectuuid)
        return nil if Fx18Attributes::getOrNull(objectuuid, "mikuType") != "TxTimeControl"
        {
            "uuid"        => objectuuid,
            "mikuType"    => Fx18Attributes::getOrNull(objectuuid, "mikuType"),
            "unixtime"    => Fx18Attributes::getOrNull(objectuuid, "unixtime"),
            "datetime"    => Fx18Attributes::getOrNull(objectuuid, "datetime"),
            "description" => Fx18Attributes::getOrNull(objectuuid, "description"),
            "ax39"        => Fx18::jsonParseIfNotNull(Fx18Attributes::getOrNull(objectuuid, "ax39")),
        }
    end

    # TxTimeControls::items()
    def self.items()
        Lookup1::mikuTypeToItems("TxTimeControl")
    end

    # TxTimeControls::destroy(uuid)
    def self.destroy(uuid)
        Fx18::deleteObject(uuid)
    end

    # ----------------------------------------------------------------------
    # Objects Makers

    # TxTimeControls::interactivelyIssueNewItemOrNull() # item
    def self.interactivelyIssueNewItemOrNull()

        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""

        unixtime   = Time.new.to_i
        datetime   = Time.new.utc.iso8601

        ax39 = Ax39::interactivelyCreateNewAx()

        uuid = SecureRandom.uuid

        Fx18Attributes::set_objectMaking(uuid, "uuid",        uuid)
        Fx18Attributes::set_objectMaking(uuid, "mikuType",    "TxTimeControl")
        Fx18Attributes::set_objectMaking(uuid, "unixtime",    Time.new.to_f)
        Fx18Attributes::set_objectMaking(uuid, "datetime",    Time.new.utc.iso8601)
        Fx18Attributes::set_objectMaking(uuid, "description", description)
        Fx18Attributes::set_objectMaking(uuid, "ax39",        JSON.generate(ax39))
        FileSystemCheck::fsckObject(uuid)
        Lookup1::reconstructEntry(uuid)
        item = TxTimeControls::objectuuidToItemOrNull(uuid)
        if item.nil? then
            raise "(error: 8211abba-cbe2-44a4-8fb8-404eaf58d5c7) How did that happen ? 🤨"
        end
        item
    end

    # ----------------------------------------------------------------------
    # Data

    # TxTimeControls::toString(item)
    def self.toString(item)
        dnsustr = DoNotShowUntil::isVisible(item["uuid"]) ? "" : " (DoNotShowUntil: #{DoNotShowUntil::getDateTimeOrNull(item["uuid"])})"
        "(timecontrol) #{item["description"]} #{Ax39::toString(item)}#{dnsustr}"
    end

    # TxTimeControls::section1()
    def self.section1()
        TxTimeControls::items()
    end

    # ----------------------------------------------------------------------
    # Operations

    # TxTimeControls::landing(item)
    def self.landing(item)
        loop {

            return if item.nil?

            uuid = item["uuid"]

            item = Fx18::itemOrNull(uuid)

            return if item.nil?

            system("clear")

            puts TxTimeControls::toString(item).green

            store = ItemStore.new()

            puts "uuid: #{item["uuid"]}".yellow
            puts "unixtime: #{item["unixtime"]}".yellow

            linkeduuids  = NxLink::linkedUUIDs(uuid)

            puts "commands: description | Ax39 | json | destroy".yellow

            command = LucilleCore::askQuestionAnswerAsString("> ")

            break if command == ""

            if Interpreting::match("description", command) then
                if item["mikuType"] == "NxPerson" then
                    name1 = CommonUtils::editTextSynchronously(item["name"]).strip
                    next if name1 == ""
                    Fx18Attributes::set_objectUpdate(item["uuid"], "name", name1)
                else
                    description = CommonUtils::editTextSynchronously(item["description"]).strip
                    next if description == ""
                    Fx18Attributes::set_objectUpdate(item["uuid"], "description", description)
                end
                next
            end

            if Interpreting::match("Ax39", command) then
                ax39 = Ax39::interactivelyCreateNewAx()
                Fx18Attributes::set_objectUpdate(uuid, "ax39", JSON.generate(ax39))
            end

            if Interpreting::match("json", command) then
                puts JSON.pretty_generate(item)
                LucilleCore::pressEnterToContinue()
            end

            if Interpreting::match("destroy", command) then
                if LucilleCore::askQuestionAnswerAsBoolean("destroy item ? : ") then
                    Fx18::deleteObject(item["uuid"])
                    break
                end
            end
        }
    end
end

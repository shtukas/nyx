# encoding: UTF-8

class NxIceds

    # NxIceds::items()
    def self.items()
        TheIndex::mikuTypeToItems("NxIced")
    end

    # NxIceds::destroy(uuid)
    def self.destroy(uuid)
        DxF1::deleteObjectLogically(uuid)
    end

    # --------------------------------------------------
    # Data

    # NxIceds::toString(item)
    def self.toString(item)
        "(iced) #{item["description"]}#{Cx::uuidToString(item["nx112"])}"
    end

    # NxIceds::toStringForSearch(item)
    def self.toStringForSearch(item)
        "(iced) #{item["description"]}"
    end

    # NxIceds::landing(item, isSearchAndSelect)
    def self.landing(item, isSearchAndSelect)
        loop {

            return nil if item.nil?

            uuid = item["uuid"]

            item = TheIndex::getItemOrNull(uuid)

            return nil if item.nil?

            system("clear")

            store = ItemStore.new()

            puts NxIceds::toString(item)
            puts "uuid: #{item["uuid"]}".yellow
            puts "unixtime: #{item["unixtime"]}".yellow
            puts "datetime: #{item["datetime"]}".yellow
            puts "nx112: #{item["nx112"]}".yellow

            linkeds  = NetworkLinks::linkedEntities(uuid)

            puts "Linked entities: #{linkeds.size} items".yellow

            if linkeds.size <= 200 then
                linkeds
                    .sort{|e1, e2| e1["datetime"]<=>e2["datetime"] }
                    .first(200)
                    .each{|entity|
                        indx = store.register(entity, false)
                        puts "[#{indx.to_s.ljust(3)}] #{LxFunction::function("toString", entity)}"
                    }
            else
                puts "(... many items, use `navigation` ...)"
            end

            puts "commands: access | iam | <n> | description | datetime | line | text | nx112 | json | link | unlink | network-migration | navigation | upload | return (within search) | destroy".yellow

            command = LucilleCore::askQuestionAnswerAsString("> ")

            break if command == ""

            if (indx = Interpreting::readAsIntegerOrNull(command)) then
                entity = store.get(indx)
                next if entity.nil?
                result = Landing::landing_old(entity, isSearchAndSelect)
                if isSearchAndSelect and result then
                    return result
                end
            end

            if Interpreting::match("access", command) then
                Nx112::carrierAccess(item)
                next
            end

            if Interpreting::match("description", command) then
                description = CommonUtils::editTextSynchronously(item["description"]).strip
                next if description == ""
                DxF1::setAttribute2(item["uuid"], "description", description)
                next
            end

            if Interpreting::match("datetime", command) then
                datetime = CommonUtils::editTextSynchronously(item["datetime"]).strip
                next if !CommonUtils::isDateTime_UTC_ISO8601(datetime)
                DxF1::setAttribute2(item["uuid"], "datetime", datetime)
            end

            if Interpreting::match("iam", command) then
                puts "TODO"
                exit
            end

            if Interpreting::match("line", command) then
                l1 = NxLines::interactivelyIssueNewLineOrNull()
                next if l1.nil?
                puts JSON.pretty_generate(l1)
                NetworkLinks::link(item["uuid"], l1["uuid"])
                next
            end

            if Interpreting::match("text", command) then
                i2 = DxText::interactivelyIssueNew()
                puts JSON.pretty_generate(i2)
                NetworkLinks::link(item["uuid"], i2["uuid"])
                next
            end

            if Interpreting::match("nx112", command) then
                i2 = Cx::interactivelyCreateNewCxForOwnerOrNull(item["uuid"])
                next if i2.nil?
                puts JSON.pretty_generate(i2)
                DxF1::setAttribute2(item["uuid"], "nx112", i2["uuid"])
                next
            end

            if Interpreting::match("json", command) then
                puts JSON.pretty_generate(item)
                LucilleCore::pressEnterToContinue()
            end

            if Interpreting::match("link", command) then
                Landing::link(item)
            end

            if Interpreting::match("navigation", command) then
                LinkedNavigation::navigate(item)
            end

            if Interpreting::match("unlink", command) then
                Landing::removeConnected(item)
            end

            if Interpreting::match("network-migration", command) then
                NetworkLinks::networkMigration(item)
            end

            if Interpreting::match("upload", command) then
                Upload::interactivelyUploadToItem(item)
            end

            if Interpreting::match("return", command) then
                return item
            end

            if Interpreting::match("destroy", command) then
                if LucilleCore::askQuestionAnswerAsBoolean("destroy item ? : ") then
                    DxF1::deleteObjectLogically(item["uuid"])
                    break
                end
            end
        }
    end
end

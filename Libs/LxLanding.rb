
# encoding: UTF-8

class LxLanding

    # LxLanding::landing(item, isSearchAndSelect) # item or null
    def self.landing(item, isSearchAndSelect)

        return nil if item.nil?

        if item["mikuType"] == "TxTimeCommitmentProject" then
            return TxTimeCommitmentProjects::landing(item, isSearchAndSelect)
        end

        loop {

            return nil if item.nil?

            uuid = item["uuid"]

            item = DxF1::getProtoItemOrNull(uuid)

            return nil if item.nil?

            system("clear")

            puts LxFunction::function("toString", item)
            puts "uuid: #{item["uuid"]}".yellow
            puts "unixtime: #{item["unixtime"]}".yellow
            puts "datetime: #{item["datetime"]}".yellow
            puts "nx112: #{item["nx112"]}".yellow

            store = ItemStore.new()

            linkeds  = NetworkLinks::linkedEntities(uuid)

            if !linkeds.empty? then
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
            end

            commands = ["access", "edit", "<n>", "description", "name", "datetime", "line", "text", "nx112", "json", "link", "unlink", "network-migration", "navigation", "upload", "return (within search)", "destroy"]

            if item["mikuType"] == "NxAnniversary" then
                commands = ["description", "update start date", "destroy"]
            end

            if item["mikuType"] == "DxFile" then
                commands = ["access", "description", "json", "destroy"]
            end

            if item["mikuType"] == "DxText" then
                commands = ["access", "edit", "destroy"]
            end

            if item["mikuType"] == "NxLine" then
                commands = ["edit", "destroy"]
            end

            if item["mikuType"] == "NxPerson" then
                commands = ["name", "destroy"]
            end

            if item["mikuType"] == "TopLevel" then
                commands = ["access", "json", "destroy"]
            end

            puts "commands: #{commands.join(" | ")}"

            command = LucilleCore::askQuestionAnswerAsString("> ")

            break if command == ""

            if (indx = Interpreting::readAsIntegerOrNull(command)) then
                entity = store.get(indx)
                next if entity.nil?
                result = LxLanding::landing(entity, isSearchAndSelect)
                if isSearchAndSelect and result then
                    return result
                end
            end

            if Interpreting::match("access", command) then
                LxAccess::access(item)
                next
            end

            if Interpreting::match("name", command) then
                name1 = CommonUtils::editTextSynchronously(item["name"]).strip
                next if name1 == ""
                DxF1::setAttribute2(item["uuid"], "name", name1)
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

            if Interpreting::match("update start date", command) then
                startdate = CommonUtils::editTextSynchronously(item["startdate"])
                return if startdate == ""
                DxF1::setAttribute2(item["uuid"], "startdate",   startdate)
            end

            if Interpreting::match("edit", command) then
                item = LxEdit::edit(item)
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
                NetworkLinks::linkToArchitectured(item)
            end

            if Interpreting::match("navigation", command) then
                LinkedNavigation::navigate(item)
            end

            if Interpreting::match("unlink", command) then
                LxLanding::selectOneLinkedAndUnlink(item)
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

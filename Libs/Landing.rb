
# encoding: UTF-8

class Landing

    # Landing::removeConnected(item)
    def self.removeConnected(item)
        store = ItemStore.new()

        NetworkLinks::linkeduuids(item["uuid"]) # .sort{|e1, e2| e1["datetime"]<=>e2["datetime"] }
            .each{|entityuuid|
                entity = TheIndex::getItemOrNull(entityuuid)
                next if entity.nil?
                indx = store.register(entity, false)
                puts "[#{indx.to_s.ljust(3)}] #{LxFunction::function("toString", entity)}"
            }

        i = LucilleCore::askQuestionAnswerAsString("> remove index (empty to exit): ")

        return if i == ""

        if (indx = Interpreting::readAsIntegerOrNull(i)) then
            entity = store.get(indx)
            return if entity.nil?
            NetworkLinks::unlink(item["uuid"], entity["uuid"])
        end
    end

    # Landing::link(item)
    def self.link(item)
        newitem = Nyx::architectOneOrNull()
        return if newitem.nil?
        NetworkLinks::link(item["uuid"], newitem["uuid"])
    end

    # Landing::landing_old(item, isSearchAndSelect) # item or null
    def self.landing_old(item, isSearchAndSelect)
        if item["mikuType"] == "TxTimeCommitmentProject" then
            return TxTimeCommitmentProjects::landing(item, isSearchAndSelect)
        end
        if item["mikuType"] == "DxAionPoint" then
            return Landing::landing_new(item, isSearchAndSelect)
        end
        if item["mikuType"] == "DxFile" then
            return Landing::landing_new(item, isSearchAndSelect)
        end
        if item["mikuType"] == "DxLine" then
            return Landing::landing_new(item, isSearchAndSelect)
        end
        if item["mikuType"] == "DxText" then
            return DxText::landing(item, isSearchAndSelect)
        end
        if item["mikuType"] == "TopLevel" then
            TopLevel::access(item)
            return nil
        end
        if item["mikuType"] == "NxIced" then
            return Landing::landing_new(item, isSearchAndSelect)
        end
        if item["mikuType"] == "NxLine" then
            puts "landing:"
            puts JSON.pretty_generate(item)
            LucilleCore::pressEnterToContinue()
            return nil
        end
        if item["mikuType"] == "NxPerson" then
            return NxPersons::landing(item, isSearchAndSelect)
        end
        if item["mikuType"] == "NxEntity" then
            return NxEntities::landing(item, isSearchAndSelect)
        end
        if item["mikuType"] == "NxConcept" then
            return NxConcepts::landing(item, isSearchAndSelect)
        end
        if item["mikuType"] == "NxCollection" then
            return NxCollections::landing(item, isSearchAndSelect)
        end
        if item["mikuType"] == "NxTask" then
            NxTasks::landing(item, isSearchAndSelect)
        end
        if item["mikuType"] == "NxTimeline" then
            return NxTimelines::landing(item, isSearchAndSelect)
        end
        raise "(error: 1e84c68b-b602-41af-b2e9-00e66fa687ac) item: #{item}"
    end

    # Landing::landing_new(item, isSearchAndSelect) # item or null
    def self.landing_new(item, isSearchAndSelect)
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

            commands = ["access", "iam", "<n>", "description", "name", "datetime", "line", "text", "nx112", "json", "link", "unlink", "network-migration", "navigation", "upload", "return (within search)", "destroy"]

            if item["mikuType"] == "NxAnniversary" then
                commands = ["description", "update start date", "destroy"]
            end

            if item["mikuType"] == "DxFile" then
                commands = ["access", "description", "json", "destroy"]
            end

            puts "commands: #{commands.join(" | ")}"

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

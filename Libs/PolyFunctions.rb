
class PolyFunctions

    # PolyFunctions::_check(item, functionname)
    def self._check(item, functionname)
        if item.nil?  then
            raise "(error: d366d408-93a1-4e91-af92-c115e88c501f) null item sent to #{functionname}"
        end

        if item["mikuType"].nil? then
            puts "Objects sent to a poly function should have a mikuType attribute."
            puts "function name: #{functionname}"
            puts "item: #{JSON.pretty_generate(item)}"
            puts "Aborting."
            raise "(error: f74385d4-5ece-4eae-8a09-90d3a5e0f120)"
        end
    end

    # PolyFunctions::genericDescription(item)
    def self.genericDescription(item)
        PolyFunctions::_check(item, "PolyFunctions::genericDescription")

        if item["mikuType"] == "CxAionPoint" then
            return "#{item["mikuType"]}"
        end
        if item["mikuType"] == "CxDx8Unit" then
            return "#{item["mikuType"]}"
        end
        if item["mikuType"] == "CxFile" then
           return "#{item["mikuType"]}"
        end
        if item["mikuType"] == "CxText" then
            return "#{item["mikuType"]}"
        end
        if item["mikuType"] == "CxUniqueString" then
            return "#{item["mikuType"]}"
        end
        if item["mikuType"] == "CxUrl" then
            return "#{item["mikuType"]}"
        end
        if item["mikuType"] == "DxAionPoint" then
            return item["description"]
        end
        if item["mikuType"] == "DxFile" then
            return (item["description"] ? item["description"] : "DxFile: #{item["nhash"]}")
        end
        if item["mikuType"] == "DxLine" then
            return item["line"]
        end
        if item["mikuType"] == "DxText" then
            return item["description"]
        end
        if item["mikuType"] == "DxUniqueString" then
            return item["description"]
        end
        if item["mikuType"] == "DxUrl" then
            return item["url"]
        end
        if item["mikuType"] == "InboxItem" then
            return item["description"]
        end
        if item["mikuType"] == "NxAnniversary" then
            return item["description"]
        end
        if item["mikuType"] == "NxCollection" then
            return item["description"]
        end
        if item["mikuType"] == "NxConcept" then
            return item["description"]
        end
        if item["mikuType"] == "NxEntity" then
            return item["description"]
        end
        if item["mikuType"] == "NxEvent" then
            return item["description"]
        end
        if item["mikuType"] == "NxIced" then
            return item["description"]
        end
        if item["mikuType"] == "NxLine" then
            return item["line"]
        end
        if item["mikuType"] == "NxPerson" then
            return item["name"]
        end
        if item["mikuType"] == "NxTask" then
            return item["description"]
        end
        if item["mikuType"] == "NxTimeline" then
            return item["description"]
        end
        if item["mikuType"] == "TxFloat" then
            return item["description"]
        end
        if item["mikuType"] == "TxThread" then
            return item["description"]
        end
        if item["mikuType"] == "TxTimeCommitmentProject" then
            return item["description"]
        end
        if item["mikuType"] == "TopLevel" then
            firstline = TopLevel::getFirstLineOrNull(item)
            return (firstline ? firstline : "(no generic-description)")
        end
        if item["mikuType"] == "TxDated" then
            return item["description"]
        end
        if item["mikuType"] == "Wave" then
            return item["description"]
        end

        puts "I do not know how to PolyFunctions::genericDescription(#{JSON.pretty_generate(item)})"
        raise "(error: 475225ec-74fe-4614-8664-a99c1b2c9916)"
    end

    # PolyFunctions::toString(item)
    def self.toString(item)
        PolyFunctions::_check(item, "PolyFunctions::toString")

        if item["mikuType"] == "(rstream-to-target)" then
            return item["announce"]
        end
        if item["mikuType"] == "fitness1" then
            return item["announce"]
        end
        if item["mikuType"] == "DxAionPoint" then
            return DxAionPoint::toString(item)
        end
        if item["mikuType"] == "CxFile" then
            return CxFile::toString(item)
        end
        if item["mikuType"] == "CxText" then
            return CxText::toString(item)
        end
        if item["mikuType"] == "CxUniqueString" then
            return CxUniqueString::toString(item)
        end
        if item["mikuType"] == "CxUrl" then
            return CxUrl::toString(item)
        end
        if item["mikuType"] == "DxFile" then
            return DxFile::toString(item)
        end
        if item["mikuType"] == "DxLine" then
            return DxLine::toString(item)
        end
        if item["mikuType"] == "DxText" then
            return DxText::toString(item)
        end
        if item["mikuType"] == "DxUniqueString" then
            return DxUniqueString::toString(item)
        end
        if item["mikuType"] == "DxUrl" then
            return DxUrl::toString(item)
        end
        if item["mikuType"] == "InboxItem" then
            return InboxItems::toString(item)
        end
        if item["mikuType"] == "MxPlanning" then
            return MxPlanning::toString(item)
        end
        if item["mikuType"] == "MxPlanningDisplay" then
            return MxPlanning::displayItemToString(item)
        end
        if item["mikuType"] == "NxAnniversary" then
            return Anniversaries::toString(item)
        end
        if item["mikuType"] == "NxBall.v2" then
            return item["description"]
        end
        if item["mikuType"] == "NxCollection" then
            return NxCollections::toString(item)
        end
        if item["mikuType"] == "NxConcept" then
            return NxConcepts::toString(item)
        end
        if item["mikuType"] == "NxEntity" then
            return NxEntities::toString(item)
        end
        if item["mikuType"] == "NxEvent" then
            return NxEvents::toString(item)
        end
        if item["mikuType"] == "NxIced" then
            return NxIceds::toString(item)
        end
        if item["mikuType"] == "NxLine" then
            return NxLines::toString(item)
        end
        if item["mikuType"] == "NxPerson" then
            return NxPersons::toString(item)
        end
        if item["mikuType"] == "NxTask" then
            return NxTasks::toString(item)
        end
        if item["mikuType"] == "NxTimeline" then
            return NxTimelines::toString(item)
        end
        if item["mikuType"] == "TxFloat" then
            return TxFloats::toString(item)
        end
        if item["mikuType"] == "TxTimeCommitmentProject" then
            return TxTimeCommitmentProjects::toString(item)
        end
        if item["mikuType"] == "TopLevel" then
            return TopLevel::toString(item)
        end
        if item["mikuType"] == "TxDated" then
            return TxDateds::toString(item)
        end
        if item["mikuType"] == "Wave" then
            return Waves::toString(item)
        end

        puts "I do not know how to PolyFunctions::toString(#{JSON.pretty_generate(item)})"
        raise "(error: 820ce38d-e9db-4182-8e14-69551f58671c)"
    end

    # PolyFunctions::edit(item) # item
    def self.edit(item)

        if item["mikuType"] == "DxText" then
            text = CommonUtils::editTextSynchronously(item["text"])
            DxF1::setAttribute2(item["uuid"], "text", text)
            return DxF1::getProtoItemOrNull(item["uuid"])
        end

        if item["mikuType"] == "DxAionPoint" then
            operator = DxF1Elizabeth.new(item["uuid"], true, true)
            rootnhash = item["rootnhash"]
            parentLocation = "#{ENV['HOME']}/Desktop/DxPure-Edit-#{SecureRandom.hex(4)}"
            FileUtils.mkdir(parentLocation)
            AionCore::exportHashAtFolder(operator, rootnhash, parentLocation)
            puts "Item exported at #{parentLocation}. Continue to upload update"
            LucilleCore::pressEnterToContinue()

            location = CommonUtils::interactivelySelectDesktopLocationOrNull()
            return if location.nil?

            uuid = item["uuid"]
            operator = DxF1Elizabeth.new(uuid, true, true)
            rootnhash = AionCore::commitLocationReturnHash(operator, location)
            DxF1::setAttribute2(uuid, "rootnhash", rootnhash)
            FileSystemCheck::fsckObjectuuidErrorAtFirstFailure(uuid, SecureRandom.hex, true)

            return DxF1::getProtoItemOrNull(item["uuid"])
        end

        item
    end

    # PolyFunctions::landing(item, isSearchAndSelect) # item or null
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

            puts PolyFunctions::toString(item)
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
                            puts "[#{indx.to_s.ljust(3)}] #{PolyFunctions::toString(entity)}"
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
                commands = ["name", "line", "text", "link", "unlink", "destroy"]
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
                result = PolyFunctions::landing(entity, isSearchAndSelect)
                if isSearchAndSelect and result then
                    return result
                end
            end

            if Interpreting::match("access", command) then
                PolyActions::access(item)
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
                item = PolyFunctions::edit(item)
            end

            if Interpreting::match("line", command) then
                l1 = NxLines::interactivelyIssueNewLineOrNull()
                next if l1.nil?
                puts JSON.pretty_generate(l1)
                NetworkLinks::link(item["uuid"], l1["uuid"])
                next
            end

            if Interpreting::match("text", command) then
                i2 = DxText::interactivelyIssueNewOrNull()
                return if i2.nil?
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
                NetworkLinks::selectOneLinkedAndUnlink(item)
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

    # PolyFunctions::timeBeforeNotificationsInHours(item)
    def self.timeBeforeNotificationsInHours(item)
        if item["mikuType"] == "MxPlanning" then
            return item["timespanInHour"]
        end
        if item["mikuType"] == "MxPlanningDisplay" then
            return PolyFunctions::timeBeforeNotificationsInHours(item["item"])
        end
        1
    end

    # PolyFunctions::bankAccounts(item)
    def self.bankAccounts(item)

        decideTxTimeCommitmentProjectUUIDOrNull = lambda {|itemuuid|
            key = "bb9bf6c2-87c4-4fa1-a8eb-21c0b3c67c61:#{itemuuid}"
            uuid = XCache::getOrNull(key)
            if uuid == "null" then
                return nil
            end
            if uuid then
                return uuid
            end
            puts "This is important, pay attention. We need an owner for this item, for the account."
            LucilleCore::pressEnterToContinue()
            ox = TxTimeCommitmentProjects::interactivelySelectOneOrNull()
            if ox then
                XCache::set(key, ox["uuid"])
                SystemEvents::broadcast({
                    "mikuType" => "XCacheSet",
                    "key"      => key,
                    "value"    => ox["uuid"]
                })
                return ox["uuid"]
            else
                XCache::set(key, "null")
                SystemEvents::broadcast({
                    "mikuType" => "XCacheSet",
                    "key"      => key,
                    "value"    => "null"
                })
                return nil
            end
        }

        accounts = [item["uuid"]] # Item's own uuid

        ownersuuids = OwnerMapping::elementuuidToOwnersuuids(item["uuid"])
        if ownersuuids.size > 0 then
            accounts = accounts + ownersuuids
        else
            accounts = accounts + [decideTxTimeCommitmentProjectUUIDOrNull.call(item["uuid"])].compact
        end

        accounts
    end
end

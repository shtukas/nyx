
class PolyFunction

    # PolyFunction::_check(item, functionname)
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

    # PolyFunction::genericDescription(item)
    def self.genericDescription(item)
        PolyFunction::_check(item, "PolyFunction::genericDescription")

        if item["mikuType"] == "NxAnniversary" then
            return item["description"]
        end
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
        if item["mikuType"] == "NxFrame" then
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

        puts "I do not know how to PolyFunction::genericDescription(#{JSON.pretty_generate(item)})"
        raise "(error: 475225ec-74fe-4614-8664-a99c1b2c9916)"
    end

    # PolyFunction::toString(item)
    def self.toString(item)
        PolyFunction::_check(item, "PolyFunction::toString")

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
        if item["mikuType"] == "NxFrame" then
            return NxFrames::toString(item)
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

        puts "I do not know how to PolyFunction::toString(#{JSON.pretty_generate(item)})"
        raise "(error: 820ce38d-e9db-4182-8e14-69551f58671c)"
    end

    # PolyFunction::edit(item) # item
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

    # PolyFunction::landing(item, isSearchAndSelect) # item or null
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

            puts PolyFunction::toString(item)
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
                            puts "[#{indx.to_s.ljust(3)}] #{PolyFunction::toString(entity)}"
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
                result = PolyFunction::landing(entity, isSearchAndSelect)
                if isSearchAndSelect and result then
                    return result
                end
            end

            if Interpreting::match("access", command) then
                PolyAction::access(item)
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
                item = PolyFunction::edit(item)
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
end

class PolyAction

    # PolyAction::doubleDot(item)
    def self.doubleDot(item)

        PolyFunction::_check(item, "PolyAction::doubleDot")

        if item["mikuType"] == "fitness1" then
            PolyAction::access(item)
            return
        end

        if item["mikuType"] == "NxIced" then
            PolyAction::start(item)
            PolyAction::access(item)
            return
        end

        if item["mikuType"] == "TxDated" then
            PolyAction::start(item)
            PolyAction::access(item)
            loop {
                actions = ["keep running and back to listing", "stop and back to listing", "stop and destroy"]
                action = LucilleCore::selectEntityFromListOfEntitiesOrNull("action", actions)
                next if action.nil?
                if action == "keep running and back to listing" then
                    return
                end
                if action == "stop and back to listing" then
                    PolyAction::stop(item)
                    return
                end
                if action == "stop and destroy" then
                    PolyAction::stop(item)
                    PolyAction::destroyWithPrompt(item)
                    return
                end
            }
            return
        end

        if item["mikuType"] == "InboxItem" then
            PolyAction::start(item)
            PolyAction::access(item)
            actions = ["destroy", "transmute to task and get owner", "do not display until"]
            action = LucilleCore::selectEntityFromListOfEntitiesOrNull("action", actions)
            if action.nil? then
                PolyAction::stop(item)
                return
            end
            if action == "destroy" then
                PolyAction::stop(item)
                PolyAction::destroyWithPrompt(item)
                return
            end
            if action == "transmute to task and get owner" then
                PolyAction::stop(item)
                DxF1::setAttribute2(item["uuid"], "mikuType", "NxTask")
                item = TheIndex::getItemOrNull(item["uuid"]) # We assume it's not null
                TxTimeCommitmentProjects::interactivelyAddThisElementToOwner(item)
                return
            end
            if action == "do not display until" then
                PolyAction::stop(item)
                puts "Write it: 9a681ca6-c5ca-4839-ae1a-0ecd973d25a0"
                exit
                return
            end
            return
        end

        if item["mikuType"] == "TxTimeCommitmentProject" then
            TxTimeCommitmentProjects::doubleDot(item)
            return
        end

        if item["mikuType"] == "Wave" then
            PolyAction::start(item)
            PolyAction::access(item)
            if LucilleCore::askQuestionAnswerAsBoolean("done '#{PolyFunction::toString(item).green}' ? ") then
                Waves::performWaveNx46WaveDone(item)
                PolyAction::stop(item)
            else
                if LucilleCore::askQuestionAnswerAsBoolean("continue ? ") then
                    return
                else
                    PolyAction::stop(item)
                end
            end
            return
        end

        puts "I do not know how to PolyAction::doubleDot(#{JSON.pretty_generate(item)})"
        raise "(error: afbb56ca-90fa-47bc-972c-6681c6c58831)"
    end

    # PolyAction::done(item)
    def self.done(item)
        PolyFunction::_check(item, "PolyAction::done")

        PolyAction::stop(item)

        if item["mikuType"] == "(rstream-to-target)" then
            return
        end

        if item["mikuType"] == "InboxItem" then
            DxF1::deleteObjectLogically(item["uuid"])
            return
        end

        if item["mikuType"] == "MxPlanning" then
            if LucilleCore::askQuestionAnswerAsBoolean("'#{PolyFunction::toString(item).green}' done ? ", true) then
                MxPlanning::destroy(item["uuid"])
                if item["payload"]["type"] == "pointer" then
                    PolyAction::done(item["payload"]["item"])
                end
            end
            return
        end

        if item["mikuType"] == "MxPlanningDisplay" then
            PolyAction::done(item["item"])
            return
        end

        if item["mikuType"] == "NxAnniversary" then
            Anniversaries::done(item["uuid"])
            return
        end

        if item["mikuType"] == "NxBall.v2" then
            return
        end

        if item["mikuType"] == "NxFrame" then
            return
        end

        if item["mikuType"] == "NxIced" then
            NxIceds::destroy(item["uuid"])
            return
        end

        if item["mikuType"] == "NxTask" then
            if item["ax39"] then
                if LucilleCore::askQuestionAnswerAsBoolean("'#{PolyFunction::toString(item).green}' done for today ? ", true) then
                    DoneForToday::setDoneToday(item["uuid"])
                end
                return
            end
            if LucilleCore::askQuestionAnswerAsBoolean("destroy NxTask '#{PolyFunction::toString(item).green}' ? ") then
                DxF1::deleteObjectLogically(item["uuid"])
            end
            return
        end

        if item["mikuType"] == "NxLine" then
            if LucilleCore::askQuestionAnswerAsBoolean("destroy NxLine '#{PolyFunction::toString(item).green}' ? ", true) then
                DxF1::deleteObjectLogically(item["uuid"])
            end
            return
        end

        if item["mikuType"] == "TxDated" then
            if LucilleCore::askQuestionAnswerAsBoolean("destroy TxDated '#{item["description"].green}' ? ", true) then
                TxDateds::destroy(item["uuid"])
            end
            return
        end

        if item["mikuType"] == "TxTimeCommitmentProject" then
            return
        end

        if item["mikuType"] == "Wave" then
            if LucilleCore::askQuestionAnswerAsBoolean("done-ing '#{Waves::toString(item).green} ? '", true) then
                Waves::performWaveNx46WaveDone(item)
            end
            return
        end

        puts "I do not know how to PolyAction::done(#{JSON.pretty_generate(item)})"
        raise "(error: f278f3e4-3f49-4f79-89d2-e5d3b8f728e6)"
    end

    # PolyAction::destroyWithPrompt(item)
    def self.destroyWithPrompt(item)
        PolyFunction::_check(item, "PolyAction::destroyWithPrompt")

        PolyAction::stop(item)
        if LucilleCore::askQuestionAnswerAsBoolean("confirm destruction of #{item["mikuType"]} '#{PolyFunction::toString(item).green}' ") then
            DxF1::deleteObjectLogically(item["uuid"])
        end

        puts "I do not know how to PolyAction::destroyWithPrompt(#{JSON.pretty_generate(item)})"
        raise "(error: 6d79f9cb-7a15-4e51-a40f-a95e37cd1ddd)"
    end

    # PolyAction::landing(item)
    def self.landing(item)
        PolyFunction::_check(item, "PolyAction::landing")

        if item["mikuType"] == "fitness1" then
            system("#{Config::userHomeDirectory()}/Galaxy/Binaries/fitness doing #{item["fitness-domain"]}")
            return
        end

        if ["DxText", "NxAnniversary", "NxIced"].include?(item["mikuType"]) then
            return PolyFunction::landing(item, isSearchAndSelect)
        end

        return PolyFunction::landing(item, isSearchAndSelect = false)

        puts "I do not know how to PolyAction::landing(#{JSON.pretty_generate(item)})"
        raise "(error: 249ab52b-2eb5-4d99-904b-70994e223654)"
    end

    # PolyAction::redate(item)
    def self.redate(item)
        PolyFunction::_check(item, "PolyAction::redate")

        if item["mikuType"] == "TxDated" then
            datetime = (CommonUtils::interactivelySelectDateTimeIso8601OrNullUsingDateCode() || Time.new.utc.iso8601)
            DxF1::setAttribute2(item["uuid"], "datetime", datetime)
            return
        end

        puts "I do not know how to PolyAction::redate(#{JSON.pretty_generate(item)})"
        raise "(error: bfc8c526-b23a-4d38-bc47-40d3733b4044)"
    end

    # PolyAction::start(item)
    def self.start(item)
        PolyFunction::_check(item, "PolyAction::start")

        if item["mikuType"] == "MxPlanning" then
            if item["payload"]["type"] == "pointer" then
                PolyAction::start(item["payload"]["item"])
            end
        end

        if item["mikuType"] == "MxPlanningDisplay" then
            PolyAction::start(item["item"])
        end

        return if NxBallsService::isRunning(item["uuid"])

        accounts = []
        accounts << item["uuid"] # Item's own uuid
        OwnerMapping::elementuuidToOwnersuuids(item["uuid"])
            .each{|owneruuid|
                accounts << owneruuid # Owner of a owned item
            }
        if ["InboxItem", "TxDated"].include?(item["mikuType"]) then
            ox = TxTimeCommitmentProjects::interactivelySelectOneOrNull()
            if ox then
                puts "registering extra bank account: #{PolyFunction::toString(ox).green}"
                accounts << ox["uuid"]
            end
        end

        NxBallsService::issue(item["uuid"], PolyFunction::toString(item), accounts)
    end

    # PolyAction::stop(item)
    def self.stop(item)
        PolyFunction::_check(item, "PolyAction::stop")

        if command == "stop" then
            if item["mikuType"] == "MxPlanning" then
                if item["payload"]["type"] == "pointer" then
                    PolyAction::stop(item["payload"]["item"])
                end
            end
            if item["mikuType"] == "MxPlanningDisplay" then
                PolyAction::stop(item["item"])
            end
            NxBallsService::close(item["uuid"], true)
            return
        end

        if command == "wave" then
            Waves::issueNewWaveInteractivelyOrNull()
            return
        end

        puts "I do not know how to PolyAction::stop(#{JSON.pretty_generate(item)})"
        raise "(error: 13f1d929-9ae3-4c11-b795-cf399b35a17f)"
    end

    # PolyAction::access(item)
    def self.access(item)

        if item["mikuType"] == "(rstream-to-target)" then
            Streaming::icedStreamingToTarget()
            return
        end

        if item["mikuType"] == "fitness1" then
            puts PolyFunction::toString(item).green
            system("#{Config::userHomeDirectory()}/Galaxy/Binaries/fitness doing #{item["fitness-domain"]}")
            return
        end

        if item["mikuType"] == "CxAionPoint" then
            CxAionPoint::access(item)
            return
        end

        if item["mikuType"] == "CxFile" then
            CxFile::access(item)
            return
        end

        if item["mikuType"] == "CxUrl" then
            CxUrl::access(item)
            return
        end

        if item["mikuType"] == "DxAionPoint" then
            DxAionPoint::access(item)
            return
        end

        if item["mikuType"] == "DxText" then
            CommonUtils::accessText(item["text"])
            return
        end

        if item["mikuType"] == "MxPlanning" then
            if item["payload"]["type"] == "simple" then
                puts item["payload"]["description"].green
                LucilleCore::pressEnterToContinue()
            end
            if item["payload"]["type"] == "pointer" then
                PolyAction::access(item["payload"]["item"])
            end
            return
        end

        if item["mikuType"] == "MxPlanningDisplay" then
            PolyAction::access(item["item"])
            return
        end

        if item["mikuType"] == "NxAnniversary" then
            Anniversaries::access(item)
            return
        end

        if item["mikuType"] == "NxBall.v2" then
            if NxBallsService::isRunning(item["uuid"]) then
                if LucilleCore::askQuestionAnswerAsBoolean("complete '#{PolyFunction::toString(item).green}' ? ") then
                    NxBallsService::close(item["uuid"], true)
                end
            end
            return
        end

        if item["mikuType"] == "NxIced" then
            Nx112::carrierAccess(item)
            return
        end

        if item["mikuType"] == "NxLine" then
            if LucilleCore::askQuestionAnswerAsBoolean("destroy '#{PolyFunction::toString(item).green}' ? ") then
                DxF1::deleteObjectLogically(item["uuid"])
            end
            return
        end

        if item["mikuType"] == "NxTask" then
            Nx112::carrierAccess(item)
        end

        if item["mikuType"] == "TopLevel" then
            puts PolyFunction::toString(item).green
            action = LucilleCore::selectEntityFromListOfEntitiesOrNull("action", ["access", "edit"])
            return if action.nil?
            if action == "access" then
                TopLevel::access(item)
            end
            if action == "edit" then
                TopLevel::edit(item)
            end
            return
        end

        if item["mikuType"] == "InboxItem" then
            Nx112::carrierAccess(item)
            return
        end

        if item["mikuType"] == "TxTimeCommitmentProject" then
            puts PolyFunction::toString(item).green
            TxTimeCommitmentProjects::access(item)
            return
        end

        if item["mikuType"] == "Wave" then
            puts Waves::toString(item).green
            Nx112::carrierAccess(item)
            return
        end

        if Iam::isNetworkAggregation(item) then
            LinkedNavigation::navigate(item)
            return
        end

        raise "(error: abb645e9-2575-458e-b505-f9c029f4ca69) I do not know how to access mnikuType: #{item["mikuType"]}"
    end
end
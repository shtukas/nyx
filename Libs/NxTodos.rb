# encoding: UTF-8

class NxTodos

    # NxTodos::uuidToNx5Filepath(uuid)
    def self.uuidToNx5Filepath(uuid)
        "#{Config::pathToDataCenter()}/NxTodo/#{uuid}.Nx5"
    end

    # NxTodos::filepaths()
    def self.filepaths()
        LucilleCore::locationsAtFolder("#{Config::pathToDataCenter()}/NxTodo")
            .select{|filepath| filepath[-4, 4] == ".Nx5" }
            .each{|filepath|
                Nx5SyncConflictsResolution::probeAndRepairIfRelevant(filepath)
            }

        LucilleCore::locationsAtFolder("#{Config::pathToDataCenter()}/NxTodo")
            .select{|filepath| filepath[-4, 4] == ".Nx5" }
    end

    # NxTodos::items()
    def self.items()
        NxTodos::filepaths()
            .map{|filepath| Nx5Ext::readFileAsAttributesOfObject(filepath) }
    end

    # NxTodos::getItemOrNull(uuid)
    def self.getItemOrNull(uuid)
        filepath = NxTodos::uuidToNx5Filepath(uuid)
        return nil if !File.exists?(filepath)
        Nx5Ext::readFileAsAttributesOfObject(filepath)
    end

    # NxTodos::commitObject(object)
    def self.commitObject(object)
        FileSystemCheck::fsck_MikuTypedItem(object, SecureRandom.hex, false)
        filepath = NxTodos::uuidToNx5Filepath(object["uuid"])
        if !File.exists?(filepath) then
            Nx5::issueNewFileAtFilepath(filepath)
        end
        object.each{|key, value|
            Nx5::emitEventToFile1(filepath, key, value)
        }
    end

    # NxTodos::destroy(uuid)
    def self.destroy(uuid)
        filepath = NxTodos::uuidToNx5Filepath(uuid)
        return if !File.exists?(filepath)
        FileUtils.rm(filepath)
    end

    # NxTodos::moveToIce(uuid)
    #def self.moveToIce(uuid)
    #    filepath1 = NxTodos::uuidToNx5Filepath(uuid)
    #    filepath2 = filepath1.gsub("NxTodo", "NxTodo-Iced")
    #    FileUtils.mv(filepath1, filepath2)
    #end

    # --------------------------------------------------
    # Makers

    # NxTodos::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid  = SecureRandom.uuid
        nx11e = Nx11E::interactivelyCreateNewNx11E()
        nx113 = Nx113Make::interactivelyMakeNx113OrNull(NxTodos::getElizabethOperatorForUUID(uuid))
        cx23  = (nx11e["type"] == "standard") ? Cx23::interactivelyMakeNewOrNull() : nil
        item = {
            "uuid"        => uuid,
            "mikuType"    => "NxTodo",
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "description" => description,
            "nx113"       => nx113,
            "nx11e"       => nx11e,
            "cx23"        => cx23,
            "listeable"   => true
        }
        NxTodos::commitObject(item)
        item
    end

    # NxTodos::interactivelyIssueNewOndateOrNull(datetime = nil)
    def self.interactivelyIssueNewOndateOrNull(datetime = nil)
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid     = SecureRandom.uuid
        datetime = datetime || CommonUtils::interactivelySelectDateTimeIso8601UsingDateCode()
        nx11e    = Nx11E::makeOndate(datetime)
        nx113    = Nx113Make::interactivelyMakeNx113OrNull(NxTodos::getElizabethOperatorForUUID(uuid))
        item = {
            "uuid"        => uuid,
            "mikuType"    => "NxTodo",
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "description" => description,
            "nx113"       => nx113,
            "nx11e"       => nx11e,
            "listeable"   => true
        }
        NxTodos::commitObject(item)
        item
    end

    # NxTodos::interactivelyIssueNewTodayOrNull()
    def self.interactivelyIssueNewTodayOrNull()
        NxTodos::interactivelyIssueNewOndateOrNull(Time.new.utc.iso8601)
    end

    # NxTodos::interactivelyIssueNewHot(description)
    def self.interactivelyIssueNewHot(description)
        uuid  = SecureRandom.uuid
        nx11e = Nx11E::makeHot()
        item = {
            "uuid"        => uuid,
            "mikuType"    => "NxTodo",
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "description" => description,
            "nx11e"       => nx11e,
            "listeable"   => true
        }
        NxTodos::commitObject(item)
        item
    end

    # NxTodos::bufferInImport(location)
    def self.bufferInImport(location)
        description = File.basename(location)
        uuid = SecureRandom.uuid
        operator = NxTodos::getElizabethOperatorForUUID(uuid)
        nx113 = Nx113Make::aionpoint(operator, location)
        nx11e = Nx11E::makeTriage()
        item = {
            "uuid"        => uuid,
            "mikuType"    => "NxTodo",
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "description" => description,
            "nx113"       => nx113,
            "nx11e"       => nx11e,
            "listeable"   => true
        }
        NxTodos::commitObject(item)
        item
    end

    # NxTodos::issueUsingUrl(url)
    def self.issueUsingUrl(url)
        description = File.basename(location)
        uuid  = SecureRandom.uuid
        nx113 = Nx113Make::url(url)
        nx11e = Nx11E::makeStandard()
        item = {
            "uuid"        => uuid,
            "mikuType"    => "NxTodo",
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "description" => description,
            "nx113"       => nx113,
            "nx11e"       => nx11e,
            "listeable"   => true
        }
        NxTodos::commitObject(item)
        item
    end

    # NxTodos::issueFromElements(uuid, description, nx113, nx11e, cx23)
    def self.issueFromElements(uuid, description, nx113, nx11e, cx23)
        item = {
            "uuid"        => uuid,
            "mikuType"    => "NxTodo",
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "description" => description,
            "nx113"       => nx113,
            "nx11e"       => nx11e,
            "cx23"        => cx23,
            "listeable"   => true
        }
        NxTodos::commitObject(item)
    end

    # --------------------------------------------------
    # Data

    # NxTodos::toString(item)
    def self.toString(item)
        nx11estr = " #{Nx11E::toString(item["nx11e"])}"
        nx113str = Nx113Access::toStringOrNull(" ", item["nx113"], "")
        cx23 = item["cx23"]
        str1 = Cx23::toStringOrNull(cx23)
        cx23str1 = cx23 ? " (#{"%6.2f" % cx23["position"]})" : ""
        cx23str2 = str1 ? " (#{str1})".green : ""
        "(todo)#{cx23str1}#{nx11estr}#{nx113str} #{item["description"]}#{cx23str2}"
    end

    # NxTodos::toStringForSearch(item)
    def self.toStringForSearch(item)
        "(todo) #{item["description"]}"
    end

    # NxTodos::toStringForListing(item)
    def self.toStringForListing(item)
        datetimeOpt = DoNotShowUntil::getDateTimeOrNull(item["uuid"])
        dnsustr  = datetimeOpt ? " (do not show until: #{datetimeOpt})" : ""
        "#{NxTodos::toString(item)}#{dnsustr}"
    end

    # NxTodos::itemsOndates()
    def self.itemsOndates()
        NxTodos::items()
            .select{|item| item["nx11e"]["type"] == "ondate" }
    end

    # NxTodos::listingPriorityOrNull(item)
    def self.listingPriorityOrNull(item) # Float between 0 and 1

        shiftOnDateTime = lambda {|datetime|
            0.01*(Time.new.to_f - DateTime.parse(datetime).to_time.to_f)/86400
        }

        shiftOnUnixtime = lambda {|unixtime|
            0.01*Math.log(Time.new.to_f - unixtime)
        }

        shiftOnPosition = lambda {|position|
            0.01*Math.atan(-position)
        }

        shiftOnOrdinal = lambda {|ordinal|
            0.01*Math.atan(-ordinal)
        }

        shiftOnCompletionRatio = lambda {|ratio|
            0.01*Math.atan(-ratio)
        }

        # First we take account of the engine

        if item["nx11e"]["type"] == "hot" then
            return 0.95 + shiftOnUnixtime.call(item["nx11e"]["unixtime"])
        end

        if item["nx11e"]["type"] == "triage" then
            return 0.90 + shiftOnUnixtime.call(item["nx11e"]["unixtime"])
        end

        if item["nx11e"]["type"] == "ordinal" then
            return 0.85 + shiftOnOrdinal.call(item["nx11e"]["ordinal"])
        end

        if item["nx11e"]["type"] == "ondate" then
            return nil if (CommonUtils::today() < item["nx11e"]["datetime"][0, 10])
            return 0.70 + shiftOnDateTime.call(item["nx11e"]["datetime"])
        end

        if item["nx11e"]["type"] == "standard" and item["cx23"] then
            cx22 = Cx22::getOrNull(item["cx23"]["groupuuid"])
            if cx22 then
                return nil if !DoNotShowUntil::isVisible(cx22["uuid"])
                completionRatio = Ax39::completionRatioCached(cx22["ax39"], cx22["uuid"])
                return nil if completionRatio >= 1
                return 0.60 + shiftOnCompletionRatio.call(completionRatio) + shiftOnPosition.call(item["cx23"]["position"]).to_f/100
            end
        end

        if item["nx11e"]["type"] == "standard" then
            return 0.40 + shiftOnUnixtime.call(item["unixtime"])
        end

        raise "(error: a3c6797b-e063-44ca-8dab-4c5540688776) I do not know how to prioritise item: #{item}"
    end

    # NxTodos::listingItems()
    def self.listingItems()

        # We update the list of listable every day
        # TODO: when we moved to Nx5 files and NxTodo vs NxTodo-Iced, then this stopped working a s intended
        #if ProgrammableBooleans::trueNoMoreOftenThanEveryNSeconds("e38d89ee-0e4e-4b71-adcd-bfdcb7891e72", 86400) then
        #    Cx22::items().each{|cx22|
        #        NxTodos::items()
        #            .select{|item| item["cx23"] and item["cx23"]["groupuuid"] == cx22["uuid"] }
        #            .sort{|i1, i2| i1["unixtime"] <=> i2["unixtime"] }
        #            .reduce([]){|selected, item|
        #                (lambda {
        #                    if item["nx11e"]["type"] != "standard" then
        #                        return selected + [item]
        #                    end
        #                    if item["nx11e"]["type"] == "standard" then
        #                        count = selected.select{|i| i["nx11e"]["type"] == "standard" }.count
        #                        if count < 50 then
        #                            return selected + [item]
        #                        else
        #                            selected
        #                        end
        #                    end
        #                }).call()
        #            }
        #            .each{|item|
        #                next if item["listeable"]
        #                puts "set to listeable: #{NxTodos::toString(item)}"
        #                item["listeable"] =  true
        #                NxTodos::commitObject(item)
        #            }
        #    }
        #end

        NxTodos::items()
    end

    # NxTodos::itemsForCx22(cx22)
    def self.itemsForCx22(cx22)
        NxTodos::items()
            .select{|item| item["cx23"] }
            .select{|item| item["cx23"]["groupuuid"] == cx22["uuid"] }
    end

    # NxTodos::itemsInPositionOrderForGroup(cx22)
    def self.itemsInPositionOrderForGroup(cx22)
        NxTodos::itemsForCx22(cx22)
            .sort{|i1, i2| i1["cx23"]["position"] <=> i2["cx23"]["position"] }
    end

    # --------------------------------------------------
    # Operations

    # NxTodos::getElizabethOperatorForUUID(uuid)
    def self.getElizabethOperatorForUUID(uuid)
        filepath = NxTodos::uuidToNx5Filepath(uuid)
        if !File.exists?(filepath) then
            Nx5::issueNewFileAtFilepath(filepath)
        end
        ElizabethNx5.new(filepath)
    end

    # NxTodos::getElizabethOperatorForItem(item)
    def self.getElizabethOperatorForItem(item)
        raise "(error: c0581614-3ee5-4ed3-a192-537ed22c1dce)" if item["mikuType"] != "NxTodo"
        filepath = NxTodos::uuidToNx5Filepath(item["uuid"])
        if !File.exists?(filepath) then
            Nx5::issueNewFileAtFilepath(filepath)
        end
        ElizabethNx5.new(filepath)
    end

    # NxTodos::access(item)
    def self.access(item)
        puts NxTodos::toString(item).green
        if item["nx113"] then
            Nx113Access::access(NxTodos::getElizabethOperatorForItem(item), item["nx113"])
        end
    end

    # NxTodos::edit(item) # item
    def self.edit(item)
        if item["nx113"].nil? then
            puts "This item doesn't have a Nx113 attached to it"
            status = LucilleCore::askQuestionAnswerAsBoolean("Would you like to edit the description instead ? ")
            if status then
                PolyActions::editDescription(item)
                return NxTodos::getItemOrNull(item["uuid"])
            else
                return item
            end
        end
        Nx113Edit::editNx113Carrier(item)
        NxTodos::getItemOrNull(item["uuid"])
    end

    # NxTodos::landing(item)
    def self.landing(item)
        loop {

            return nil if item.nil?

            uuid = item["uuid"]
            item = NxTodos::getItemOrNull(uuid)
            return nil if item.nil?

            system("clear")

            puts PolyFunctions::toString(item)
            puts "uuid: #{item["uuid"]}".yellow
            puts "unixtime: #{item["unixtime"]}".yellow
            puts "datetime: #{item["datetime"]}".yellow
            puts "Nx11E (engine): #{JSON.generate(item["nx11e"])}".yellow
            puts "Nx113 (payload): #{Nx113Access::toStringOrNull("", item["nx113"], "")}".yellow
            puts "Cx23 (Contribution Group & Position): #{JSON.generate(item["cx23"])}".yellow

            puts ""
            puts "description | access | start | stop | engine | edit | nx113 | cx22 | done | do not show until | expose | destroy | nyx".yellow
            puts ""

            input = LucilleCore::askQuestionAnswerAsString("> ")
            return if input == ""

            # ordering: alphabetical

            if Interpreting::match("access", input) then
                PolyActions::access(item)
                next
            end

            if Interpreting::match("destroy", input) then
                PolyActions::destroyWithPrompt(item)
                return
            end

            if Interpreting::match("description", input) then
                PolyActions::editDescription(item)
                next
            end

            if Interpreting::match("done", input) then
                PolyActions::done(item)
                return
            end

            if Interpreting::match("do not show until", input) then
                datecode = LucilleCore::askQuestionAnswerAsString("datecode: ")
                return if datecode == ""
                unixtime = CommonUtils::codeToUnixtimeOrNull(datecode.gsub(" ", ""))
                return if unixtime.nil?
                PolyActions::stop(item)
                DoNotShowUntil::setUnixtime(item["uuid"], unixtime)
                return
            end

            if Interpreting::match("edit", input) then
                item = PolyFunctions::edit(item)
                next
            end

            if Interpreting::match("engine", input) then
                engine = Nx11E::interactivelyCreateNewNx11EOrNull()
                next if engine.nil?
                item["nx11e"] =  engine
                NxTodos::commitObject(item)
                next
            end

            if Interpreting::match("expose", input) then
                puts JSON.pretty_generate(item)
                LucilleCore::pressEnterToContinue()
                next
            end

            if Interpreting::match("nyx", input) then
                Nyx::program()
                next
            end

            if Interpreting::match("start", input) then
                PolyActions::start(item)
                next
            end

            if Interpreting::match("stop", input) then
                PolyActions::stop(item)
                next
            end
        }
    end

    # NxTodos::diveOndates()
    def self.diveOndates()
        loop {
            system("clear")
            items = NxTodos::itemsOndates().sort{|i1, i2| i1["nx11e"]["datetime"] <=> i2["nx11e"]["datetime"] }
            item = LucilleCore::selectEntityFromListOfEntitiesOrNull("dated", items, lambda{|item| NxTodos::toString(item) })
            break if item.nil?
            PolyActions::landing(item)
        }
    end

    # NxTodos::elementsDive(elements)
    def self.elementsDive(elements)
        loop {
            system("clear")
            store = ItemStore.new()
            elements
                .each{|element|
                    store.register(element, false)
                    puts "#{store.prefixString()} #{PolyFunctions::toString(element)}"
                }

            puts ""
            puts "<n>".yellow
            puts ""
            input = LucilleCore::askQuestionAnswerAsString("> ")
            return if input == ""

            if (indx = Interpreting::readAsIntegerOrNull(input)) then
                entity = store.get(indx)
                next if entity.nil?
                PolyActions::landing(entity)
                next
            end
        }
    end

    # NxTodos::todosLatestFirst()
    def self.todosLatestFirst()
        items = NxTodos::items()
                    .sort{|i1, i2| i1["unixtime"] <=> i2["unixtime"] }
                    .reverse
                    .first(50)
        NxTodos::elementsDive(items)
    end
end

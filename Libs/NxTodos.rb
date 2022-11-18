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
        FileSystemCheck::fsck_MikuTypedItem(object, false)
        filepath = NxTodos::uuidToNx5Filepath(object["uuid"])
        if !File.exists?(filepath) then
            Nx5::issueNewFileAtFilepath(filepath, object["uuid"])
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

    # --------------------------------------------------
    # Makers

    # NxTodos::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid  = SecureRandom.uuid
        nx11e = Nx11E::interactivelyCreateNewNx11E()
        nx113 = Nx113Make::interactivelyMakeNx113OrNull(NxTodos::getElizabethOperatorForUUID(uuid))
        cx23  = (nx11e["type"] == "standard") ? Cx23::interactivelyMakeNewOrNull(uuid) : nil
        Cx22::commitCx23(cx23)
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
        nx11e = Nx11E::makeAsapNotNecToday()
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
        Cx22::commitCx23(cx23)
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
    end

    # --------------------------------------------------
    # Data

    # NxTodos::toString(item)
    def self.toString(item)
        nx11estr = " #{Nx11E::toString(item["nx11e"])}"
        nx113str = Nx113Access::toStringOrNull(" ", item["nx113"], "")

        cx23str1 = ""
        cx23str2 = ""

        cx23 = Cx22::getCx23ForItemuuidOrNull(item["uuid"])
        if cx23 then
            str1 = Cx23::toStringOrNull(cx23)
            cx23str1 = cx23 ? " (#{"%6.2f" % cx23["position"]})" : ""
            cx23str2 = str1 ? " (#{str1})".green : ""
        end

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

        # This is a subset of the primary definition

        # NxTodo (triage)               0.92
        # NxTodo (ondate:today)         0.76
        # NxTodo (asap-not-nec-today)   0.50
        # NxTodo (standard)             0.30

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

        if item["nx11e"]["type"] == "triage" then
            return 0.92 + shiftOnUnixtime.call(item["nx11e"]["unixtime"])
        end

        if item["nx11e"]["type"] == "ondate" then
            return nil if (CommonUtils::today() < item["nx11e"]["datetime"][0, 10])
            return 0.76 + shiftOnDateTime.call(item["nx11e"]["datetime"])
        end

        if item["nx11e"]["type"] == "ns:asap-not-nec-today" then
            return 0.50 + shiftOnUnixtime.call(item["nx11e"]["unixtime"])
        end

        if item["nx11e"]["type"] == "standard" and Cx22::getCx22ForItemUUIDOrNull(item["uuid"]) then
            return nil
        end

        if item["nx11e"]["type"] == "standard" then
            return 0.30 + shiftOnUnixtime.call(item["unixtime"])
        end

        raise "(error: a3c6797b-e063-44ca-8dab-4c5540688776) I do not know how to prioritise item: #{item}"
    end

    # NxTodos::listingItems()
    def self.listingItems()
        cx22 = Cx22::cx22WithCompletionRatiosOrdered()
                    .select{|packet| packet["completionRatio"] < 1 }
                    .map{|packet| packet["item"] }
                    .first

        if cx22 then
            return Cx22::firstNItemsForCx22InPositionOrder(cx22, 10)
        end

        getCachedFilepathsOrNull = lambda {
            filepaths = XCache::getOrNull("bf8228f9-9f76-4b09-a233-c744fb77c000")
            return nil if filepaths.nil?
            filepaths = JSON.parse(filepaths)
        }

        issueNewBatch = lambda {
            filepaths = NxTodos::filepaths().shuffle.take(10) # Note that this can return items on Cx22s
            XCache::set("bf8228f9-9f76-4b09-a233-c744fb77c000", JSON.generate(filepaths))
            filepaths
        }

        cachedFilepaths = getCachedFilepathsOrNull.call()
        aliveFilepaths = cachedFilepaths.select{|filepath| File.exists?(filepath) }
        if aliveFilepaths.size < 5 then
            filepaths = issueNewBatch.call()
        else
            filepaths = aliveFilepaths
        end

        filepaths
            .map{|filepath| Nx5Ext::readFileAsAttributesOfObject(filepath) }
    end

    # --------------------------------------------------
    # Operations

    # NxTodos::getElizabethOperatorForUUID(uuid)
    def self.getElizabethOperatorForUUID(uuid)
        filepath = NxTodos::uuidToNx5Filepath(uuid)
        if !File.exists?(filepath) then
            Nx5::issueNewFileAtFilepath(filepath, uuid)
        end
        ElizabethNx5.new(filepath)
    end

    # NxTodos::getElizabethOperatorForItem(item)
    def self.getElizabethOperatorForItem(item)
        raise "(error: c0581614-3ee5-4ed3-a192-537ed22c1dce)" if item["mikuType"] != "NxTodo"
        filepath = NxTodos::uuidToNx5Filepath(item["uuid"])
        if !File.exists?(filepath) then
            Nx5::issueNewFileAtFilepath(filepath, item["uuid"])
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
            puts "Cx23 (Contribution Group & Position): #{JSON.generate(Cx22::getCx23ForItemuuidOrNull(item["uuid"]))}".yellow

            puts ""
            puts "description | access | engine | edit | nx113 | cx22 | done | do not show until | expose | destroy | nyx".yellow
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
                description = CommonUtils::editTextSynchronously(item["description"]).strip
                return if description == ""
                filepath = NxTodos::uuidToNx5Filepath(item["uuid"])
                Nx5Ext::setAttribute(filepath, "description", description)
                next
            end

            if Interpreting::match("nx113", input) then
                operator = NxTodos::getElizabethOperatorForUUID(item["uuid"])
                nx113 = Nx113Make::interactivelyMakeNx113OrNull(operator)
                next if nx113.nil?
                filepath = NxTodos::uuidToNx5Filepath(item["uuid"])
                Nx5Ext::setAttribute(filepath, "nx113", nx113)
                return
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
                filepath = NxTodos::uuidToNx5Filepath(item["uuid"])
                Nx5Ext::setAttribute(filepath, "nx11e", nx11e)
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
end

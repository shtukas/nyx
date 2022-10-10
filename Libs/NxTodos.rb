# encoding: UTF-8

$ListingManager = nil

class ListingManager

    def initialize()
        data = XCache::getOrNull("de9710ba-6ece-4cff-8176-41e8894b4fde")
        if data then
            @data = JSON.parse(data)
        else
            rebuildInstance()
        end

        Thread.new {
            loop {
                sleep 60
                rebuildInstance()
                sleep 3600
            }
        }
    end

    def listingItemsInstance()
        @data.first(20)
            .map{|packet| packet["item"] }
            .map{|item| item.clone }
    end

    def rebuildInstance()
        items = NxTodos::items()
        @data = items
                    .map{|item|
                        {
                            "mikuType" => "NxTodoWithListingPriority",
                            "item"     => item,
                            "priority" => NxTodos::listingPriorityOrNull(item)
                        }
                    }
                    .sort{|p1, p2| (p1["priority"] || -1) <=> (p2["priority"] || -1) }
                    .reverse
        XCache::set("de9710ba-6ece-4cff-8176-41e8894b4fde", JSON.generate(@data))
    end

    def incomingItemInstance(item)
        return if item["mikuType"] != "NxTodo"
        @data = @data.reject{|packet| packet["item"]["uuid"] == item["uuid"] }
        @data << {
            "mikuType" => "NxTodoWithListingPriority",
            "item"     => item,
            "priority" => NxTodos::listingPriorityOrNull(item)
        }
        @data = @data
                    .sort{|p1, p2| (p1["priority"] || -1) <=> (p2["priority"] || -1) }
                    .reverse
        XCache::set("de9710ba-6ece-4cff-8176-41e8894b4fde", JSON.generate(@data))
    end

    def destroyItemInstance(itemuuid)
        @data = @data.reject{|packet| packet["item"]["uuid"] == itemuuid }
        @data = @data
                    .sort{|p1, p2| (p1["priority"] || -1) <=> (p2["priority"] || -1) }
                    .reverse
        XCache::set("de9710ba-6ece-4cff-8176-41e8894b4fde", JSON.generate(@data))
    end

    # ListingManager::listingItems()
    def self.listingItems()
        if $ListingManager.nil? then
            $ListingManager = ListingManager.new()
        end
        $ListingManager.listingItemsInstance()
    end

    # ListingManager::rebuild()
    def self.rebuild()
        if $ListingManager.nil? then
            $ListingManager = ListingManager.new()
        end
        $ListingManager.rebuildInstance()
    end

    # ListingManager::incomingItem(item)
    def self.incomingItem(item)
        if $ListingManager.nil? then
            $ListingManager = ListingManager.new()
        end
        $ListingManager.incomingItemInstance(item)
    end

    # ListingManager::incomingItemuuid(itemuuid)
    def self.incomingItemuuid(itemuuid)
        if $ListingManager.nil? then
            $ListingManager = ListingManager.new()
        end
        item = Items::getItemOrNull(itemuuid)
        $ListingManager.incomingItemInstance(item)
    end

    # ListingManager::destroyItem(itemuuid)
    def self.destroyItem(itemuuid)
        if $ListingManager.nil? then
            $ListingManager = ListingManager.new()
        end
        $ListingManager.destroyItemInstance(itemuuid)
    end
end

class NxTodos

    # NxTodos::items()
    def self.items()
        Items::mikuTypeToItems("NxTodo")
    end

    # NxTodos::destroy(uuid)
    def self.destroy(uuid)
        Items::delete(uuid)
    end

    # --------------------------------------------------
    # Makers

    # NxTodos::interactivelyCreateNewOrNull()
    def self.interactivelyCreateNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid        = SecureRandom.uuid
        nx11e       = Nx11E::interactivelyCreateNewNx11E()
        nx113nhash  = Nx113Make::interactivelyIssueNewNx113OrNullReturnDataBase1Nhash()
        cx22        = Cx22::architectOrNull()
        cx23        = cx22 ? Cx23::makeNewOrNull2(cx22["groupuuid"]) : nil
        item = {
            "uuid"        => uuid,
            "mikuType"    => "NxTodo",
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "description" => description,
            "nx113"       => nx113nhash,
            "nx11e"       => nx11e,
            "cx22"        => cx22,
            "cx23"        => cx23
        }
        FileSystemCheck::fsckItemErrorArFirstFailure(item, SecureRandom.hex, true)
        Items::putItem(item)
        item
    end

    # NxTodos::interactivelyCreateNewOndateOrNull(datetime = nil)
    def self.interactivelyCreateNewOndateOrNull(datetime = nil)
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid       = SecureRandom.uuid
        datetime   = datetime || CommonUtils::interactivelySelectDateTimeIso8601UsingDateCode()
        nx11e      = Nx11E::makeOndate(datetime)
        nx113nhash = Nx113Make::interactivelyIssueNewNx113OrNullReturnDataBase1Nhash()
        cx22       = Cx22::architectOrNull()
        item = {
            "uuid"        => uuid,
            "mikuType"    => "NxTodo",
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "description" => description,
            "nx113"       => nx113nhash,
            "nx11e"       => nx11e,
            "cx22"        => cx22
        }
        FileSystemCheck::fsckItemErrorArFirstFailure(item, SecureRandom.hex, true)
        Items::putItem(item)
        item
    end

    # NxTodos::interactivelyCreateNewTodayOrNull()
    def self.interactivelyCreateNewTodayOrNull()
        NxTodos::interactivelyCreateNewOndateOrNull(Time.new.utc.iso8601)
    end

    # NxTodos::interactivelyCreateNewHot(description)
    def self.interactivelyCreateNewHot(description)
        uuid       = SecureRandom.uuid
        nx11e      = Nx11E::makeHot()
        nx113nhash = nil
        cx22       = Cx22::architectOrNull()
        item = {
            "uuid"        => uuid,
            "mikuType"    => "NxTodo",
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "description" => description,
            "nx113"       => nx113nhash,
            "nx11e"       => nx11e,
            "cx22"        => cx22
        }
        FileSystemCheck::fsckItemErrorArFirstFailure(item, SecureRandom.hex, true)
        Items::putItem(item)
        item
    end

    # NxTodos::issueUsingLocation(location)
    def self.issueUsingLocation(location)
        description = File.basename(location)
        uuid        = SecureRandom.uuid
        nx113nhash  = Nx113Make::aionpoint(location)
        nx11e       = Nx11E::makeStandard()
        item = {
            "uuid"        => uuid,
            "mikuType"    => "NxTodo",
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "description" => description,
            "nx113"       => nx113nhash,
            "nx11e"       => nx11e
        }
        FileSystemCheck::fsckItemErrorArFirstFailure(item, SecureRandom.hex, true)
        Items::putItem(item)
        item
    end

    # NxTodos::issueUsingUrl(url)
    def self.issueUsingUrl(url)
        description = File.basename(location)
        uuid        = SecureRandom.uuid
        nx113nhash  = Nx113Make::url(url)
        nx11e       = Nx11E::makeStandard()
        item = {
            "uuid"        => uuid,
            "mikuType"    => "NxTodo",
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "description" => description,
            "nx113"       => nx113nhash,
            "nx11e"       => nx11e
        }
        FileSystemCheck::fsckItemErrorArFirstFailure(item, SecureRandom.hex, true)
        Items::putItem(item)
        item
    end

    # --------------------------------------------------
    # Data

    # NxTodos::toString(item)
    def self.toString(item)
        nx11estr = Nx11E::toString(item["nx11e"])
        nx113str = Nx113Access::toStringOrNull(" ", item["nx113"], "")
        cx22str  = item["cx22"] ? " #{Cx22::toString(item["cx22"]).green}" : ""
        cx23str  = item["cx23"] ? " (pos: #{"%6.2f" % item["cx23"]["position"]})" : ""
        "(todo)#{cx23str} #{nx11estr} #{item["description"]}#{nx113str}#{cx22str}".strip.gsub("(todo) (standard)", "(todo)")
    end

    # NxTodos::toStringForSearch(item)
    def self.toStringForSearch(item)
        "(todo) #{item["description"]}"
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

        if item["nx11e"]["type"] == "standard" and item["cx22"] and item["cx23"] then
            completionRatio = Ax39::completionRatioCached(item["cx22"]["ax39"], item["cx22"]["bankaccount"])
            return nil if completionRatio >= 1
            return 0.60 + shiftOnCompletionRatio.call(completionRatio) + shiftOnPosition.call(item["cx23"]["position"]).to_f/100
        end

        if item["nx11e"]["type"] == "standard" and item["cx22"] then
            completionRatio = Ax39::completionRatioCached(item["cx22"]["ax39"], item["cx22"]["bankaccount"])
            return nil if completionRatio >= 1
            return 0.50 + shiftOnCompletionRatio.call(completionRatio)
        end

        if item["nx11e"]["type"] == "standard" then
            return 0.40 + shiftOnUnixtime.call(item["unixtime"])
        end

        raise "(error: a3c6797b-e063-44ca-8dab-4c5540688776) I do not know how to prioritise item: #{item}"
    end

    # NxTodos::listingItems()
    def self.listingItems()
        ListingManager::listingItems()
    end

    # NxTodos::itemsInPositionOrderForGroup(cx22)
    def self.itemsInPositionOrderForGroup(cx22)
        items1 = NxTodos::items()
                    .select{|item| item["cx22"] and item["cx22"]["groupuuid"] == cx22["groupuuid"] }
                    .select{|item| item["cx23"] }
                    .sort{|i1, i2| i1["cx23"]["position"] <=> i2["cx23"]["position"] }
        items2 = NxTodos::items()
                    .select{|item| item["cx22"] and item["cx22"]["groupuuid"] == cx22["groupuuid"] }
                    .select{|item| item["cx23"].nil? }
                    .sort{|i1, i2| i1["unixtime"] <=> i2["unixtime"] }
        items1 + items2
    end

    # --------------------------------------------------
    # Operations

    # NxTodos::access(item)
    def self.access(item)
        puts NxTodos::toString(item).green
        if item["nx113"] then
            Nx113Access::access(item["nx113"])
        end
    end

    # NxTodos::edit(item) # item
    def self.edit(item)
        if item["nx113"].nil? then
            puts "This item doesn't have a Nx113 attached to it"
            status = LucilleCore::askQuestionAnswerAsBoolean("Would you like to edit the description instead ? ")
            if status then
                PolyActions::editDescription(item)
                return Items::getItemOrNull(item["uuid"])
            else
                return item
            end
        end
        Nx113Edit::edit(item)
        Items::getItemOrNull(item["uuid"])
    end

    # NxTodos::landing(item)
    def self.landing(item)
        loop {

            return nil if item.nil?

            uuid = item["uuid"]
            item = Items::getItemOrNull(uuid)
            return nil if item.nil?

            system("clear")

            puts PolyFunctions::toString(item)
            puts "uuid: #{item["uuid"]}".yellow
            puts "unixtime: #{item["unixtime"]}".yellow
            puts "datetime: #{item["datetime"]}".yellow
            puts "Nx11E (engine): #{JSON.generate(item["nx11e"])}".yellow
            puts "Nx113 (payload): #{Nx113Access::toStringOrNull("", item["nx113"], "")}".yellow
            puts "Cx22 (Contribution Group): #{JSON.generate(item["cx22"])}".yellow
            puts "Cx23 (Group position): #{JSON.generate(item["cx23"])}".yellow

            puts ""
            puts "description | access | start | stop | engine | edit | nx113 | done | do not show until | expose | destroy | nyx".yellow
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
                Items::setAttribute2(item["uuid"], "nx11e", engine)
                next
            end

            if Interpreting::match("expose", input) then
                puts JSON.pretty_generate(item)
                LucilleCore::pressEnterToContinue()
                next
            end

            if Interpreting::match("nx113", input) then
                PolyActions::setNx113(item)
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

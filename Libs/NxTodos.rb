# encoding: UTF-8

class NxTodosActivePool
    # This class is an optimization solution

    # NxTodosActivePool::computeActivePool()
    def self.computeActivePool()
        items = Items::mikuTypeToItems("NxTodo")
        items = items
                    .map{|item|
                        {
                            "item"     => item,
                            "priority" => PolyFunctions::listingPriority(item)
                        }
                    }.sort{|p1, p2|
                        p1["priority"] <=> p2["priority"]
                    }
                    .reverse
                    .first(100)
                    .map{|packet| packet["item"] }
        items.map{|item| item["uuid"] }
    end

    # NxTodosActivePool::getActivePool()
    def self.getActivePool()
        objectuuids = XCache::getOrNull("64a299f3-0960-4330-8538-394879cc231f")
        if objectuuids then
            return JSON.parse(objectuuids)
        end
        objectuuids = NxTodosActivePool::computeActivePool()
        NxTodosActivePool::commitPoolToCache(objectuuids)
        objectuuids
    end

    # NxTodosActivePool::commitPoolToCache(objectuuids)
    def self.commitPoolToCache(objectuuids)
        XCache::set("64a299f3-0960-4330-8538-394879cc231f", JSON.generate(objectuuids))
    end

    # NxTodosActivePool::todoObjectHadBeenCreated(item)
    def self.todoObjectHadBeenCreated(item)
        return if item["mikuType"] != "NxTodo"
        objectuuids = NxTodosActivePool::getActivePool() + item["uuid"]
        NxTodosActivePool::commitPoolToCache(objectuuids)
    end
end

class NxTodos

    # NxTodos::items()
    def self.items()
        Items::mikuTypeToItems("NxTodo")
    end

    # NxTodos::destroy(uuid)
    def self.destroy(uuid)
        NxDeleted::deleteObject(uuid)
    end

    # --------------------------------------------------
    # Makers

    # NxTodos::interactivelyCreateNewOrNull()
    def self.interactivelyCreateNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid       = SecureRandom.uuid
        nx11e      = Nx11E::interactivelyCreateNewNx11EOrNull(uuid)
        return if nx11e.nil?
        nx113nhash = Nx113Make::interactivelyIssueNewNx113OrNullReturnDataBase1Nhash()
        ItemsEventsLog::setAttribute2(uuid, "uuid",        uuid)
        ItemsEventsLog::setAttribute2(uuid, "mikuType",    "NxTodo")
        ItemsEventsLog::setAttribute2(uuid, "unixtime",    Time.new.to_i)
        ItemsEventsLog::setAttribute2(uuid, "datetime",    Time.new.utc.iso8601)
        ItemsEventsLog::setAttribute2(uuid, "description", description)
        ItemsEventsLog::setAttribute2(uuid, "nx113",       nx113nhash)
        ItemsEventsLog::setAttribute2(uuid, "nx11e",       nx11e)
        FileSystemCheck::fsckObjectuuidErrorAtFirstFailure(uuid, SecureRandom.hex)
        item = Items::getItemOrNull(uuid)
        if item.nil? then
            raise "(error: ec1f1b6f-62b4-4426-bfe3-439a51cf76d4) How did that happen ? 🤨"
        end
        NxTodosActivePool::todoObjectHadBeenCreated(item)
        item
    end

    # NxTodos::interactivelyCreateNewOndateOrNull(datetime = nil)
    def self.interactivelyCreateNewOndateOrNull(datetime = nil)
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""

        if datetime.nil? then
             datetime = CommonUtils::interactivelySelectDateTimeIso8601OrNullUsingDateCode()
             # TODO: we could also have an interactive builder that always returns a non null value
             if datetime.nil? then
                datetime = Time.new.utc.iso8601
             end
        end

        uuid = SecureRandom.uuid
        nx113nhash = Nx113Make::interactivelyIssueNewNx113OrNullReturnDataBase1Nhash()
        nx11e      = Nx11E::makeOndate(datetime)
        ItemsEventsLog::setAttribute2(uuid, "uuid",        uuid)
        ItemsEventsLog::setAttribute2(uuid, "mikuType",    "NxTodo")
        ItemsEventsLog::setAttribute2(uuid, "unixtime",    Time.new.to_i)
        ItemsEventsLog::setAttribute2(uuid, "datetime",    Time.new.utc.iso8601) # This is the object datetime, not the engine datetime (back during the TxDated era they used to be the same)
        ItemsEventsLog::setAttribute2(uuid, "description", description)
        ItemsEventsLog::setAttribute2(uuid, "nx113",       nx113nhash)
        ItemsEventsLog::setAttribute2(uuid, "nx11e",       nx11e)
        FileSystemCheck::fsckObjectuuidErrorAtFirstFailure(uuid, SecureRandom.hex)
        item = Items::getItemOrNull(uuid)
        if item.nil? then
            raise "(error: 06f11b6f-7d31-411b-b3bf-7b1115a756a9) How did that happen ? 🤨"
        end

        NxTodosActivePool::todoObjectHadBeenCreated(item)
        item
    end

    # NxTodos::interactivelyCreateNewTodayOrNull()
    def self.interactivelyCreateNewTodayOrNull()
        NxTodos::interactivelyCreateNewOndateOrNull(Time.new.utc.iso8601)
    end

    # NxTodos::interactivelyCreateNewDescriptionOnlyOrNull_v1(description)
    def self.interactivelyCreateNewDescriptionOnlyOrNull_v1(description)
        uuid  = SecureRandom.uuid
        nx11e = Nx11E::interactivelyCreateNewNx11EOrNull(uuid)
        return if nx11e.nil?
        nx113nhash = nil
        ItemsEventsLog::setAttribute2(uuid, "uuid",        uuid)
        ItemsEventsLog::setAttribute2(uuid, "mikuType",    "NxTodo")
        ItemsEventsLog::setAttribute2(uuid, "unixtime",    Time.new.to_i)
        ItemsEventsLog::setAttribute2(uuid, "datetime",    Time.new.utc.iso8601)
        ItemsEventsLog::setAttribute2(uuid, "description", description)
        ItemsEventsLog::setAttribute2(uuid, "nx113",       nx113nhash)
        ItemsEventsLog::setAttribute2(uuid, "nx11e",       nx11e)
        FileSystemCheck::fsckObjectuuidErrorAtFirstFailure(uuid, SecureRandom.hex)
        item = Items::getItemOrNull(uuid)
        if item.nil? then
            raise "(error: ec1f1b6f-62b4-4426-bfe3-439a51cf76d4) How did that happen ? 🤨"
        end
        NxTodosActivePool::todoObjectHadBeenCreated(item)
        item
    end

    # NxTodos::issueUsingLocation(location)
    def self.issueUsingLocation(location)
        description = File.basename(location)
        uuid        = SecureRandom.uuid
        nx11e       = {
            "mikuType" => "Nx11E",
            "type"     => "standard",
            "unixtime" => Time.new.to_f
        }
        nx113nhash  = Nx113Make::aionpoint(location)
        ItemsEventsLog::setAttribute2(uuid, "uuid",        uuid)
        ItemsEventsLog::setAttribute2(uuid, "mikuType",    "NxTodo")
        ItemsEventsLog::setAttribute2(uuid, "unixtime",    Time.new.to_i)
        ItemsEventsLog::setAttribute2(uuid, "datetime",    Time.new.utc.iso8601)
        ItemsEventsLog::setAttribute2(uuid, "description", description)
        ItemsEventsLog::setAttribute2(uuid, "nx113",       nx113nhash)
        ItemsEventsLog::setAttribute2(uuid, "nx11e",       nx11e)
        FileSystemCheck::fsckObjectuuidErrorAtFirstFailure(uuid, SecureRandom.hex)
        item = Items::getItemOrNull(uuid)
        if item.nil? then
            raise "(error: ec1f1b6f-62b4-4426-bfe3-439a51cf76d4) How did that happen ? 🤨"
        end
        NxTodosActivePool::todoObjectHadBeenCreated(item)
        item
    end

    # NxTodos::issueUsingUrl(url)
    def self.issueUsingUrl(url)
        description = File.basename(location)
        uuid        = SecureRandom.uuid
        nx11e       = {
            "mikuType" => "Nx11E",
            "type"     => "standard",
            "unixtime" => Time.new.to_f
        }
        nx113nhash  = Nx113Make::url(url)
        ItemsEventsLog::setAttribute2(uuid, "uuid",        uuid)
        ItemsEventsLog::setAttribute2(uuid, "mikuType",    "NxTodo")
        ItemsEventsLog::setAttribute2(uuid, "unixtime",    Time.new.to_i)
        ItemsEventsLog::setAttribute2(uuid, "datetime",    Time.new.utc.iso8601)
        ItemsEventsLog::setAttribute2(uuid, "description", description)
        ItemsEventsLog::setAttribute2(uuid, "nx113",       nx113nhash)
        ItemsEventsLog::setAttribute2(uuid, "nx11e",       nx11e)
        FileSystemCheck::fsckObjectuuidErrorAtFirstFailure(uuid, SecureRandom.hex)
        item = Items::getItemOrNull(uuid)
        if item.nil? then
            raise "(error: ec1f1b6f-62b4-4426-bfe3-439a51cf76d4) How did that happen ? 🤨"
        end
        NxTodosActivePool::todoObjectHadBeenCreated(item)
        item
    end

    # --------------------------------------------------
    # Data

    # NxTodos::toString(item)
    def self.toString(item)
        "(todo) #{Nx11E::toString(item["nx11e"])} #{item["description"]}#{Nx113Access::toStringOrNull(" ", item["nx113"], "")}"
    end

    # NxTodos::toStringForSearch(item)
    def self.toStringForSearch(item)
        "(todo) #{item["description"]}"
    end

    # NxTodos::listingItems()
    def self.listingItems()
        NxTodosActivePool::getActivePool()
            .map{|objectuuid| Items::getItemOrNull(objectuuid) }
            .compact
    end

    # NxTodos::itemsOndates()
    def self.itemsOndates()
        NxTodos::items()
            .select{|item| item["nx11e"]["type"] == "ondate" }
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
        ItemsEventsLog::getProtoItemOrNull(item["uuid"])
    end

    # NxTodos::landing(item)
    def self.landing(item)
        loop {

            return nil if item.nil?

            uuid = item["uuid"]
            item = ItemsEventsLog::getProtoItemOrNull(uuid)
            return nil if item.nil?

            system("clear")

            puts PolyFunctions::toString(item)
            puts "uuid: #{item["uuid"]}".yellow
            puts "unixtime: #{item["unixtime"]}".yellow
            puts "datetime: #{item["datetime"]}".yellow
            puts "Nx11E: #{JSON.pretty_generate(item["nx11e"])}".yellow

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
                engine = Nx11E::interactivelyCreateNewNx11EOrNull(item["uuid"])
                next if engine.nil?
                ItemsEventsLog::setAttribute2(item["uuid"], "nx11e", engine)
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
            PolyPrograms::itemLanding(item)
        }
    end
end

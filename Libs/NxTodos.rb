# encoding: UTF-8

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
        uuid        = SecureRandom.uuid
        nx11e       = Nx11E::interactivelyCreateNewNx11E()
        nx113nhash  = Nx113Make::interactivelyIssueNewNx113OrNullReturnDataBase1Nhash()
        cx22        = Cx22::architectOrNull()
        cx23        = cx22 ? Cx23::makeNewOrNull2(cx22["groupuuid"]) : nil
        Items::setAttribute2(uuid, "uuid",        uuid)
        Items::setAttribute2(uuid, "mikuType",    "NxTodo")
        Items::setAttribute2(uuid, "unixtime",    Time.new.to_i)
        Items::setAttribute2(uuid, "datetime",    Time.new.utc.iso8601)
        Items::setAttribute2(uuid, "description", description)
        Items::setAttribute2(uuid, "nx113",       nx113nhash)
        Items::setAttribute2(uuid, "nx11e",       nx11e)
        Items::setAttribute2(uuid, "cx22",        cx22)
        Items::setAttribute2(uuid, "cx23",        cx23)
        item = Items::getItemOrNull(uuid)
        if item.nil? then
            raise "(error: ec1f1b6f-62b4-4426-bfe3-439a51cf76d4) How did that happen ? 🤨"
        end
        FileSystemCheck::fsckItemErrorArFirstFailure(item, SecureRandom.hex, true)
        item
    end

    # NxTodos::interactivelyCreateNewOndateOrNull(datetime = nil)
    def self.interactivelyCreateNewOndateOrNull(datetime = nil)
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid = SecureRandom.uuid
        datetime = datetime || CommonUtils::interactivelySelectDateTimeIso8601UsingDateCode()
        nx11e = Nx11E::makeOndate(datetime)
        nx113nhash = Nx113Make::interactivelyIssueNewNx113OrNullReturnDataBase1Nhash()
        cx22 = Cx22::architectOrNull()
        Items::setAttribute2(uuid, "uuid",        uuid)
        Items::setAttribute2(uuid, "mikuType",    "NxTodo")
        Items::setAttribute2(uuid, "unixtime",    Time.new.to_i)
        Items::setAttribute2(uuid, "datetime",    Time.new.utc.iso8601) # This is the object datetime, not the engine datetime (back during the TxDated era they used to be the same)
        Items::setAttribute2(uuid, "description", description)
        Items::setAttribute2(uuid, "nx113",       nx113nhash)
        Items::setAttribute2(uuid, "nx11e",       nx11e)
        Items::setAttribute2(uuid, "cx22",        cx22)
        item = Items::getItemOrNull(uuid)
        if item.nil? then
            raise "(error: 06f11b6f-7d31-411b-b3bf-7b1115a756a9) How did that happen ? 🤨"
        end
        FileSystemCheck::fsckItemErrorArFirstFailure(item, SecureRandom.hex, true)
        item
    end

    # NxTodos::interactivelyCreateNewTodayOrNull()
    def self.interactivelyCreateNewTodayOrNull()
        NxTodos::interactivelyCreateNewOndateOrNull(Time.new.utc.iso8601)
    end

    # NxTodos::interactivelyCreateNewHot(description)
    def self.interactivelyCreateNewHot(description)
        uuid  = SecureRandom.uuid
        nx11e = Nx11E::makeHot()
        return if nx11e.nil?
        nx113nhash = nil
        cx22 = Cx22::architectOrNull()
        Items::setAttribute2(uuid, "uuid",        uuid)
        Items::setAttribute2(uuid, "mikuType",    "NxTodo")
        Items::setAttribute2(uuid, "unixtime",    Time.new.to_i)
        Items::setAttribute2(uuid, "datetime",    Time.new.utc.iso8601)
        Items::setAttribute2(uuid, "description", description)
        Items::setAttribute2(uuid, "nx113",       nx113nhash)
        Items::setAttribute2(uuid, "nx11e",       nx11e)
        Items::setAttribute2(uuid, "cx22",        cx22)
        item = Items::getItemOrNull(uuid)
        if item.nil? then
            raise "(error: ec1f1b6f-62b4-4426-bfe3-439a51cf76d4) How did that happen ? 🤨"
        end
        FileSystemCheck::fsckItemErrorArFirstFailure(item, SecureRandom.hex, true)
        item
    end

    # NxTodos::issueUsingLocation(location)
    def self.issueUsingLocation(location)
        description = File.basename(location)
        uuid        = SecureRandom.uuid
        nx11e       = Nx11E::makeStandard()
        nx113nhash  = Nx113Make::aionpoint(location)
        Items::setAttribute2(uuid, "uuid",        uuid)
        Items::setAttribute2(uuid, "mikuType",    "NxTodo")
        Items::setAttribute2(uuid, "unixtime",    Time.new.to_i)
        Items::setAttribute2(uuid, "datetime",    Time.new.utc.iso8601)
        Items::setAttribute2(uuid, "description", description)
        Items::setAttribute2(uuid, "nx113",       nx113nhash)
        Items::setAttribute2(uuid, "nx11e",       nx11e)
        item = Items::getItemOrNull(uuid)
        if item.nil? then
            raise "(error: ec1f1b6f-62b4-4426-bfe3-439a51cf76d4) How did that happen ? 🤨"
        end
        FileSystemCheck::fsckItemErrorArFirstFailure(item, SecureRandom.hex, true)
        item
    end

    # NxTodos::issueUsingUrl(url)
    def self.issueUsingUrl(url)
        description = File.basename(location)
        uuid        = SecureRandom.uuid
        nx11e       = Nx11E::makeStandard()
        nx113nhash  = Nx113Make::url(url)
        Items::setAttribute2(uuid, "uuid",        uuid)
        Items::setAttribute2(uuid, "mikuType",    "NxTodo")
        Items::setAttribute2(uuid, "unixtime",    Time.new.to_i)
        Items::setAttribute2(uuid, "datetime",    Time.new.utc.iso8601)
        Items::setAttribute2(uuid, "description", description)
        Items::setAttribute2(uuid, "nx113",       nx113nhash)
        Items::setAttribute2(uuid, "nx11e",       nx11e)
        item = Items::getItemOrNull(uuid)
        if item.nil? then
            raise "(error: ec1f1b6f-62b4-4426-bfe3-439a51cf76d4) How did that happen ? 🤨"
        end
        FileSystemCheck::fsckItemErrorArFirstFailure(item, SecureRandom.hex, true)
        item
    end

    # --------------------------------------------------
    # Data

    # NxTodos::toString(item)
    def self.toString(item)
        cx22str = item["cx22"] ? " #{Cx22::toString(item["cx22"]).green}" : ""
        cx23str = item["cx23"] ? " (pos: #{"%6.2f" % item["cx23"]["position"]})" : ""
        "(todo)#{cx23str} #{Nx11E::toString(item["nx11e"])} #{item["description"]}#{Nx113Access::toStringOrNull(" ", item["nx113"], "")}#{cx22str}".strip.gsub("(todo) (standard)", "(todo)")
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
        Nx11E::priorityOrNull(item["nx11e"], item["cx22"])
    end

    # NxTodos::itemsInDisplayOrder(cx22Opt)
    def self.itemsInDisplayOrder(cx22Opt)

        # If cx22 is set, then we present the items with a cx23 first (in position order), and then
        # the ones without a cx23 in unixtime order

        # If cx22 is not set, we present items without a cx22 in unixtime order

        if cx22Opt then
            cx22 = cx22Opt
            items = Items::mikuTypeToItems("NxTodo")
                .select{|item| item["cx22"] and (item["cx22"]["groupuuid"] == cx22["groupuuid"]) }

            items1, items2 = items.partition{|item| item["cx23"] }
            items1 = items1.sort{|i1, i2| i1["cx23"]["position"] <=> i2["cx23"]["position"] }
            items2 = items2.sort{|i1, i2| i1["unixtime"] <=> i2["unixtime"] }
            items1 + items2
        else
            Items::mikuTypeToItems("NxTodo")
                .select{|item| item["cx22"].nil? }
                .sort{|p1, p2| p1["unixtime"] <=> p2["unixtime"] }
        end
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
            PolyPrograms::itemLanding(item)
        }
    end
end

# encoding: UTF-8

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
        # We are only taking account of the position within a group and not the group itself
        # because we are displaying only one group at a time.
        Nx11E::priorityOrNull(item["nx11e"], item["cx23"])
    end

    # NxTodos::listingItems(cx22Opt)
    def self.listingItems(cx22Opt)
        items = []
        if cx22Opt then
            cx22 = cx22Opt
            items = items + NxTodos::items()
                            .select{|item| item["cx22"] }
                            .select{|item| item["cx22"]["groupuuid"] == cx22["groupuuid"] }
        end
        items = items + NxTodos::items()
                            .select{|item| item["cx22"].nil? }
        items
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

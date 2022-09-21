# encoding: UTF-8

class NxTodos

    # NxTodos::items()
    def self.items()
        Items::mikuTypeToItems("NxTodo")
    end

    # NxTodos::destroy(uuid)
    def self.destroy(uuid)
        ItemsEventsLog::deleteObject(uuid)
    end

    # --------------------------------------------------
    # Makers

    # NxTodos::interactivelyCreateNewOrNull()
    def self.interactivelyCreateNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid       = SecureRandom.uuid
        nx113nhash = Nx113Make::interactivelyIssueNewNx113OrNullReturnDataBase1Nhash()
        nx11e      = Nx11E::interactivelyCreateNewNx11EOrNull(uuid)
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
        item
    end

    # --------------------------------------------------
    # Data

    # NxTodos::toString(item)
    def self.toString(item)
        nx11estr = item["nx11e"] ? " (#{Nx11E::toString(item["nx11e"])})" : ""
        "(todo) #{item["description"]}#{Nx113Access::toStringOrNull(" ", item["nx113"], "")}#{nx11estr}"
    end

    # NxTodos::toStringForSearch(item)
    def self.toStringForSearch(item)
        "(todo) #{item["description"]}"
    end

    # NxTodos::listingItems()
    def self.listingItems()
        Items::mikuTypeToItems("NxTodo")
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

            puts ""
            puts "description | access | start | stop | edit | done | do not show until | redate | nx113 | expose | destroy | nyx".yellow
            puts ""

            input = LucilleCore::askQuestionAnswerAsString("> ")
            next if input == ""

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
                return
            end

            if Interpreting::match("expose", input) then
                puts JSON.pretty_generate(item)
                LucilleCore::pressEnterToContinue()
                return
            end

            if Interpreting::match("nx113", input) then
                PolyActions::setNx113(item)
                return
            end

            if Interpreting::match("nyx", input) then
                Nyx::program()
                return
            end

            if Interpreting::match("redate", input) then
                PolyActions::redate(item)
                return
            end

            if Interpreting::match("start", input) then
                PolyActions::start(item)
                return
            end

            if Interpreting::match("stop", input) then
                PolyActions::stop(item)
                return
            end
        }
    end
end

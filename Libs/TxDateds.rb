# encoding: UTF-8

class TxDateds

    # TxDateds::items()
    def self.items()
        Items::mikuTypeToItems("TxDated")
    end

    # TxDateds::destroy(uuid)
    def self.destroy(uuid)
        ItemsEventsLog::deleteObject(uuid)
    end

    # --------------------------------------------------
    # Makers

    # TxDateds::interactivelyCreateNewOrNull()
    def self.interactivelyCreateNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""

        datetime = CommonUtils::interactivelySelectDateTimeIso8601OrNullUsingDateCode()
        return nil if datetime.nil?
        uuid = SecureRandom.uuid
        nx113nhash = Nx113Make::interactivelyIssueNewNx113OrNullReturnDataBase1Nhash()
        unixtime   = Time.new.to_i
        ItemsEventsLog::setAttribute2(uuid, "uuid",        uuid)
        ItemsEventsLog::setAttribute2(uuid, "mikuType",    "TxDated")
        ItemsEventsLog::setAttribute2(uuid, "unixtime",    unixtime)
        ItemsEventsLog::setAttribute2(uuid, "datetime",    datetime)
        ItemsEventsLog::setAttribute2(uuid, "description", description)
        ItemsEventsLog::setAttribute2(uuid, "nx113",       nx113nhash)
        FileSystemCheck::fsckObjectuuidErrorAtFirstFailure(uuid, SecureRandom.hex)
        item = Items::getItemOrNull(uuid)
        if item.nil? then
            raise "(error: 06f11b6f-7d31-411b-b3bf-7b1115a756a9) How did that happen ? 🤨"
        end
        item
    end

    # TxDateds::interactivelyCreateNewTodayOrNull()
    def self.interactivelyCreateNewTodayOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid = SecureRandom.uuid
        nx113nhash = Nx113Make::interactivelyIssueNewNx113OrNullReturnDataBase1Nhash()
        unixtime   = Time.new.to_i
        datetime   = Time.new.utc.iso8601
        ItemsEventsLog::setAttribute2(uuid, "uuid",        uuid)
        ItemsEventsLog::setAttribute2(uuid, "mikuType",    "TxDated")
        ItemsEventsLog::setAttribute2(uuid, "unixtime",    unixtime)
        ItemsEventsLog::setAttribute2(uuid, "datetime",    datetime)
        ItemsEventsLog::setAttribute2(uuid, "description", description)
        ItemsEventsLog::setAttribute2(uuid, "nx113",       nx113nhash)
        FileSystemCheck::fsckObjectuuidErrorAtFirstFailure(uuid, SecureRandom.hex)
        item = Items::getItemOrNull(uuid)
        if item.nil? then
            raise "(error: 69486f48-3748-4c73-b604-a7edad98871d) How did that happen ? 🤨"
        end
        item
    end

    # --------------------------------------------------
    # toString

    # TxDateds::toString(item)
    def self.toString(item)
        "(ondate) [#{item["datetime"][0, 10]}] #{item["description"]}#{Nx113Access::toStringOrNull(" ", item["nx113"], "")} 🗓"
    end

    # TxDateds::toStringForSearch(item)
    def self.toStringForSearch(item)
        "(ondate) #{item["description"]}"
    end

    # --------------------------------------------------
    # Operations

    # TxDateds::dive()
    def self.dive()
        loop {
            system("clear")
            items = TxDateds::items().sort{|i1, i2| i1["datetime"] <=> i2["datetime"] }
            item = LucilleCore::selectEntityFromListOfEntitiesOrNull("dated", items, lambda{|item| TxDateds::toString(item) })
            break if item.nil?
            PolyPrograms::itemLanding(item)
        }
    end

    # TxDateds::access(item)
    def self.access(item)
        puts TxDateds::toString(item).green
        if item["nx113"] then
            Nx113Access::access(item["nx113"])
        end
    end

    # TxDateds::edit(item)
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
        Nx113Access::access(item["nx113"])
        item
    end

    # TxDateds::landing(item)
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
                PolyFunctions::edit(item)
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

    # --------------------------------------------------
    # 

    # TxDateds::listingItems()
    def self.listingItems()
        TxDateds::items()
            .select{|item| item["datetime"][0, 10] <= CommonUtils::today() }
            .sort{|i1, i2| i1["datetime"] <=> i2["datetime"] }
    end
end

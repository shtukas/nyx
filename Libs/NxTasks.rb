# encoding: UTF-8

class NxTasks

    # NxTasks::items()
    def self.items()
        Items::mikuTypeToItems("NxTask")
    end

    # NxTasks::destroy(uuid)
    def self.destroy(uuid)
        ItemsEventsLog::deleteObject(uuid)
    end

    # --------------------------------------------------
    # Makers

    # NxTasks::interactivelyCreateNewOrNull(shouldPromptForTimeCommitment)
    def self.interactivelyCreateNewOrNull(shouldPromptForTimeCommitment)
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid = SecureRandom.uuid
        nx113nhash = Nx113Make::interactivelyIssueNewNx113OrNullReturnDataBase1Nhash()
        ax39 = nil
        if shouldPromptForTimeCommitment and LucilleCore::askQuestionAnswerAsBoolean("Attach a Ax39 (time commitment) ? ", false) then
            ax39 = Ax39::interactivelyCreateNewAxOrNull()
        end
        ItemsEventsLog::setAttribute2(uuid, "uuid",        uuid)
        ItemsEventsLog::setAttribute2(uuid, "mikuType",    "NxTask")
        ItemsEventsLog::setAttribute2(uuid, "unixtime",    Time.new.to_i)
        ItemsEventsLog::setAttribute2(uuid, "datetime",    Time.new.utc.iso8601)
        ItemsEventsLog::setAttribute2(uuid, "description", description)
        ItemsEventsLog::setAttribute2(uuid, "nx113",       nx113nhash)
        ItemsEventsLog::setAttribute2(uuid, "ax39",        ax39)
        FileSystemCheck::fsckObjectuuidErrorAtFirstFailure(uuid, SecureRandom.hex)
        item = Items::getItemOrNull(uuid)
        if item.nil? then
            raise "(error: ec1f1b6f-62b4-4426-bfe3-439a51cf76d4) How did that happen ? 🤨"
        end
        item
    end

    # NxTasks::interactivelyIssueDescriptionOnlyOrNull()
    def self.interactivelyIssueDescriptionOnlyOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        NxTasks::issueDescriptionOnly(description)
    end

    # NxTasks::issueViennaURL(url)
    def self.issueViennaURL(url)
        uuid        = SecureRandom.uuid
        description = "(vienna) #{url}"
        nx113nhash  = Nx113Make::url(url)
        ItemsEventsLog::setAttribute2(uuid, "uuid",        uuid)
        ItemsEventsLog::setAttribute2(uuid, "mikuType",    "NxTask")
        ItemsEventsLog::setAttribute2(uuid, "unixtime",    Time.new.to_i)
        ItemsEventsLog::setAttribute2(uuid, "datetime",    Time.new.utc.iso8601)
        ItemsEventsLog::setAttribute2(uuid, "description", description)
        ItemsEventsLog::setAttribute2(uuid, "nx113",       nx113nhash)
        FileSystemCheck::fsckObjectuuidErrorAtFirstFailure(uuid, SecureRandom.hex)
        item = Items::getItemOrNull(uuid)
        if item.nil? then
            raise "(error: f78008bf-12d4-4483-b4bb-96e3472d46a2) How did that happen ? 🤨"
        end
        item
    end

    # NxTasks::issueUsingLocation(location)
    def self.issueUsingLocation(location)
        if !File.exists?(location) then
            raise "(error: 52b8592f-a61a-45ef-a886-ed2ab4cec5ed)"
        end
        description = File.basename(location)
        uuid = SecureRandom.uuid
        nx113nhash  = Nx113Make::aionpoint(location)
        ItemsEventsLog::setAttribute2(uuid, "uuid",        uuid)
        ItemsEventsLog::setAttribute2(uuid, "mikuType",    "NxTask")
        ItemsEventsLog::setAttribute2(uuid, "unixtime",    Time.new.to_i)
        ItemsEventsLog::setAttribute2(uuid, "datetime",    Time.new.utc.iso8601)
        ItemsEventsLog::setAttribute2(uuid, "description", description)
        ItemsEventsLog::setAttribute2(uuid, "nx113",       nx113nhash)
        FileSystemCheck::fsckObjectuuidErrorAtFirstFailure(uuid, SecureRandom.hex)
        item = Items::getItemOrNull(uuid)
        if item.nil? then
            raise "(error: 7938316c-cb54-4d60-a480-f161f19718ef) How did that happen ? 🤨"
        end
        item
    end

    # NxTasks::issueDescriptionOnly(description)
    def self.issueDescriptionOnly(description)
        uuid  = SecureRandom.uuid
        ItemsEventsLog::setAttribute2(uuid, "uuid",        uuid)
        ItemsEventsLog::setAttribute2(uuid, "mikuType",    "NxTask")
        ItemsEventsLog::setAttribute2(uuid, "unixtime",    Time.new.to_i)
        ItemsEventsLog::setAttribute2(uuid, "datetime",    Time.new.utc.iso8601)
        ItemsEventsLog::setAttribute2(uuid, "description", description)
        FileSystemCheck::fsckObjectuuidErrorAtFirstFailure(uuid, SecureRandom.hex)
        item = Items::getItemOrNull(uuid)
        if item.nil? then
            raise "(error: 5ea6abff-1007-4bd5-ab61-bde26c621a8b) How did that happen ? 🤨"
        end
        item
    end

    # --------------------------------------------------
    # Data

    # NxTasks::toString(item)
    def self.toString(item)
        ax39str = Ax39Extensions::toString2OrNull(item["ax39"], item["uuid"])
        ax39str = ax39str ? " #{ax39str}" : ""
        "(task)#{Nx113Access::toStringOrNull(" ", item["nx113"], "")} #{item["description"]}#{ax39str}"
    end

    # NxTasks::toStringForSearch(item)
    def self.toStringForSearch(item)
        "(task) #{item["description"]}"
    end

    # NxTasks::cacheduuidsForListingItems1()
    def self.cacheduuidsForListingItems1()
        key = "baf670c7-20c2-497d-aa50-9ac71f682019"
        itemuuids = XCacheValuesWithExpiry::getOrNull(key)
        return itemuuids if itemuuids

        # Items not time commitments and without an owner
        itemuuids = Items::mikuTypeToItems("NxTask")
                        .select{|item| item["ax39"].nil? }
                        .sort{|i1, i2| i1["unixtime"] <=> i2["unixtime"] }
                        .select{|item| TimeCommitmentMapping::elementuuidToOwnersuuids(item["uuid"]).empty? }
                        .first(200)
                        .map{|item| item["uuid"] }

        XCacheValuesWithExpiry::set(key, itemuuids, 86400)
        itemuuids
    end

    # NxTasks::cacheduuidsForListingItems2()
    def self.cacheduuidsForListingItems2()
        key = "a13c22c2-468a-412e-902c-62abc030b925"
        itemuuids = XCacheValuesWithExpiry::getOrNull(key)
        return itemuuids if itemuuids

        # Items not time commitments and without an owner
        itemuuids = Items::mikuTypeToItems("NxTask")
                        .select{|item| item["ax39"] }
                        .sort{|i1, i2| i1["unixtime"] <=> i2["unixtime"] }
                        .map{|item| item["uuid"] }

        XCacheValuesWithExpiry::set(key, itemuuids, 3600)
        itemuuids
    end

    # NxTasks::listingItems1()
    def self.listingItems1()
        NxTasks::cacheduuidsForListingItems1()
            .map{|itemuuid| Items::getItemOrNull(itemuuid) }
            .compact
    end

    # NxTasks::listingItems2TimeCommitments()
    def self.listingItems2TimeCommitments()
        NxTasks::cacheduuidsForListingItems2()
            .map{|itemuuid| Items::getItemOrNull(itemuuid) }
            .compact
    end

    # --------------------------------------------------
    # Operations

    # NxTasks::access(item)
    def self.access(item)
        puts NxTasks::toString(item).green
        if item["nx113"] then
            Nx113Access::access(item["nx113"])
        end
    end

    # NxTasks::edit(item) # item
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

    # NxTasks::landing(item)
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

# encoding: UTF-8

class NxOndates

    # --------------------------------------------------
    # Makers

    # NxOndates::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid  = SecureRandom.uuid
        nx113 = Nx113Make::interactivelyMakeNx113OrNull()
        datetime = CommonUtils::interactivelySelectDateTimeIso8601UsingDateCode()
        item = {
            "uuid"        => uuid,
            "mikuType"    => "NxOndate",
            "unixtime"    => Time.new.to_i,
            "datetime"    => datetime,
            "description" => description,
            "nx113"       => nx113,
        }
        TodoDatabase2::commit_item(item)
        item
    end

    # NxOndates::interactivelyIssueNewTodayOrNull()
    def self.interactivelyIssueNewTodayOrNull()
        description = LucilleCore::askQuestionAnswerAsString("today (empty to abort): ")
        return nil if description == ""
        uuid  = SecureRandom.uuid
        nx113 = Nx113Make::interactivelyMakeNx113OrNull()
        item = {
            "uuid"        => uuid,
            "mikuType"    => "NxOndate",
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "description" => description,
            "nx113"       => nx113,
        }
        TodoDatabase2::commit_item(item)
        item
    end

    # NxOndates::viennaUrlForToday(url)
    def self.viennaUrlForToday(url)
        description = "(vienna) #{url}"
        uuid  = SecureRandom.uuid
        nx113 = Nx113Make::url(url)
        item = {
            "uuid"        => uuid,
            "mikuType"    => "NxOndate",
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "description" => description,
            "nx113"       => nx113,
        }
        TodoDatabase2::commit_item(item)
        item
    end

    # --------------------------------------------------
    # Data

    # NxOndates::toString(item)
    def self.toString(item)
        nx113str = Nx113Access::toStringOrNull(" ", item["nx113"], "")
        "(ondate: #{item["datetime"][0, 10]}) #{item["description"]}#{nx113str}"
    end

    # NxOndates::listingItems()
    def self.listingItems()
        TodoDatabase2::itemsForMikuType("NxOndate").select{|item| item["datetime"][0, 10] <= Time.new.to_s[0, 10] }
    end

    # --------------------------------------------------
    # Operations

    # NxOndates::access(item)
    def self.access(item)
        puts NxOndates::toString(item).green
        if item["nx113"] then
            Nx113Access::access(item["nx113"])
        end
    end

    # NxOndates::edit(item) # item
    def self.edit(item)
        if item["nx113"].nil? then
            puts "This item doesn't have a Nx113 attached to it"
            status = LucilleCore::askQuestionAnswerAsBoolean("Would you like to edit the description instead ? ")
            if status then
                PolyActions::editDescription(item)
                return TodoDatabase2::getObjectByUUIDOrNull(item["uuid"])
            else
                return item
            end
        end
        Nx113Edit::editNx113Carrier(item)
        TodoDatabase2::getObjectByUUIDOrNull(item["uuid"])
    end

    # NxOndates::probe(item)
    def self.probe(item)
        loop {
            item = TodoDatabase2::getObjectByUUIDOrNull(item["uuid"])
            actions = ["access", "redate", "transmute", "destroy"]
            action = LucilleCore::selectEntityFromListOfEntitiesOrNull("action: ", actions)
            return if action.nil?
            if action == "access" then
                NxOndates::access(item)
                next
            end
            if action == "transmute" then
                Transmutations::transmute2(item)
                return
            end
            if action == "redate" then
                item["datetime"] = CommonUtils::interactivelySelectDateTimeIso8601UsingDateCode()
                TodoDatabase2::commit_item(item)
                next
            end
            if action == "destroy" then
                TodoDatabase2::destroy(item["uuid"])
                return
            end
        }
    end

    # NxOndates::report()
    def self.report()
        system("clear")
        puts "ondates:"
        TodoDatabase2::itemsForMikuType("NxOndate")
            .sort{|i1, i2| i1["datetime"] <=> i2["datetime"]}
            .each{|item| puts NxOndates::toString(item) }
        LucilleCore::pressEnterToContinue()
    end
end

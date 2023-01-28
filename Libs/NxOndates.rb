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
        TodoDatabase2::commitItem(item)
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
        TodoDatabase2::commitItem(item)
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
        TodoDatabase2::commitItem(item)
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
        Database2Data::itemsForMikuType("NxOndate").select{|item| item["datetime"][0, 10] <= Time.new.to_s[0, 10] }
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

    # NxOndates::report()
    def self.report()
        system("clear")
        puts "ondates:"
        Database2Data::itemsForMikuType("NxOndate")
            .sort{|i1, i2| i1["datetime"] <=> i2["datetime"]}
            .each{|item| puts NxOndates::toString(item) }
        LucilleCore::pressEnterToContinue()
    end
end

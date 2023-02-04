# encoding: UTF-8

class NxTodos

    # NxTodos::items()
    def self.items()
        Engine::itemsForMikuType("NxTodo")
    end

    # --------------------------------------------------
    # Makers

    # NxTodos::interactivelyIssueNewRegularOrNull()
    def self.interactivelyIssueNewRegularOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid  = SecureRandom.uuid
        nx113 = Nx113Make::interactivelyMakeNx113OrNull()
        item = {
            "uuid"        => uuid,
            "mikuType"    => "NxTodo",
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "description" => description,
            "nx113"       => nx113,
            "field2"      => "regular"
        }
        ObjectStore1::commitItem(item)
        item
    end

    # NxTodos::interactivelyIssueNewOndateOrNull()
    def self.interactivelyIssueNewOndateOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description (empty to abort): ")
        return nil if description == ""
        uuid  = SecureRandom.uuid
        nx113 = Nx113Make::interactivelyMakeNx113OrNull()
        datetime = CommonUtils::interactivelySelectDateTimeIso8601UsingDateCode()
        item = {
            "uuid"        => uuid,
            "mikuType"    => "NxTodo",
            "unixtime"    => Time.new.to_i,
            "datetime"    => datetime,
            "description" => description,
            "nx113"       => nx113,
            "field2"      => "ondate"
        }
        ObjectStore1::commitItem(item)
        item
    end

    # NxTodos::interactivelyIssueNewTodayOrNull()
    def self.interactivelyIssueNewTodayOrNull()
        description = LucilleCore::askQuestionAnswerAsString("today (empty to abort): ")
        return nil if description == ""
        uuid  = SecureRandom.uuid
        nx113 = Nx113Make::interactivelyMakeNx113OrNull()
        item = {
            "uuid"        => uuid,
            "mikuType"    => "NxTodo",
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "description" => description,
            "nx113"       => nx113,
            "field2"      => "ondate"
        }
        ObjectStore1::commitItem(item)
        item
    end

    # NxTodos::viennaUrlForToday(url)
    def self.viennaUrlForToday(url)
        description = "(vienna) #{url}"
        uuid  = SecureRandom.uuid
        nx113 = Nx113Make::url(url)
        item = {
            "uuid"        => uuid,
            "mikuType"    => "NxTodo",
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "description" => description,
            "nx113"       => nx113,
            "field2"      => "ondate"
        }
        ObjectStore1::commitItem(item)
        item
    end

    # NxTodos::bufferInImport(location)
    def self.bufferInImport(location)
        description = File.basename(location)
        uuid = SecureRandom.uuid
        nx113 = Nx113Make::aionpoint(location)
        item = {
            "uuid"        => uuid,
            "mikuType"    => "NxTodo",
            "unixtime"    => Time.new.to_i,
            "datetime"    => Time.new.utc.iso8601,
            "description" => description,
            "nx113"       => nx113,
            "field2"      => "triage"
        }
        ObjectStore1::commitItem(item)
        item
    end

    # --------------------------------------------------
    # Data

    # NxTodos::toString(item)
    def self.toString(item)
        flavour = (lambda {|item|
            return "" if item["field2"] == "regular"
            return ", ondate #{item["datetime"][0, 10]}" if item["field2"] == "ondate"
            return ", triage" if item["field2"] == "triage"
            raise "(error: ca9b365a-2e14-4523-8df9-fe2d6a6dd5f4) #{item}"
        }).call(item)
        nx113str = Nx113Access::toStringOrNull(" ", item["nx113"], "")
        "(todo#{flavour}) #{item["description"]}#{nx113str}"
    end

    # NxTodos::toStringForSearch(item)
    def self.toStringForSearch(item)
        "(todo) #{item["description"]}"
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

    # NxTodos::ondateReport()
    def self.ondateReport()
        system("clear")
        puts "ondates:"
        Engine::itemsForMikuType("NxTodo")
            .select{|item| item["field2"] == "ondate" }
            .sort{|i1, i2| i1["datetime"] <=> i2["datetime"] }
            .each{|item|
                puts NxTodos::toString(item)
            }
        LucilleCore::pressEnterToContinue()
    end

    # NxTodos::doneprocess(item)
    def self.doneprocess(item)
        puts PolyFunctions::toString(item)
        if LucilleCore::askQuestionAnswerAsBoolean("destroy NxTodo '#{item["description"].green}' ? ", true) then
            if item["nx113"] then
                puts "You are attempting to done a NxTodo which carries some contents (Nx113)"
                option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", ["destroy", "exit"])
                return if option == ""
                if option == "destroy" then
                    ObjectStore1::destroy(item["uuid"])
                    return
                end
                if option == "exit" then
                    return
                end
                return
            else
                ObjectStore1::destroy(item["uuid"])
            end
        end
    end
end

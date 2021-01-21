
class Calendar

    # Calendar::pathToCalendarItems()
    def self.pathToCalendarItems()
        "/Users/pascal/Galaxy/Calendar/Calendar"
    end

    # Calendar::today()
    def self.today()
        Time.new.to_s[0, 10]
    end

    # Calendar::dates()
    def self.dates()
        Dir.entries(Calendar::pathToCalendarItems())
            .select{|filename| filename[-4, 4] == ".txt" }
            .sort
            .map{|filename| filename[0, 10] }
    end

    # Calendar::dateToFilepath(date)
    def self.dateToFilepath(date)
        "#{Calendar::pathToCalendarItems()}/#{date}.txt"
    end

    # Calendar::filePathToCatalystObject(date, indx)
    def self.filePathToCatalystObject(date, indx)
        filepath = Calendar::dateToFilepath(date)
        content = IO.read(filepath).strip
        uuid = "8413-9d175a593282-#{date}"
        {
            "uuid"     => uuid,
            "body"     => "🗓️  " + date + "\n" + content,
            "metric"   => KeyValueStore::flagIsTrue(nil, "63bbe86e-15ae-4c0f-93b9-fb1b66278b00:#{Time.new.to_s[0, 10]}:#{date}") ? 0 : 0.93 - indx.to_f/10000,
            "landing"  => lambda { Calendar::execute(date) },
            "nextNaturalStep" => lambda { Calendar::setDateAsReviewed(date) },
            "x-calendar-date" => date
        }
    end

    # Calendar::catalystObjects()
    def self.catalystObjects()
        Calendar::dates()
            .each{|date|
                filepath = Calendar::dateToFilepath(date)
                content = IO.read(filepath).strip
                next if content.size > 0
                FileUtils.rm(filepath)
            }

        Calendar::dates()
            .map
            .with_index{|date, indx| Calendar::filePathToCatalystObject(date, indx) }
    end

    # Calendar::setDateAsReviewed(date)
    def self.setDateAsReviewed(date)
        KeyValueStore::setFlagTrue(nil, "63bbe86e-15ae-4c0f-93b9-fb1b66278b00:#{Time.new.to_s[0, 10]}:#{date}")
    end

    # Calendar::execute(date)
    def self.execute(date)
        options = ["reviewed", "open"]
        option = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", options)
        return if option.nil?
        if option == "reviewed" then
            Calendar::setDateAsReviewed(date)
        end
        if option == "open" then
            filepath = Calendar::dateToFilepath(date)
            system("open '#{filepath}'")
        end
    end

    # -----------------------------------------------------------------------

    # Calendar::calendarItems()
    def self.calendarItems()
        NSCoreObjects::getSet("a2d0f91c-9cd5-4223-b633-21cd540aa5c9")
    end

    # Calendar::toString(item)
    def self.toString(item)
        element = StandardDataCarriersInterface::getCarrierOrNull(item["StandardDataCarrierUUID"])
        elementToString = element ? StandardDataCarriersInterface::toString(element) : "element not found"
        "[calendar] #{item["date"]} #{elementToString}"
    end

    # Calendar::landing(item)
    def self.landing(item)
        loop {
            system("clear")
            mx = LCoreMenuItemsNX1.new()
            puts Calendar::toString(item).green
            mx.item("access data carrier".yellow, lambda { 
                element = StandardDataCarriersInterface::getCarrierOrNull(item["StandardDataCarrierUUID"])
                return if element.nil?
                StandardDataCarriersInterface::landing(element)
            })
            mx.item("update date".yellow, lambda { 
                item["date"] = LucilleCore::askQuestionAnswerAsString("date: ")
                NSCoreObjects::put(item)
            })
            mx.item("destroy".yellow, lambda { 
                NSCoreObjects::destroy(item)
            })
            status = mx.promptAndRunSandbox()
            break if !status
        }        
    end

    # Calendar::diveCalendarItems()
    def self.diveCalendarItems()
        loop {
            system("clear")
            mx = LCoreMenuItemsNX1.new()
            Calendar::calendarItems().each{|item|
                mx.item(Calendar::toString(item), lambda { 
                    Calendar::landing(item)
                })
            }
            status = mx.promptAndRunSandbox()
            break if !status
        }
    end

    # Calendar::interactivelyIssueNewCalendarItemOrNull()
    def self.interactivelyIssueNewCalendarItemOrNull()
        element = StandardDataCarriersInterface::interactivelyIssueNewDataCarrierOrNull()
        return if element.nil?
        item = {
            "uuid"     => SecureRandom.hex,
            "nyxNxSet" => "a2d0f91c-9cd5-4223-b633-21cd540aa5c9",
            "unixtime" => Time.new.to_i,
            "date"     => LucilleCore::askQuestionAnswerAsString("date: "),
            "StandardDataCarrierUUID" => element["uuid"]
        }
        NSCoreObjects::put(item)
    end

    # Calendar::main()
    def self.main()
        loop {
            system("clear")
            mx = LCoreMenuItemsNX1.new()
            mx.item("dive into calendar".yellow, lambda { 
                Calendar::diveCalendarItems()
            })
            mx.item("make new calendar item".yellow, lambda { 
                Calendar::interactivelyIssueNewCalendarItemOrNull() 
            })
            status = mx.promptAndRunSandbox()
            break if !status
        }
    end
end



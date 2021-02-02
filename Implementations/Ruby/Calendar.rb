
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

    # Calendar::displayItemsNS16()
    def self.displayItemsNS16()
        [
            Calendar::dates()
                .select{|date| !KeyValueStore::flagIsTrue(nil, "63bbe86e-15ae-4c0f-93b9-fb1b66278b00:#{Time.new.to_s[0, 10]}:#{date}") }
                .map{|date| 
                    filepath = Calendar::dateToFilepath(date)
                    content = IO.read(filepath).strip
                    {
                        "uuid"     => "cba62d9e-cacc-4e95-a8f2-6cfb72efbf39:#{date}",
                        "announce" => "🗓️  " + date + "\n" + content,
                        "lambda"   => lambda {
                            if LucilleCore::askQuestionAnswerAsBoolean("mark as reviewed ? ") then
                                KeyValueStore::setFlagTrue(nil, "63bbe86e-15ae-4c0f-93b9-fb1b66278b00:#{Time.new.to_s[0, 10]}:#{date}")
                            end
                        }
                    }
                },

            Calendar::calendarItems()
                .sort{|i1, i2| i1["date"]<=>i2["date"] }
                .map{|item|
                    {
                        "uuid"     => item["uuid"],
                        "announce" => Calendar::toString(item),
                        "lambda"   => lambda{}
                    }
                }
        ].flatten
    end

    # -----------------------------------------------------------------------

    # Calendar::calendarItems()
    def self.calendarItems()
        NSCoreObjects::getSet("a2d0f91c-9cd5-4223-b633-21cd540aa5c9")
    end

    # Calendar::toString(item)
    def self.toString(item)
        "[calendar] #{item["date"]} #{NereidInterface::toString(item["StandardDataCarrierUUID"])}"
    end

    # Calendar::landing(item)
    def self.landing(item)
        loop {
            system("clear")

            return if NSCoreObjects::getOrNull(item["uuid"]).nil?
            item = NSCoreObjects::getOrNull(item["uuid"]) # could have been transmuted in the previous loop

            mx = LCoreMenuItemsNX1.new()
            puts Calendar::toString(item).green
            mx.item("data carrier landing".yellow, lambda { 
                element = NereidInterface::getElementOrNull(item["StandardDataCarrierUUID"])
                return if element.nil?
                NereidInterface::landing(element)
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
        element = NereidInterface::interactivelyIssueNewElementOrNull()
        return if element.nil?
        item = {
            "uuid"     => SecureRandom.hex,
            "nyxNxSet" => "a2d0f91c-9cd5-4223-b633-21cd540aa5c9",
            "unixtime" => Time.new.to_i,
            "date"     => LucilleCore::askQuestionAnswerAsString("date: "),
            "StandardDataCarrierUUID" => element["uuid"]
        }
        NSCoreObjects::put(item)
        NereidInterface::setOwnership(element["uuid"], "catalyst")
        item
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




class Calendar

    # -----------------------------------------------------------------------

    # Calendar::calendarItems()
    def self.calendarItems()
        TodoCoreData::getSet("a2d0f91c-9cd5-4223-b633-21cd540aa5c9")
    end

    # Calendar::toString(item)
    def self.toString(item)
        "[calendar] #{item["date"]} #{NereidInterface::toString(item["StandardDataCarrierUUID"])}"
    end

    # Calendar::displayItemsNS16()
    def self.displayItemsNS16()
        Calendar::calendarItems()
            .sort{|i1, i2| i1["date"]<=>i2["date"] }
            .map{|item|
                {
                    "uuid"     => item["uuid"],
                    "announce" => Calendar::toString(item),
                    "lambda"   => lambda{}
                }
            }
    end

    # Calendar::landing(item)
    def self.landing(item)
        loop {
            system("clear")

            return if TodoCoreData::getOrNull(item["uuid"]).nil?
            item = TodoCoreData::getOrNull(item["uuid"]) # could have been transmuted in the previous loop

            mx = LCoreMenuItemsNX1.new()
            puts Calendar::toString(item).green
            mx.item("data carrier landing".yellow, lambda { 
                element = NereidInterface::getElementOrNull(item["StandardDataCarrierUUID"])
                return if element.nil?
                NereidInterface::landing(element)
            })
            mx.item("update date".yellow, lambda { 
                item["date"] = LucilleCore::askQuestionAnswerAsString("date: ")
                TodoCoreData::put(item)
            })
            mx.item("destroy".yellow, lambda { 
                TodoCoreData::destroy(item)
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
        TodoCoreData::put(item)
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



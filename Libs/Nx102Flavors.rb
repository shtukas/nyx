
# encoding: UTF-8

class Nx102Flavor

    # Nx102Flavor::interactivelyCreateNewFlavour()
    def self.interactivelyCreateNewFlavour()
        types = [
            "encyclopedia (default)",
            "of-interest-from-the-web",
            "calendar-item",
            "public-event",
            "pascal-personal-note"
        ]
        type = LucilleCore::selectEntityFromListOfEntitiesOrNull("flavor type", types)
        if type.nil? then
            return {
                "type" => "encyclopedia"
            }
        end
        if type == "encyclopedia (default)" then
            return {
                "type" => "encyclopedia"
            }
        end
        if type == "of-interest-from-the-web" then
            return {
                "type" => "of-interest-from-the-web"
            }
        end
        if type == "calendar-item" then
            calendarDate = LucilleCore::askQuestionAnswerAsString("calendarDate (format: YYYY-MM-DD) : ")
            calendarTime = LucilleCore::askQuestionAnswerAsString("calendarTime (format: HH:MM) : ")
            active = true
            return {
                "type"         => "calendar-item",
                "calendarDate" => calendarDate,
                "calendarTime" => calendarTime,
                "active"       => active
            }
        end
        if type == "public-event" then
            eventDate = LucilleCore::askQuestionAnswerAsString("eventDate (format: YYYY-MM-DD) : ")
            return {
                "type"      => "public-event",
                "eventDate" => eventDate
            }
        end
        if type == "pascal-personal-note" then
            return {
                "type" => "pascal-personal-note"
            }
        end
    end
end

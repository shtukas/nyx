
# encoding: UTF-8

class Nx102Flavor

    # Nx102Flavor::interactivelySelectFlavourTypeOrNull()
    def self.interactivelySelectFlavourTypeOrNull()
        types = [
            "encyclopedia (default)",
            "of-interest-from-the-web",
            "calendar-item",
            "pascal-personal-note",
            "limited-scope-event",
            "public-event"
        ]
        LucilleCore::selectEntityFromListOfEntitiesOrNull("flavor type", types)
    end

    # Nx102Flavor::interactivelyCreateNewFlavour()
    def self.interactivelyCreateNewFlavour()
        type = Nx102Flavor::interactivelySelectFlavourTypeOrNull()
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
        if type == "limited-scope-event" then
            return {
                "type" => "limited-scope-event"
            }
        end
        raise "(error: afcc7f96-5552-4639-ba3e-d6f03287371c) type: #{type}"
    end
end

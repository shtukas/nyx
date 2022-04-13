
class LxFunction

    # LxFunction::function(command, object or nil)
    def self.function(command, object)

        return if command.nil?

        if object and object["mikuType"].nil? then
            puts "Objects sent to LxFunction if not null should have a mikuType attribute."
            puts "Got:"
            puts JSON.pretty_generate(object)
            puts "Aborting."
            exit
        end

        if command == "description" then
            if object["mikuType"] == "TxTodo" then
                return object["description"]
            end
            if object["mikuType"] == "Nx31" then
                return object["description"]
            end
            if object["mikuType"] == "TxFloat" then
                return object["description"]
            end
        end

        if command == "toString" then
            if object["mikuType"] == "Nx25" then
                return Nx25s::toString(object)
            end

            if object["mikuType"] == "Nx31" then
                return Nx31s::toString(object)
            end

            if object["mikuType"] == "Nx45" then
                return Nx45s::toString(object)
            end

            if object["mikuType"] == "Nx51" then
                return Nx51s::toString(object)
            end

            if object["mikuType"] == "Nx47CalendarItem" then
                return Nx47CalendarItems::toString(object)
            end

            if object["mikuType"] == "Nx48PublicEvent" then
                return Nx48PublicEvents::toString(object)
            end

            if object["mikuType"] == "Nx49PascalPersonalNote" then
                return Nx49PascalPersonalEvents::toString(object)
            end
        end

        puts "I do not know how to LxFunction::function (command: #{command}, object: #{JSON.pretty_generate(object)})"
        puts "Aborting."
        exit
    end
end
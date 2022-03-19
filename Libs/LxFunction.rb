
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

        if command == "toString" then
            if object["mikuType"] == "Nx31" then
                return Nx31s::toString(object)
            end

            if object["mikuType"] == "Nx47CalendarItem" then
                return Nx47CalendarItems::toString(object)
            end

            if object["mikuType"] == "Nx48TimedPublicEvent" then
                return Nx48TimedPublicEvents::toString(object)
            end

            if object["mikuType"] == "Nx49PascalPrivateLog" then
                return Nx49PascalPersonalEvents::toString(object)
            end
        end

        puts "I do not know how to do function (command: #{command}, object: #{JSON.pretty_generate(object)})"
        puts "Aborting."
        exit
    end
end
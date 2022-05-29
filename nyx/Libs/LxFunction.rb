
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
            if object["mikuType"] == "Nx100" then
                return object["description"]
            end
        end

        if command == "toString" then
            if object["mikuType"] == "Nx100" then
                return Nx100s::toString(object)
            end
        end

        puts "I do not know how to LxFunction::function (command: #{command}, object: #{JSON.pretty_generate(object)})"
        puts "Aborting."
        exit
    end
end
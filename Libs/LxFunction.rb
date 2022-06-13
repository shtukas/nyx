
class LxFunction

    # LxFunction::function(command, item or nil)
    def self.function(command, item)

        return if command.nil?

        if item and item["mikuType"].nil? then
            puts "Objects sent to LxFunction if not null should have a mikuType attribute."
            puts "Got:"
            puts JSON.pretty_generate(item)
            puts "Aborting."
            exit
        end

        if command == "toString" then
            if item["mikuType"] == "(rstream)" then
                return item["announce"]
            end
            if item["mikuType"] == "fitness1" then
                return item["announce"]
            end
            if item["mikuType"] == "Anniversary" then
                return Anniversaries::toString(item)
            end
            if item["mikuType"] == "NxDataNode" then
                return NxDataNodes::toString(item)
            end          
            if item["mikuType"] == "NxTimeline" then
                return NxTimelines::toString(item)
            end
            if item["mikuType"] == "TxDated" then
                return TxDateds::toString(item)
            end
            if item["mikuType"] == "TxZero" then
                return TxZero::toString(item)
            end
            if item["mikuType"] == "TxTodo" then
                return TxTodos::toString(item)
            end
            if item["mikuType"] == "Wave" then
                return Waves::toString(item)
            end
            if item["description"] then
                return item["description"]
            end
        end

        puts "I do not know how to LxFunction::function (command: #{command}, item: #{JSON.pretty_generate(item)})"
        puts "Aborting."
        exit
    end
end
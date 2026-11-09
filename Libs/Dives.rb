
class Dives

    # Dives::objectDive(object, isSeekingSelect)
    def self.objectDive(object, isSeekingSelect)
        if  PolyFunctions::networkNodeTypes().include?(object["mikuType"]) then
            possibly_selected = Dives::programNetworkNode(object, isSeekingSelect)
            if possibly_selected then
                return possibly_selected
            end
            return
        end
        if object["mikuType"] == "NxLink" then
            Dives::diveNxLink(object)
            return
        end
        if object["mikuType"] == "NxNote" then
            Dives::diveNxNote(object)
            return
        end
        raise "(error: 847d0f13) I do not know how to dive #{JSON.pretty_generate(object)}"
    end

    # Dives::programNetworkNode(object, isSeekingSelect) # nil or object if isSeekingSelect
    def self.programNetworkNode(object, isSeekingSelect)
        loop {
            object = NxObjectIO::getObjectByUUIDOrNull(object["uuid"])
            system('clear')

            if isSeekingSelect then
                puts " ---------------------------".green
                puts "| select                    |".green
                puts " ---------------------------".green
                puts ""
            end

            store = ListingStore.new()
            puts PolyFunctions::toString(object).green
            puts ""
            PolyFunctions::objectToItsNotes(object)
                .each{|note|
                    store.register(note)
                    puts "[#{store.prefixString()}] #{PolyFunctions::toString(note)}"
                    puts note["text"]
                }
            PolyFunctions::linkedObjects(object)
                .sort_by{|o1, o2| o1["datetime"] <=> o2["datetime"] }
                .each{|lo|
                    store.register(lo)
                    puts "[#{store.prefixString()}] linked: #{PolyFunctions::toString(lo)}"
                }
            puts ""

            if isSeekingSelect then
                puts ""
                puts "commands: #{"select".green} | access | connect | expose | update description | make note | disconnect | destroy"
            else
                puts ""
                puts "commands: access | connect | expose | update description | make note | disconnect | destroy"
                puts "commands: permanode -> navigation node"
            end

            command = LucilleCore::askQuestionAnswerAsString("> ")
            break if command == ""

            if CommonUtils::isInteger(command) then
                indx = command.to_i
                o = store.get(indx)
                next if o.nil?
                possibly_selected = Dives::objectDive(o, isSeekingSelect)
                if possibly_selected then
                    return possibly_selected
                end
                next
            end

            if command == "select" then
                return object
            end

            if command == "access" then
                PolyActions::access(object)
                next
            end
            if command == "expose" then
                puts JSON.pretty_generate(object)
                LucilleCore::pressEnterToContinue()
                next
            end
            if command == "update description" then
                description = LucilleCore::askQuestionAnswerAsString("description: ")
                object["description"] = description
                NxObjectIO::commitObject(object)
                next
            end
            if command == "make note" then
                text = LucilleCore::editTextSynchronously("").strip
                next if text == ""
                note = Forges::forgeNxNote(object["uuid"], text)
                NxObjectIO::commitObject(note)
                next
            end
            if command == "connect" then
                object2 = PolyFunctions::architectNodeOrNull()
                next if object2.nil?
                NxObjectIO::commitObject(object2)
                link = Forges::forgeNxLink(object["uuid"], object2["uuid"])
                NxObjectIO::commitObject(link)
                next
            end
            if command == "disconnect" then
                puts "link remove is not implemented yet"
                LucilleCore::pressEnterToContinue()
                next
            end
            if command == "permanode -> navigation node" then
                if object["mikuType"] == "Permanode" then
                    if LucilleCore::askQuestionAnswerAsBoolean("Confirm recasting this permanode as NavigationNode ") then
                        object["mikuType"] = "NavigationNode"
                        NxObjectIO::commitObject(object)
                    end
                end
                next
            end
            if command == "destroy" then
                if LucilleCore::askQuestionAnswerAsBoolean("confirm destroying #{PolyFunctions::toString(object)}") then
                    NxObjectIO::destroy(object["uuid"])
                    return
                end
                next
            end
        }
        nil
    end

    # Dives::diveNxLink(object)
    def self.diveNxLink(object)
        raise "Dives::diveNxLink: not implemented yet"
    end

    # Dives::diveNxNote(object)
    def self.diveNxNote(object)
        raise "Dives::diveNxNote: not implemented yet"
    end
end

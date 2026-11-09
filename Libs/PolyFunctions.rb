
class PolyFunctions

    # PolyFunctions::architectNodeOrNull()
    def self.architectNodeOrNull()
        loop {
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", ["search and maybe `select`", "interactively make new (automatically selected)"])
            return nil if option.nil?
            if option == "search and maybe `select`" then
                node = PolyFunctions::interactivelySelectNodeOrNull()
                if node then
                    return node
                end
            end
            if option == "interactively make new (automatically selected)" then
                node = PolyFunctions::forgeNewNodeOrNull()
                if node then
                    return node
                end
            end
        }
    end

    # PolyFunctions::interactivelySelectNodeOrNull() nil or node
    def self.interactivelySelectNodeOrNull()
        puts "get node using selection and navigation".green
        loop {
            fragment = LucilleCore::askQuestionAnswerAsString("search fragment (empty to abort and return null) : ")
            return nil if fragment == ""
            loop {
                selected = NxObjectIO::allObjects().select{|item| Search::isMatch(item, fragment) }
                if selected.empty? then
                    puts "Could not find a matching element for '#{fragment}'"
                    if LucilleCore::askQuestionAnswerAsBoolean("search more ? ", false) then
                        break
                    else
                        return nil
                    end
                else
                    # In case something has changed, we want the ones that have survived
                    selected = selected
                        .map{|node| NxObjectIO::getObjectByUUIDOrNull(node["uuid"]) }
                        .compact
                    node = LucilleCore::selectEntityFromListOfEntitiesOrNull("node", selected, lambda{|o| PolyFunctions::toString(o) })
                    if node.nil? then
                        if LucilleCore::askQuestionAnswerAsBoolean("search more ? ", false) then
                            break
                        else
                            return nil
                        end
                    end
                    node = Dives::objectDive(node, true)
                    if node then
                        return node # was `select`ed
                    end
                end
            }
        }
    end

    # PolyFunctions::toString(object)
    def self.toString(object)
        if object["mikuType"] == "NxLink" then
            return "NxLink: #{object["uuid1"]} / #{object["uuid2"]}"
        end
        if object["mikuType"] == "NxNote" then
            return "NxNote @ #{object["datetime"]}"
        end
        if object["mikuType"] == "NxDataBeacon" then
            return "NxDataBeacon: #{object["description"]}"
        end
        if object["mikuType"] == "NxDataUniqueString" then
            return "NxDataUniqueString: #{object["description"]}"
        end
        if object["mikuType"] == "NxDataAionPoint" then
            return "NxDataAionPoint: #{object["description"]}"
        end
        if object["mikuType"] == "NxDataUrl" then
            return "NxDataUrl: #{object["description"]}"
        end
        if object["mikuType"] == "NxDataText" then
            return "NxDataText: #{object["description"]}"
        end
        if object["mikuType"] == "Permanode" then
            return "Permanode: #{object["description"]}"
        end
        if object["mikuType"] == "NavigationNode" then
            return "NavigationNode: #{object["description"]}"
        end
        raise "(error: ee3f2028) I do not know how to PolyFunctions::toString #{JSON.pretty_generate(object)}"
    end

    # PolyFunctions::allLinks()
    def self.allLinks()
        NxObjectIO::allObjects().select{|object| object["mikuType"] == "NxLink" }
    end

    # PolyFunctions::linked(uuid1, uuid2)
    def self.linked(uuid1, uuid2)
        PolyFunctions::allLinks().each{|link|
            return true if link["uuid1"] == uuid1 and link["uuid2"] == uuid2
            return true if link["uuid1"] == uuid2 and link["uuid2"] == uuid1
        }
        false
    end

    # PolyFunctions::objectToLinkedUUIDs(object)
    def self.objectToLinkedUUIDs(object)
        PolyFunctions::allLinks()
            .select{|link| link["uuid1"] == object["uuid"] or link["uuid2"] == object["uuid"] }
            .map{|link| [ link["uuid1"], link["uuid2"] ] }
            .flatten
            .select{|uuid| uuid != object["uuid"] }
            .uniq
    end

    # PolyFunctions::linkedObjects(object)
    def self.linkedObjects(object)
        PolyFunctions::objectToLinkedUUIDs(object)
            .map{|uuid| NxObjectIO::getObjectByUUIDOrNull(uuid) }
            .compact
    end

    # PolyFunctions::objectToItsNotes(object)
    def self.objectToItsNotes(object)
        NxObjectIO::allObjects()
            .select{|o1| o1["mikuType"] = "NxNote"}
            .select{|o1| o1["targetuuid"] == object["uuid"] }
    end

    # PolyFunctions::networkNodeTypes()
    def self.networkNodeTypes()
        [
            "Permanode",
            "NavigationNode",
            "NxDataText",
            "NxDataUrl",
            "NxDataAionPoint",
            "NxDataUniqueString",
            "NxDataBeacon"
        ]
    end

    # PolyFunctions::nxDataTypes()
    def self.nxDataTypes()
        [
            "NxDataText",
            "NxDataUrl",
            "NxDataAionPoint",
            "NxDataUniqueString",
            "NxDataBeacon"
        ]
    end

    # PolyFunctions::forgeNewNodeOrNull()
    def self.forgeNewNodeOrNull()
        description = LucilleCore::askQuestionAnswerAsString("description: ")
        options = ["text", "url", "aion-point", "beacon", "unique string", "navigation node"]
        option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", options)
        return nil if option.nil?
        if option == "text" then
            text = CommonUtils::editTextSynchronously("")
            return Forges::forgeNxDataText(description, text)
        end
        if option == "url" then
            url = LucilleCore::askQuestionAnswerAsString("url: ")
            return Forges::forgeNxDataUrl(description, url)
        end
        if option == "aion-point" then
            location = CommonUtils::interactivelySelectDesktopLocationOrNull()
            return nil if location.nil?
            nhash =  AionCore::commitLocationReturnHash(Elizabeth.new(), location)
            return Forges::forgeNxDataAionPoint(description, nhash)
        end
        if option == "beacon" then
            beaconId = SecureRandom.uuid
            beacon = {
                "type" => "Bx47",
                "id" => beaconId
            }
            beaconFilepath = "#{Config::userHomeDirectory()}/Desktop/#{SecureRandom.hex(4)}.nyx29-beacon.json"
            File.open(beaconFilepath, "w"){|f| f.puts(JSON.pretty_generate(beacon)) }
            puts "I have put the beacon file on the Desktop, please move to destination"
            LucilleCore::pressEnterToContinue()
            return Forges::forgeNxDataBeacon(description, beaconId)
        end
        if option == "unique string" then
            uniquestring = LucilleCore::askQuestionAnswerAsString("unique string (if needed use Nx01-#{SecureRandom.hex[0, 12]}): ")
            return Forges::forgeNxDataUniqueString(description, uniquestring)
        end
        if option == "navigation node" then
            description = LucilleCore::askQuestionAnswerAsString("description: ")
            return Forges::forgeNavigationNode(description)
        end
    end
end

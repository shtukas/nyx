
class PolyFunctions

    # PolyFunctions::itemOrNull(uuid)
    def self.itemOrNull(uuid)
        Cubes::itemOrNull(uuid)
    end

    # PolyFunctions::toString(item)
    def self.toString(item)
        if item["mikuType"] == "Nx101" then
            return Nx101s::toString(item)
        end
        if item["mikuType"] == "NxAvaldi" then
            return NxAvaldis::toString(item)
        end
        if item["mikuType"] == "NxCoreDataRef" then
            return CoreDataRefsNxCDRs::toString(item)
        end
        raise "(error: f0b8340c-9ed8-4046-b102-7e461cedef21) unsupported miku type: #{item["mikuType"]}"
    end

    # PolyFunctions::linkeduuids(item)
    def self.linkeduuids(item)
        if item["mikuType"] == "Nx101" then
            return item["linkeduuids"]
        end
        if item["mikuType"] == "NxAvaldi" then
            return Cub3sX::getSet2(item["uuid"], "linkeduuids")
        end
        raise "(error: 4645d069-ff48-4d57-91d6-9cb980d34403) unsupported miku type: #{item["mikuType"]}"
    end

    # PolyFunctions::taxonomy(item)
    def self.taxonomy(item)
        if item["mikuType"] == "Nx101" then
            return item["taxonomy"]
        end
        if item["mikuType"] == "NxAvaldi" then
            return Cub3sX::getSet2(item["uuid"], "taxonomy")
        end
        raise "(error: 16a6bfce-49d5-4dc5-af8e-7ec0d2bdd1db) unsupported miku type: #{item["mikuType"]}"
    end

    # PolyFunctions::notes(item)
    def self.notes(item)
        if item["mikuType"] == "Nx101" then
            return item["notes"]
        end
        if item["mikuType"] == "NxAvaldi" then
            return Cub3sX::getSet2(item["uuid"], "notes")
        end
        raise "(error: 137f9265-d3f0-45c2-8cc6-5bfd36481572) unsupported miku type: #{item["mikuType"]}"
    end

    # PolyFunctions::tags(item)
    def self.tags(item)
        if item["mikuType"] == "Nx101" then
            return []
        end
        if item["mikuType"] == "NxAvaldi" then
            return Cub3sX::getSet2(item["uuid"], "tags")
        end
    end

    # PolyFunctions::allNetworkItems()
    def self.allNetworkItems()
        Cubes::mikuType('Nx101') + Cubes::mikuType('NxAvaldi')
    end

    # PolyFunctions::interactivelyIssueNewOrNull()
    def self.interactivelyIssueNewOrNull()
        options = [
            "node: 101",
            "node: avaldi",
        ]
        option = LucilleCore::selectEntityFromListOfEntitiesOrNull("operation", options)
        return if option.nil?
        if option == "node: 101" then
            return Nx101s::interactivelyIssueNewOrNull()
        end
        if option == "node: avaldi" then
            return NxAvaldis::interactivelyIssueNewOrNull()
        end
    end

    # PolyFunctions::architectNodeOrNull()
    def self.architectNodeOrNull()
        loop {
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", ["search and maybe `select`", "build and return"])
            return nil if option.nil?
            if option == "search and maybe `select`" then
                node = PolyFunctions::getNodeOrNullUsingSelectionAndNavigation()
                if node then
                    return node
                end
            end
            if option == "build and return" then
                node = PolyFunctions::interactivelyIssueNewOrNull()
                if node then
                    return node
                end
            end
        }
    end

    # PolyFunctions::getNodeOrNullUsingSelectionAndNavigation() nil or node
    def self.getNodeOrNullUsingSelectionAndNavigation()
        puts "get node using selection and navigation".green
        sleep 0.5
        loop {
            fragment = LucilleCore::askQuestionAnswerAsString("search fragment (empty to abort and return null) : ")
            return nil if fragment == ""
            loop {
                selected = Cubes::mikuType('Nx101')
                            .select{|node| Search::match(node, fragment) }

                if selected.empty? then
                    puts "Could not find a matching element for '#{fragment}'"
                    if LucilleCore::askQuestionAnswerAsBoolean("search more ? ", false) then
                        break
                    else
                        return nil
                    end
                else
                    selected = selected.select{|node| Cubes::itemOrNull(node["uuid"]) } # In case something has changed, we want the ones that have survived
                    node = LucilleCore::selectEntityFromListOfEntitiesOrNull("node", selected, lambda{|i| i["description"] })
                    if node.nil? then
                        if LucilleCore::askQuestionAnswerAsBoolean("search more ? ", false) then
                            break
                        else
                            return nil
                        end
                    end
                    node = Nx101s::program(node)
                    if node then
                        return node # was `select`ed
                    end
                end
            }
        }
    end
end

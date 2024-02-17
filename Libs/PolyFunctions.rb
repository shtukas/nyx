
class PolyFunctions

    # PolyFunctions::itemOrNull(uuid)
    def self.itemOrNull(uuid)
        Cubes::itemOrNull(uuid)
    end

    # PolyFunctions::toString(item)
    def self.toString(item)
        if item["mikuType"] == "NxDot41" then
            return NxDot41::toString(item)
        end
        if item["mikuType"] == "NxCoreDataRef" then
            return CoreDataRefsNxCDRs::toString(item)
        end
        raise "(error: f0b8340c-9ed8-4046-b102-7e461cedef21) unsupported miku type: #{item["mikuType"]}"
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
                node = NxDot41s::interactivelyIssueNewOrNull()
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
                selected = Cubes::items()
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
                    node = NxDot41::program(node)
                    if node then
                        return node # was `select`ed
                    end
                end
            }
        }
    end
end

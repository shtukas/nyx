
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
                node = NxNode::interactivelyIssueNewOrNull()
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
                selected = NxNode::items()
                            .select{|node| Search::match(node, fragment) }

                if selected.empty? then
                    puts "Could not find a matching element for '#{fragment}'"
                    if LucilleCore::askQuestionAnswerAsBoolean("search more ? ", false) then
                        break
                    else
                        return nil
                    end
                else
                    selected = selected.select{|node| Items::getItemOrNull(node["uuid"]) } # In case something has changed, we want the ones that have survived
                    node = LucilleCore::selectEntityFromListOfEntitiesOrNull("node", selected, lambda{|i| i["description"] })
                    if node.nil? then
                        if LucilleCore::askQuestionAnswerAsBoolean("search more ? ", false) then
                            break
                        else
                            return nil
                        end
                    end
                    node = NxNode::program(node, true)
                    if node then
                        return node # was `select`ed
                    end
                end
            }
        }
    end
end

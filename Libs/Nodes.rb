
class Nodes

    # ---------------------------------------
    # Data

    # Nodes::architectNodeOrNull()
    def self.architectNodeOrNull()
        loop {
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", ["search and maybe `select`", "interactively make new (automatically selected)"])
            return nil if option.nil?
            if option == "search and maybe `select`" then
                node = Nodes::interactivelySelectNodeOrNull()
                if node then
                    return node
                end
            end
            if option == "interactively make new (automatically selected)" then
                node = Nx27::interactivelyIssueNewOrNull()
                if node then
                    return node
                end
            end
        }
    end

    # Nodes::interactivelySelectNodeOrNull() nil or node
    def self.interactivelySelectNodeOrNull()
        puts "get node using selection and navigation".green
        loop {
            fragment = LucilleCore::askQuestionAnswerAsString("search fragment (empty to abort and return null) : ")
            return nil if fragment == ""
            loop {
                selected = Nx27::items()
                            .select{|node| Search::match(node, fragment) }

                if selected.empty? then
                    puts "Could not find a matching element for '#{fragment}'"
                    if LucilleCore::askQuestionAnswerAsBoolean("search more ? ", false) then
                        break
                    else
                        return nil
                    end
                else
                    selected = selected.select{|node| Blades::itemOrNull(node["uuid"]) } # In case something has changed, we want the ones that have survived
                    node = LucilleCore::selectEntityFromListOfEntitiesOrNull("node", selected, lambda{|i| i["description"] })
                    if node.nil? then
                        if LucilleCore::askQuestionAnswerAsBoolean("search more ? ", false) then
                            break
                        else
                            return nil
                        end
                    end
                    node = Nx27::program(node, true)
                    if node then
                        return node # was `select`ed
                    end
                end
            }
        }
    end

    # ---------------------------------------
    # Operations

    # Nodes::connect1(node, uuid)
    def self.connect1(node, uuid)
        node["linkeduuids"] = (node["linkeduuids"] + [uuid]).uniq
        Blades::setAttribute(node["uuid"], "linkeduuids", node["linkeduuids"])
    end

    # Nodes::connect2(node, isSeekingSelect) # nil or node
    def self.connect2(node, isSeekingSelect)
        node2 = Nodes::architectNodeOrNull()
        return nil if node2.nil?
        Nodes::connect1(node, node2["uuid"])
        Nodes::connect1(node2, node["uuid"])
        # We have connected node and node2
        # We are now going to land on it and get an opportunity to select it.
        Nx27::program(node2, isSeekingSelect)
    end

end

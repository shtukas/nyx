
# Nodes is a more abstract concept than ItemsDatabase, it is used to refer to both
# Nx27s or Fx35s, regardless of how they are stored.

class Nodes

    # ---------------------------------------
    # Data

    # Nodes::description(item)
    def self.description(item)
        return item["description"] if item["description"]
        "(#{item["mikuType"]}: #{item["uuid"]})"
    end

    # Nodes::itemOrNull(uuid)
    def self.itemOrNull(uuid)
        ItemsDatabase::itemOrNull(uuid)
    end

    # Nodes::nodes()
    def self.nodes()
        ItemsDatabase::items()
    end

    # Nodes::architectNodeOrNull()
    def self.architectNodeOrNull()
        loop {
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", ["search and maybe `select`", "interactively make new (automatically selected)"])
            return nil if option.nil?
            if option == "search and maybe `select`" then
                node = Nodes::getNodeOrNullUsingSelectionAndNavigation()
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

    # Nodes::getNodeOrNullUsingSelectionAndNavigation() nil or node
    def self.getNodeOrNullUsingSelectionAndNavigation()
        puts "get node using selection and navigation".green
        loop {
            fragment = LucilleCore::askQuestionAnswerAsString("search fragment (empty to abort and return null) : ")
            return nil if fragment == ""
            loop {
                selected = ItemsDatabase::items()
                            .select{|node| Search::match(node, fragment) }

                if selected.empty? then
                    puts "Could not find a matching element for '#{fragment}'"
                    if LucilleCore::askQuestionAnswerAsBoolean("search more ? ", false) then
                        break
                    else
                        return nil
                    end
                else
                    selected = selected.select{|node| ItemsDatabase::itemOrNull(node["uuid"]) } # In case something has changed, we want the ones that have survived
                    node = LucilleCore::selectEntityFromListOfEntitiesOrNull("node", selected, lambda{|i| i["description"] })
                    if node.nil? then
                        if LucilleCore::askQuestionAnswerAsBoolean("search more ? ", false) then
                            break
                        else
                            return nil
                        end
                    end
                    node = Nx27::programNode(node, true)
                    if node then
                        return node # was `select`ed
                    end
                end
            }
        }
    end

    # ---------------------------------------
    # Operations

    # Nodes::program(item, isSeekingSelect)
    def self.program(item, isSeekingSelect)
        if item["mikuType"] == "Nx27" then
            return Nx27::programNode(item, isSeekingSelect)
        end
        if item["mikuType"] == "Fx35" then
            return Fx35::programNode(item, isSeekingSelect)
        end
        raise "(error: dcb2daa3-10f0)"
    end

    # Nodes::fsck(item)
    def self.fsck(item)
        if item["mikuType"] == "Nx27" then
            return Nx27::fsckItem(item)
        end
        if item["mikuType"] == "Fx35" then
            return Fx35::fsckItem(item)
        end
        raise "(error: 4475759b-7ff4)"
    end

    # Nodes::commitItem(item)
    def self.commitItem(item)

    end

    # Nodes::setAttribute(uuid, attrname, attrvalue)
    def self.setAttribute(uuid, attrname, attrvalue)
        item = Nodes::itemOrNull(uuid)
        return if item.nil?
        if item["mikuType"] == "Nx27" then
            ItemsDatabase::setAttribute(uuid, attrname, attrvalue)
            return
        end
        if item["mikuType"] == "Fx35" then
            puts "I do not know how to update an attribute of a Fx35"
            exit
        end
    end

    # Nodes::deleteItem(node)
    def self.deleteItem(node)
        if node["mikuType"] == "Nx27" then
            ItemsDatabase::deleteItem(node["uuid"])
            return
        end
        if node["mikuType"] == "Fx35" then
            raise "I haven't implemented the deletion of Fx53 nodes. Should be driven from the file system."
        end
        raise "(error: 46e233c1-e148)"
    end

    # Nodes::connect1(node, uuid)
    def self.connect1(node, uuid)
        node["linkeduuids"] = (node["linkeduuids"] + [uuid]).uniq
        Nodes::setAttribute(node["uuid"], "linkeduuids", node["linkeduuids"])
    end

    # Nodes::connect2(node, isSeekingSelect) # nil or node
    def self.connect2(node, isSeekingSelect)
        node2 = Nodes::architectNodeOrNull()
        return nil if node2.nil?
        Nodes::connect1(node, node2["uuid"])
        Nodes::connect1(node2, node["uuid"])
        # We have connected node and node2
        # We are now going to land on it and get an opportunity to select it.
        Nx27::programNode(node2, isSeekingSelect)
    end

end

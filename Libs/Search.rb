
# encoding: UTF-8
class Search

    # Search::match(node, fragment)
    def self.match(node, fragment)
        node["description"].downcase.include?(fragment.downcase)
    end

    # Search::searchAndDive()
    def self.searchAndDive()
        loop {
            system('clear')
            fragment = LucilleCore::askQuestionAnswerAsString("search fragment (empty to abort) : ")
            break if fragment == ""

            loop {
                system('clear')
                selected = DarkEnergy::mikuType('NxNode')
                            .select{|node| Search::match(node, fragment) }

                if selected.empty? then
                    puts "Could not find a matching element for '#{fragment}'"
                    LucilleCore::pressEnterToContinue()
                    break
                else
                    selected = selected.select{|node| DarkEnergy::itemOrNull(node["uuid"]) } # In case something has changed, we want the ones that have survived
                    node = LucilleCore::selectEntityFromListOfEntitiesOrNull("node", selected, lambda{|i| i["description"] })
                    break if node.nil?
                    NxNodes::program(node)
                end
            }
        }
    end

    # Search::select() nil or node
    def self.select()
        puts "> entering fox search"
        LucilleCore::pressEnterToContinue()
        loop {
            system('clear')
            fragment = LucilleCore::askQuestionAnswerAsString("search fragment (empty to abort) : ")

            if fragment == "" then
                if LucilleCore::askQuestionAnswerAsBoolean("continue search ? ") then
                    next
                else
                    return nil
                end
            else
                # continue
            end

            selected = DarkEnergy::mikuType('NxNode')
                            .select{|node| Search::match(node, fragment) }

            if selected.size > 0 then
                node = LucilleCore::selectEntityFromListOfEntitiesOrNull("node", selected, lambda{|i| i["description"] })
                if node then
                    option = LucilleCore::selectEntityFromListOfEntitiesOrNull("option", ["return '#{node["description"]}'", "landing on '#{node["description"]}'"])
                    next if node.nil?
                    if option == "return '#{node["description"]}'" then
                        return node
                    end
                    if option == "landing on '#{node["description"]}'" then
                        o = NxNodes::program(node)
                        if o then
                            return o
                        end
                    end
                else
                    if LucilleCore::askQuestionAnswerAsBoolean("continue search ? ") then
                        next
                    else
                        return nil
                    end
                end
            else
                if LucilleCore::askQuestionAnswerAsBoolean("continue search ? ") then
                    next
                else
                    return nil
                end
            end
        }
        nil
    end
end
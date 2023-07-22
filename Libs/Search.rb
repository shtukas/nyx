
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
                selected = BladesGI::mikuType('NxNode')
                            .select{|node| Search::match(node, fragment) }

                if selected.empty? then
                    puts "Could not find a matching element for '#{fragment}'"
                    LucilleCore::pressEnterToContinue()
                    break
                else
                    selected = selected.select{|node| BladesGI::itemOrNull(node["uuid"]) } # In case something has changed, we want the ones that have survived
                    node = LucilleCore::selectEntityFromListOfEntitiesOrNull("node", selected, lambda{|i| i["description"] })
                    break if node.nil?
                    NxNodes::program(node)
                end
            }
        }
    end
end
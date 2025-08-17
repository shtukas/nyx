
# encoding: UTF-8
class Search

    # Search::match(item, fragment)
    def self.match(item, fragment)
        item["description"].downcase.include?(fragment.downcase)
    end

    # Search::searchAndDive()
    def self.searchAndDive()
        loop {
            system('clear')
            fragment = LucilleCore::askQuestionAnswerAsString("search fragment (empty to abort) : ")
            break if fragment == ""

            loop {
                system('clear')
                selected = NxNode28::items()
                            .select{|item| Search::match(item, fragment) }

                if selected.empty? then
                    puts "Could not find a matching element for '#{fragment}'"
                    LucilleCore::pressEnterToContinue()
                    break
                end

                selected = selected.select{|item| NxNode28::itemOrNull(item["uuid"]) } # In case something has changed, we want the ones that have survived

                item = LucilleCore::selectEntityFromListOfEntitiesOrNull("item", selected, lambda{|i| i["description"] })
                break if item.nil?
                NxNode28::program(item, false)
            }
        }
    end
end
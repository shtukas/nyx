
# encoding: UTF-8

class Search

    # Search::nx19s()
    def self.nx19s()
        Anniversaries::nx19s() +
        Calendar::nx19s() +
        Nx31s::nx19s() + 
        Nx50s::nx19s() +
        NxFloat::nx19s() +
        Waves::nx19s()
    end

    # Search::search()
    def self.search()
        loop {
            system('clear')
            fragment = LucilleCore::askQuestionAnswerAsString("search fragment (empty to abort) : ")
            break if fragment == ""
            selected = Search::nx19s().select{|nx19| nx19["announce"].downcase.include?(fragment.downcase) }
            if selected.empty? then
                puts "Could not find a matching element for '#{fragment}'"
                LucilleCore::pressEnterToContinue()
                next
            end
            nx19 = LucilleCore::selectEntityFromListOfEntitiesOrNull("search", selected, lambda{|item| item["announce"] })
            next if nx19.nil?
            system('clear')
            nx19["lambda"].call()
        }
    end
end

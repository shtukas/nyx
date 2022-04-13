
# encoding: UTF-8

class Search

    # Search::nx20s()
    def self.nx20s()
        nx20s = Nx100Nodes::nx20s() +
                Nx31s::nx20s() +
                Anniversaries::nx20s() +
                TxDateds::nx20s() +
                TxFyres::nx20s() +
                TxFloats::nx20s() +
                TxTodos::nx20s() +
                Waves::nx20s()
        nx20s.sort{|x1, x2| x1["unixtime"] <=> x2["unixtime"] }
    end

    # ---------------------------

    # Search::funkyInterfaceInterativelySelectNx20OrNull()
    def self.funkyInterfaceInterativelySelectNx20OrNull()
        Utils::selectOneObjectUsingInteractiveInterfaceOrNull(Search::nx20s(), lambda{|item| item["announce"] })
    end

    # Search::funkyInterface()
    def self.funkyInterface()
        loop {
            nx20 = Search::funkyInterfaceInterativelySelectNx20OrNull()
            break if nx20.nil?
            LxAction::action("landing", nx20["payload"])
        }
    end

    # ---------------------------

    # Search::searchClassic()
    def self.searchClassic()
        loop {
            system('clear')
            fragment = LucilleCore::askQuestionAnswerAsString("search fragment (empty to abort) : ")
            break if fragment == ""
            selected = Search::nx20s().select{|nx20| nx20["announce"].downcase.include?(fragment.downcase) }
            if selected.empty? then
                puts "Could not find a matching element for '#{fragment}'"
                LucilleCore::pressEnterToContinue()
                next
            end
            loop {
                system('clear')
                selected = Search::nx20s().select{|nx20| nx20["announce"].downcase.include?(fragment.downcase) }
                nx20 = LucilleCore::selectEntityFromListOfEntitiesOrNull("search", selected, lambda{|item| item["announce"] })
                break if nx20.nil?
                system('clear')
                LxAction::action("landing", nx20["payload"])
            }
        }
    end

    # ---------------------------
end

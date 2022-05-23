
# encoding: UTF-8

class Search

    # Search::nx20sForInteractiveSearch()
    def self.nx20sForInteractiveSearch()
        nx20s = Nx100s::nx20s() +
                Anniversaries::nx20s() +
                TxDateds::nx20s() +
                TxFyres::nx20s() +
                TxFloats::nx20s() +
                TxTodos::nx20s() +
                Waves::nx20s()
        nx20s.sort{|x1, x2| x1["unixtime"] <=> x2["unixtime"] }
    end

    # Search::nx20sForClassicalSearch()
    def self.nx20sForClassicalSearch()
        nx20s = Nx100s::nx20s() +
                Anniversaries::nx20s() +
                TxDateds::nx20s() +
                TxFyres::nx20s() +
                TxFloats::nx20s() +
                TxTodos::nx20s() +
                Waves::nx20s()
        nx20s = nx20s.sort{|x1, x2| x1["unixtime"] <=> x2["unixtime"] }

        nx20s + Nx100s::nx20sAddition1()
    end

    # ---------------------------

    # Search::interativeInterfaceSelectNx20OrNull()
    def self.interativeInterfaceSelectNx20OrNull()
        DidactUtils::selectOneObjectUsingInteractiveInterfaceOrNull(Search::nx20sForInteractiveSearch(), lambda{|item| item["announce"] })
    end

    # Search::interativeInterface()
    def self.interativeInterface()
        loop {
            nx20 = Search::interativeInterfaceSelectNx20OrNull()
            break if nx20.nil?
            LxAction::action("landing", nx20["payload"])
        }
    end

    # ---------------------------

    # Search::classicInterface()
    def self.classicInterface()
        loop {
            system('clear')
            fragment = LucilleCore::askQuestionAnswerAsString("search fragment (empty to abort) : ")
            break if fragment == ""
            selected = Search::nx20sForClassicalSearch().select{|nx20| nx20["announce"].downcase.include?(fragment.downcase) }
            if selected.empty? then
                puts "Could not find a matching element for '#{fragment}'"
                LucilleCore::pressEnterToContinue()
                next
            end
            loop {
                system('clear')
                selected = Search::nx20sForClassicalSearch().select{|nx20| nx20["announce"].downcase.include?(fragment.downcase) }
                nx20 = LucilleCore::selectEntityFromListOfEntitiesOrNull("search", selected, lambda{|item| item["announce"] })
                break if nx20.nil?
                system('clear')
                LxAction::action("landing", nx20["payload"])
            }
        }
    end

    # ---------------------------
end

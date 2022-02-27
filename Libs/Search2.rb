
# encoding: UTF-8

class Search2

    # Search2::nx20Landing(nx20)
    def self.nx20Landing(nx20)
        Nx31::landing(nx20["payload"])
    end

    # Search2::interactivelySelectOneNx20OrNull()
    def self.interactivelySelectOneNx20OrNull()
        Utils2::selectOneObjectUsingInteractiveInterfaceOrNull(Nx31::getNx20s(), lambda{|item| item["announce"] })
    end

    # Search2::searchInteractiveView()
    def self.searchInteractiveView()
        loop {
            nx20 = Search2::interactivelySelectOneNx20OrNull()
            break if nx20.nil?
            Search2::nx20Landing(nx20)
        }
    end

    # Search2::searchPerFragment(fragment)
    def self.searchPerFragment(fragment)
        loop {
            system("clear")
            puts "Searching: #{fragment}"
            nx20s = Nx31::getNx20s().select{|nx20| nx20["announce"].downcase.include?(fragment.downcase) }
            nx20 = LucilleCore::selectEntityFromListOfEntitiesOrNull("select", nx20s, lambda{|nx20| nx20["announce"] })
            break if nx20.nil?
            Search2::nx20Landing(nx20)
        }
    end

    # Search2::searchPerFragmentMainInterface()
    def self.searchPerFragmentMainInterface()
        loop {
            system("clear")
            fragment = LucilleCore::askQuestionAnswerAsString("fragment (empty to abort): ")
            break if fragment == ""
            Search2::searchPerFragment(fragment)
        }
    end
end

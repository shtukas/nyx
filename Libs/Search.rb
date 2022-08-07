
# encoding: UTF-8

class Search

    # Search::run(isSearchAndSelect)
    def self.run(isSearchAndSelect)
        loop {
            system('clear')
            fragment = LucilleCore::askQuestionAnswerAsString("search fragment (empty to abort) : ")
            break if fragment == ""
            selected = Nx20s::nx20s()
                .select{|nx20| !nx20["announce"].nil? }
                .select{|nx20| nx20["announce"].downcase.include?(fragment.downcase) }
            if selected.empty? then
                puts "Could not find a matching element for '#{fragment}'"
                LucilleCore::pressEnterToContinue()
                next
            end
            loop {
                system('clear')
                selected = Nx20s::nx20s()
                    .select{|nx20| !nx20["announce"].nil? }
                    .select{|nx20| nx20["announce"].downcase.include?(fragment.downcase) }
                    .sort{|i1, i2| i1["unixtime"] <=> i2["unixtime"] }
                nx20 = LucilleCore::selectEntityFromListOfEntitiesOrNull("item", selected, lambda{|item| item["announce"] })
                break if nx20.nil?
                system('clear')
                item = Fx18s::getItemAliveOrNull(nx20["objectuuid"])
                result = Landing::landing(item, isSearchAndSelect)
                if isSearchAndSelect and result then
                    return result
                end
            }
        }
        
        nil
    end
end

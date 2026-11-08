
# encoding: UTF-8
class Search

    # Search::isMatch(object, fragment)
    def self.isMatch(object, fragment)
        return true if object["uuid"].include?(fragment)
        if object["mikuType"] == "NxDataText" then
            return true if object["text"].downcase.include?(fragment.downcase)
        end
        if object["mikuType"] == "NxDataUrl" then
            return true if object["url"].downcase.include?(fragment.downcase)
        end
        str = PolyFunctions::toString(object)
        return false if str.nil?
        str.downcase.include?(fragment.downcase)
    end

    # Search::searchAndDive()
    def self.searchAndDive()
        loop {
            system('clear')
            fragment = LucilleCore::askQuestionAnswerAsString("search fragment (empty to abort) : ")
            break if fragment == ""

            loop {
                system('clear')
                objects = NxObjectIO::allObjects().select{|item| Search::isMatch(item, fragment) }

                if objects.empty? then
                    puts "Could not find a matching element for '#{fragment}'"
                    LucilleCore::pressEnterToContinue()
                    break
                end

                object = LucilleCore::selectEntityFromListOfEntitiesOrNull("object", objects, lambda{|object| PolyFunctions::toString(object) })
                break if object.nil?
                Dives::objectDive(object, false)
            }
        }
    end
end
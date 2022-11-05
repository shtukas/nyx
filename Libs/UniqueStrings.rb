
# encoding: UTF-8

class UniqueStrings

    # UniqueStrings::uniqueStringIsInAionPointObject(operator, object, uniquestring)
    def self.uniqueStringIsInAionPointObject(operator, object, uniquestring)
        if object["aionType"] == "indefinite" then
            return false
        end
        if object["aionType"] == "directory" then
            if object["name"].downcase.include?(uniquestring.downcase) then
                return true
            end
            return object["items"].any?{|nhash| UniqueStrings::uniqueStringIsInNhash(operator, nhash, uniquestring) }
        end
        if object["aionType"] == "file" then
            return object["name"].downcase.include?(uniquestring.downcase)
        end
    end

    # UniqueStrings::uniqueStringIsInNhash(operator, nhash, uniquestring)
    def self.uniqueStringIsInNhash(operator, nhash, uniquestring)
        blob = operator.getBlobOrNull(nhash)
        return false if blob.nil?
        object = JSON.parse(blob)
        UniqueStrings::uniqueStringIsInAionPointObject(operator, object, uniquestring)
    end

    # UniqueStrings::findAndAccessUniqueString(uniquestring)
    def self.findAndAccessUniqueString(uniquestring)

        puts "unique string: #{uniquestring}"
        location = CommonUtils::uniqueStringLocationUsingPartialGalaxySearchOrNull(uniquestring)
        if location then
            puts "location: #{location}"
            if LucilleCore::askQuestionAnswerAsBoolean("open ? ", true) then
                system("open '#{location}'")
            end
            return
        end
        puts "Unique string not found in Galaxy"
        puts "Looking inside aion-points..."

        puts "" # To accomodate CommonUtils::putsOnPreviousLine
        # Edited when we got rid of Librarian::objects() ( aebe4846-be7b-4688-ab32-eedbf65ce75b )

        [].each{|item|
            
        }

        puts "I could not find the unique string inside aion-points"
        LucilleCore::pressEnterToContinue()
    end
end
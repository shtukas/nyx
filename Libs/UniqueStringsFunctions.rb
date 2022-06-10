
# encoding: UTF-8

class UniqueStringsFunctions

    # UniqueStringsFunctions::uniqueStringIsInAionPointObject(operator, object, uniquestring)
    def self.uniqueStringIsInAionPointObject(operator, object, uniquestring)
        if object["aionType"] == "indefinite" then
            return false
        end
        if object["aionType"] == "directory" then
            if object["name"].downcase.include?(uniquestring.downcase) then
                return true
            end
            return object["items"].any?{|nhash| UniqueStringsFunctions::uniqueStringIsInNhash(operator, nhash, uniquestring) }
        end
        if object["aionType"] == "file" then
            return object["name"].downcase.include?(uniquestring.downcase)
        end
    end

    # UniqueStringsFunctions::uniqueStringIsInNhash(operator, nhash, uniquestring)
    def self.uniqueStringIsInNhash(operator, nhash, uniquestring)
        object = JSON.parse(operator.getBlobOrNull(nhash))
        UniqueStringsFunctions::uniqueStringIsInAionPointObject(operator, object, uniquestring)
    end

    # UniqueStringsFunctions::findAndAccessUniqueString(uniquestring)
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
        Librarian::objects().each{|item|
            CommonUtils::putsOnPreviousLine("looking into #{item["uuid"]}")
            next if item["iam"].nil?
            nx111 = item["nx111"]
            if nx111["type"] == "aion-point" then
                rootnhash = nx111["rootnhash"]
                operator = EnergyGridElizabeth.new()
                if UniqueStringsFunctions::uniqueStringIsInNhash(operator, rootnhash, uniquestring) then
                    EditionDesk::accessItemNx111Pair(item, nx111)
                    return
                end
            end
        }

        puts "I could not find the unique string inside aion-points"
        LucilleCore::pressEnterToContinue()
    end
end

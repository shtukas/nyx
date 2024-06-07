# encoding: UTF-8

class Px44

    # Px44::types()
    def self.types()
        ["text", "url", "blade", "nyx-fs-beacon", "unique string"]
    end

    # Px44::interactivelySelectType()
    def self.interactivelySelectType()
        types = Px44::types()
        LucilleCore::selectEntityFromListOfEntitiesOrNull("type", types)
    end

    # Px44::interactivelyMakeNewOrNull()
    def self.interactivelyMakeNewOrNull()
        type = Px44::interactivelySelectType()
        return nil if type.nil?
        if type == "text" then
            text = CommonUtils::editTextSynchronously("")
            return {
                "type" => "text",
                "text" => text
            }
        end
        if type == "url" then
            url = LucilleCore::askQuestionAnswerAsString("url: ")
            return {
                "type" => "url",
                "url"  => url
            }
        end
        if type == "blade" then
            location = CommonUtils::interactivelySelectDesktopLocationOrNull()
            return nil if location.nil?
            return {
                "type" => "blade",
                "bx26" => Blades::forge(location)
            }
        end
        if type == "nyx-fs-beacon" then
            id = SecureRandom.hex
            filepath = "#{Config::userHomeDirectory()}/Desktop/beacon-#{id[0, 4]}.nyx-fs-beacon"
            File.open(filepath, "w"){|f| f.write(id) }
            puts "I put a .nyx-fs-beacon file on the Desktop. Add it to the target location."
            LucilleCore::pressEnterToContinue()
            return {
                "type" => "nyx-fs-beacon",
                "id"   => id
            }
        end
        if type == "unique string" then
            uniquestring = LucilleCore::askQuestionAnswerAsString("unique string (if needed use Nx01-#{SecureRandom.hex[0, 12]}): ")
            return {
                "type"         => "unique-string",
                "uniquestring" => uniquestring
            }
        end
        raise "(error: f75b2797-99e5-49d0-8d49-40b44beb538c) Px44 type: #{type}"
    end

    # Px44::toStringSuffix(px44)
    def self.toStringSuffix(px44)
        return "" if px44.nil?
        if px44["type"] == "text" then
            return " (text)"
        end
        if px44["type"] == "url" then
            return " (url)"
        end
        if px44["type"] == "blade" then
            return " (blade)"
        end
        if px44["type"] == "nyx-fs-beacon" then
            return " (nyx-fs-beacon)"
        end
        if px44["type"] == "unique-string" then
            return " (unique-string)"
        end
        raise "(error: ee2b7a4b-a34a-4ea6-9f3e-c41be1d1a69c) Px44: #{px44}"
    end

    # Px44::access(px44)
    def self.access(px44)
        return if px44.nil?
        if px44["type"] == "text" then
            puts "--------------------------------------------------------------"
            puts px44["text"]
            puts "--------------------------------------------------------------"
            LucilleCore::pressEnterToContinue()
            return
        end
        if px44["type"] == "url" then
            url = px44["url"]
            puts "url: #{url}"
            CommonUtils::openUrlUsingSafari(url)
            LucilleCore::pressEnterToContinue()
            return
        end
        if px44["type"] == "blade" then
            Blades::access(px44["bx26"])
            return
        end
        if px44["type"] == "nyx-fs-beacon" then
            searchX = lambda{|id|
                roots = [
                    "#{Config::userHomeDirectory()}/Galaxy"
                ]
                Galaxy::locationEnumerator(roots).each{|filepath|
                    if File.basename(filepath)[-14, 14] == ".nyx-fs-beacon" then
                        if IO.read(filepath).strip == id then
                            return filepath
                        end
                    end
                }
                nil
            }
            id = px44["id"]
            filepath = searchX.call(id)
            puts "nyx fs beacon located: #{filepath}"
            folderpath = File.dirname(filepath)
            system("open '#{folderpath}'")
            LucilleCore::pressEnterToContinue()
        end
        if px44["type"] == "unique-string" then
            uniquestring = px44["uniquestring"]
            puts "CoreData, accessing unique string: #{uniquestring}"
            location = Atlas::uniqueStringToLocationOrNull(uniquestring)
            if location then
                puts "location: #{location}"
                LucilleCore::pressEnterToContinue()
            end
            return
        end
        raise "(error: ee2b7a4b-a34a-4ea6-9f3e-c41be1d1a69c) Px44: #{px44}"
    end

    # Px44::fsck(px44)
    def self.fsck(px44)
        return if px44.nil?
        if px44["type"] == "text" then
            return
        end
        if px44["type"] == "url" then
            return
        end
        if px44["type"] == "blade" then
            #Bx26
            #    filename : String
            #    nhash    : String
            bx26 = px44["bx26"]
            nhash = bx26["nhash"]
            AionFsck::structureCheckAionHashRaiseErrorIfAny(Elizabeth.new(), nhash)
            return
        end
        if px44["type"] == "nyx-fs-beacon" then
            return
        end
        if px44["type"] == "unique-string" then
            return
        end
        raise "(error: 4456ba26-1439-47f4-871b-f3c00e384438) Px44: #{px44}"
    end
end

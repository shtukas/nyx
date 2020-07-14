
# encoding: UTF-8

class SpinCached
    # SpinCached::forget(spin)
    def self.forget(spin)
        InMemoryWithOnDiskPersistenceValueCache::delete("e7eb4787-0cfd-4184-a286-1dbec629d9e8:#{spin["uuid"]}")
    end
end

class Spins

    # Spins::selectOneLocationOnTheDesktopOrNull()
    def self.selectOneLocationOnTheDesktopOrNull()
        desktopLocations = LucilleCore::locationsAtFolder("/Users/pascal/Desktop")
                            .select{|filepath| filepath[0,1] != '.' }
                            .select{|filepath| File.basename(filepath) != 'pascal.png' }
                            .select{|filepath| File.basename(filepath) != 'Todo-Inbox' }
                            .sort
        LucilleCore::selectEntityFromListOfEntitiesOrNull("filepath", desktopLocations, lambda{ |location| File.basename(location) })
    end

    # Spins::issueLine(targetuuid, familyname, line)
    def self.issueLine(targetuuid, familyname, line)
        object = {
            "uuid"       => SecureRandom.uuid,
            "nyxNxSet"   => "0f555c97-3843-4dfe-80c8-714d837eba69",
            "unixtime"   => Time.new.to_f,
            "targetuuid" => targetuuid,
            "familyname" => familyname,
            "type"       => "line",
            "line"       => line
        }
        NyxObjects::put(object)
        object
    end

    # Spins::issueUrl(targetuuid, familyname, url)
    def self.issueUrl(targetuuid, familyname, url)
        object = {
            "uuid"       => SecureRandom.uuid,
            "nyxNxSet"   => "0f555c97-3843-4dfe-80c8-714d837eba69",
            "unixtime"   => Time.new.to_f,
            "targetuuid" => targetuuid,
            "familyname" => familyname,
            "type"       => "url",
            "url"        => url
        }
        NyxObjects::put(object)
        object
    end

    # Spins::issueText(targetuuid, familyname, text)
    def self.issueText(targetuuid, familyname, text)
        namedhash = NyxBlobs::put(text)
        object = {
            "uuid"       => SecureRandom.uuid,
            "nyxNxSet"   => "0f555c97-3843-4dfe-80c8-714d837eba69",
            "unixtime"   => Time.new.to_f,
            "targetuuid" => targetuuid,
            "familyname" => familyname,
            "type"       => "text",
            "namedhash"  => namedhash
        }
        NyxObjects::put(object)
        object
    end

    # Spins::issueAionPoint(targetuuid, familyname, namedhash)
    def self.issueAionPoint(targetuuid, familyname, namedhash)
        object = {
            "uuid"       => SecureRandom.uuid,
            "nyxNxSet"   => "0f555c97-3843-4dfe-80c8-714d837eba69",
            "unixtime"   => Time.new.to_f,
            "targetuuid" => targetuuid,
            "familyname" => familyname,
            "type"       => "aion-point",
            "namedhash"  => namedhash
        }
        NyxObjects::put(object)
        object
    end

    # Spins::issueUniqueName(targetuuid, familyname, uniquename)
    def self.issueUniqueName(targetuuid, familyname, uniquename)
        object = {
            "uuid"       => SecureRandom.uuid,
            "nyxNxSet"   => "0f555c97-3843-4dfe-80c8-714d837eba69",
            "unixtime"   => Time.new.to_f,
            "targetuuid" => targetuuid,
            "familyname" => familyname,
            "type"       => "unique-name",
            "name"       => uniquename
        }
        NyxObjects::put(object)
        object
    end

    # Spins::issueNewSpinInteractivelyOrNull(targetuuid, familyname)
    def self.issueNewSpinInteractivelyOrNull(targetuuid, familyname)
        puts "Making a new Spin..."
        types = ["line", "url", "text", "fs-location aion-point", "unique-name"]
        type = LucilleCore::selectEntityFromListOfEntitiesOrNull("type", types)
        return if type.nil?
        if type == "line" then
            line = LucilleCore::askQuestionAnswerAsString("line: ")
            return nil if line.size == 0
            return Spins::issueLine(targetuuid, familyname, line)
        end
        if type == "url" then
            url = LucilleCore::askQuestionAnswerAsString("url: ")
            return nil if url.size == 0
            return Spins::issueUrl(targetuuid, familyname, url)
        end
        if type == "text" then
            text = Miscellaneous::editTextUsingTextmate("").strip
            return nil if text.size == 0
            return Spins::issueText(targetuuid, familyname, text)
        end
        if type == "fs-location aion-point" then
            location = Spins::selectOneLocationOnTheDesktopOrNull()
            return nil if location.nil?
            namedhash = LibrarianOperator::commitLocationDataAndReturnNamedHash(location)
            return Spins::issueAionPoint(targetuuid, familyname, namedhash)
        end
        if type == "unique-name" then
            uniquename = LucilleCore::askQuestionAnswerAsString("unique name: ")
            return nil if uniquename.size == 0
            return Spins::issueUniqueName(targetuuid, familyname, uniquename)
        end
    end

    # Spins::spins()
    def self.spins()
        NyxObjects::getSet("0f555c97-3843-4dfe-80c8-714d837eba69")
    end

    # Spins::getSpinDescriptionOrNull(spin)
    def self.getSpinDescriptionOrNull(spin)
        descriptionzs = DescriptionZ::getDescriptionZsForTargetInTimeOrder(spin["uuid"])
        return nil if descriptionzs.empty?
        descriptionzs.last["description"]
    end

    # Spins::ensureSpinDescriptionOrNothing(spin)
    def self.ensureSpinDescriptionOrNothing(spin)
        return if Spins::getSpinDescriptionOrNull(spin)
        description = LucilleCore::askQuestionAnswerAsString("spin description: ")
        return if description == ""
        DescriptionZ::issue(spin["uuid"], description)
        SpinCached::forget(spin)
    end

    # Spins::spinToString(spin)
    def self.spinToString(spin)
        str = InMemoryWithOnDiskPersistenceValueCache::getOrNull("e7eb4787-0cfd-4184-a286-1dbec629d9e8:#{spin["uuid"]}")
        return str if str

        str = (lambda{|spin|
            description = Spins::getSpinDescriptionOrNull(spin)
            if description then
                return "[spin] [#{spin["familyname"][0, 4]}] [#{spin["uuid"][0, 4]}] [#{spin["type"]}] #{description}"
            end
            if spin["type"] == "line" then
                return "[spin] [#{spin["familyname"][0, 4]}] [#{spin["uuid"][0, 4]}] [#{spin["type"]}] #{spin["line"]}"
            end
            if spin["type"] == "url" then
                return "[spin] [#{spin["familyname"][0, 4]}] [#{spin["uuid"][0, 4]}] [#{spin["type"]}] #{spin["url"]}"
            end
            if spin["type"] == "text" then
                namedhashToFirstLine = lambda {|namedhash|
                    text = NyxBlobs::getBlobOrNull(namedhash).strip
                    line = text.size>0 ? text.lines.first.strip : "[empty text]"
                }
                return "[spin] [#{spin["familyname"][0, 4]}] [#{spin["uuid"][0, 4]}] [#{spin["type"]}] #{namedhashToFirstLine.call(spin["namedhash"])}"
            end
            if spin["type"] == "aion-point" then
                return "[spin] [#{spin["familyname"][0, 4]}] [#{spin["uuid"][0, 4]}] [#{spin["type"]}] #{spin["namedhash"]}"
            end
            if spin["type"] == "unique-name" then
                return "[spin] [#{spin["familyname"][0, 4]}] [#{spin["uuid"][0, 4]}] [#{spin["type"]}] #{spin["name"]}"
            end
            raise "[Spins error 2c53b113-cc79]"
        }).call(spin)

        InMemoryWithOnDiskPersistenceValueCache::set("e7eb4787-0cfd-4184-a286-1dbec629d9e8:#{spin["uuid"]}", str)
        str
    end

    # Spins::getSpinsForTargetInTimeOrder(targetuuid)
    def self.getSpinsForTargetInTimeOrder(targetuuid)
        NyxObjects::getSet("0f555c97-3843-4dfe-80c8-714d837eba69")
            .select{|object| object["targetuuid"] == targetuuid }
            .sort{|o1, o2| o1["unixtime"] <=> o2["unixtime"] }
    end

    # Spins::getSpinsForTargetInTimeOrderLatestOfEachFamily(targetuuid)
    def self.getSpinsForTargetInTimeOrderLatestOfEachFamily(targetuuid)
        Spins::getSpinsForTargetInTimeOrder(targetuuid)
            .reverse
            .reduce([]){|spins, spin|
                if spins.none?{|s| s["familyname"] == spin["familyname"] } then
                    spins << spin
                end
                spins
            }
            .reverse
    end

    # Spins::openSpin(spin)
    def self.openSpin(spin)
        puts "spin:"
        puts JSON.pretty_generate(spin)
        if spin["type"] == "line" then
            puts spin["line"]
            LucilleCore::pressEnterToContinue()
            return
        end
        if spin["type"] == "url" then
            system("open '#{spin["url"]}'")
            return
        end
        if spin["type"] == "text" then
            system("clear")
            namedhash = spin["namedhash"]
            text = NyxBlobs::getBlobOrNull(namedhash)
            puts text
            LucilleCore::pressEnterToContinue()
            return
        end
        if spin["type"] == "aion-point" then
            folderpath = DeskOperator::deskFolderpathForSpinCreateIfNotExists(spin)
            system("open '#{folderpath}'")
            return
        end
        if spin["type"] == "unique-name" then
            uniquename = spin["name"]
            location = AtlasCore::uniqueStringToLocationOrNull(uniquename)
            if location then
                if File.file?(location) then
                    if Miscellaneous::fileByFilenameIsSafelyOpenable(File.basename(location)) then
                        puts "opening safely openable file '#{location}'"
                        system("open '#{location}'")
                    else
                        puts "opening parent folder of '#{location}'"
                        system("open '#{File.dirname(location)}'")
                    end
                else
                    puts "opening folder '#{location}'"
                    system("open '#{location}'")
                end
            else
                puts "I could not determine the location of unique name: #{uniquename}"
                LucilleCore::pressEnterToContinue()
            end
            return
        end
        raise "[Spin error 4bf5cfb1-c2a2]"
    end

end

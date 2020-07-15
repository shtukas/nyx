
# encoding: UTF-8

class FragmentCached
    # FragmentCached::forget(fragment)
    def self.forget(fragment)
        InMemoryWithOnDiskPersistenceValueCache::delete("e7eb4787-0cfd-4184-a286-1dbec629d9e8:#{fragment["uuid"]}")
    end
end

class Fragments

    # Fragments::selectOneLocationOnTheDesktopOrNull()
    def self.selectOneLocationOnTheDesktopOrNull()
        desktopLocations = LucilleCore::locationsAtFolder("/Users/pascal/Desktop")
                            .select{|filepath| filepath[0,1] != '.' }
                            .select{|filepath| File.basename(filepath) != 'pascal.png' }
                            .select{|filepath| File.basename(filepath) != 'Todo-Inbox' }
                            .sort
        LucilleCore::selectEntityFromListOfEntitiesOrNull("filepath", desktopLocations, lambda{ |location| File.basename(location) })
    end

    # Fragments::issueLine(familyname, line)
    def self.issueLine(familyname, line)
        object = {
            "uuid"       => SecureRandom.uuid,
            "nyxNxSet"   => "0f555c97-3843-4dfe-80c8-714d837eba69",
            "unixtime"   => Time.new.to_f,
            "familyname" => familyname,
            "type"       => "line",
            "line"       => line
        }
        NyxObjects::put(object)
        object
    end

    # Fragments::issueUrl(familyname, url)
    def self.issueUrl(familyname, url)
        object = {
            "uuid"       => SecureRandom.uuid,
            "nyxNxSet"   => "0f555c97-3843-4dfe-80c8-714d837eba69",
            "unixtime"   => Time.new.to_f,
            "familyname" => familyname,
            "type"       => "url",
            "url"        => url
        }
        NyxObjects::put(object)
        object
    end

    # Fragments::issueText(familyname, text)
    def self.issueText(familyname, text)
        namedhash = NyxBlobs::put(text)
        object = {
            "uuid"       => SecureRandom.uuid,
            "nyxNxSet"   => "0f555c97-3843-4dfe-80c8-714d837eba69",
            "unixtime"   => Time.new.to_f,
            "familyname" => familyname,
            "type"       => "text",
            "namedhash"  => namedhash
        }
        NyxObjects::put(object)
        object
    end

    # Fragments::issueAionPoint(familyname, namedhash)
    def self.issueAionPoint(familyname, namedhash)
        object = {
            "uuid"       => SecureRandom.uuid,
            "nyxNxSet"   => "0f555c97-3843-4dfe-80c8-714d837eba69",
            "unixtime"   => Time.new.to_f,
            "familyname" => familyname,
            "type"       => "aion-point",
            "namedhash"  => namedhash
        }
        NyxObjects::put(object)
        object
    end

    # Fragments::issueUniqueName(familyname, uniquename)
    def self.issueUniqueName(familyname, uniquename)
        object = {
            "uuid"       => SecureRandom.uuid,
            "nyxNxSet"   => "0f555c97-3843-4dfe-80c8-714d837eba69",
            "unixtime"   => Time.new.to_f,
            "familyname" => familyname,
            "type"       => "unique-name",
            "name"       => uniquename
        }
        NyxObjects::put(object)
        object
    end

    # Fragments::issueNewFragmentInteractivelyOrNull(familyname)
    def self.issueNewFragmentInteractivelyOrNull(familyname)
        puts "Making a new Fragment..."
        types = ["line", "url", "text", "fs-location aion-point", "unique-name"]
        type = LucilleCore::selectEntityFromListOfEntitiesOrNull("type", types)
        return if type.nil?
        if type == "line" then
            line = LucilleCore::askQuestionAnswerAsString("line: ")
            return nil if line.size == 0
            return Fragments::issueLine(familyname, line)
        end
        if type == "url" then
            url = LucilleCore::askQuestionAnswerAsString("url: ")
            return nil if url.size == 0
            return Fragments::issueUrl(familyname, url)
        end
        if type == "text" then
            text = Miscellaneous::editTextUsingTextmate("").strip
            return nil if text.size == 0
            return Fragments::issueText(familyname, text)
        end
        if type == "fs-location aion-point" then
            location = Fragments::selectOneLocationOnTheDesktopOrNull()
            return nil if location.nil?
            namedhash = LibrarianOperator::commitLocationDataAndReturnNamedHash(location)
            return Fragments::issueAionPoint(familyname, namedhash)
        end
        if type == "unique-name" then
            uniquename = LucilleCore::askQuestionAnswerAsString("unique name: ")
            return nil if uniquename.size == 0
            return Fragments::issueUniqueName(familyname, uniquename)
        end
    end

    # Fragments::fragments()
    def self.fragments()
        NyxObjects::getSet("0f555c97-3843-4dfe-80c8-714d837eba69")
    end

    # Fragments::getFragmentDescriptionOrNull(fragment)
    def self.getFragmentDescriptionOrNull(fragment)
        descriptionzs = DescriptionZ::getDescriptionZsForTargetInTimeOrder(fragment["uuid"])
        return nil if descriptionzs.empty?
        descriptionzs.last["description"]
    end

    # Fragments::ensureFragmentDescriptionOrNothing(fragment)
    def self.ensureFragmentDescriptionOrNothing(fragment)
        return if Fragments::getFragmentDescriptionOrNull(fragment)
        description = LucilleCore::askQuestionAnswerAsString("fragment description: ")
        return if description == ""
        DescriptionZ::issue(fragment["uuid"], description)
        FragmentCached::forget(fragment)
    end

    # Fragments::fragmentToString(fragment)
    def self.fragmentToString(fragment)
        str = InMemoryWithOnDiskPersistenceValueCache::getOrNull("e7eb4787-0cfd-4184-a286-1dbec629d9e8:#{fragment["uuid"]}")
        return str if str

        str = (lambda{|fragment|
            description = Fragments::getFragmentDescriptionOrNull(fragment)
            if description then
                return "[fragment] [#{fragment["familyname"][0, 4]}] [#{fragment["uuid"][0, 4]}] [#{fragment["type"]}] #{description}"
            end
            if fragment["type"] == "line" then
                return "[fragment] [#{fragment["familyname"][0, 4]}] [#{fragment["uuid"][0, 4]}] [#{fragment["type"]}] #{fragment["line"]}"
            end
            if fragment["type"] == "url" then
                return "[fragment] [#{fragment["familyname"][0, 4]}] [#{fragment["uuid"][0, 4]}] [#{fragment["type"]}] #{fragment["url"]}"
            end
            if fragment["type"] == "text" then
                namedhashToFirstLine = lambda {|namedhash|
                    text = NyxBlobs::getBlobOrNull(namedhash).strip
                    line = text.size>0 ? text.lines.first.strip : "[empty text]"
                }
                return "[fragment] [#{fragment["familyname"][0, 4]}] [#{fragment["uuid"][0, 4]}] [#{fragment["type"]}] #{namedhashToFirstLine.call(fragment["namedhash"])}"
            end
            if fragment["type"] == "aion-point" then
                return "[fragment] [#{fragment["familyname"][0, 4]}] [#{fragment["uuid"][0, 4]}] [#{fragment["type"]}] #{fragment["namedhash"]}"
            end
            if fragment["type"] == "unique-name" then
                return "[fragment] [#{fragment["familyname"][0, 4]}] [#{fragment["uuid"][0, 4]}] [#{fragment["type"]}] #{fragment["name"]}"
            end
            raise "[Fragments error 2c53b113-cc79]"
        }).call(fragment)

        InMemoryWithOnDiskPersistenceValueCache::set("e7eb4787-0cfd-4184-a286-1dbec629d9e8:#{fragment["uuid"]}", str)
        str
    end

    # Fragments::getFragmentsOfGivenFamilyName(familyname)
    def self.getFragmentsOfGivenFamilyName(familyname)
        Fragments::fragments()
            .select{|fragment| fragment["familyname"] == familyname }
    end

    # Fragments::getFragmentsForSourceInTimeOrderTransitiveToFamilyMembers(sourceuuid)
    def self.getFragmentsForSourceInTimeOrderTransitiveToFamilyMembers(sourceuuid)
        # The transitivity to Family members was introduced because of the desk clearing.
        # When a new fragment is made only its family name is known (it has the same as the one it replaces)
        # But the arrows are not set up since the source of he targets are not known. 
        # We could look them up, thinking about it, but let us just decide that family members are 
        # part of this answer even if they were not actually arrowed
        Arrows::getTargetOfGivenSetsForSourceUUID(sourceuuid, ["0f555c97-3843-4dfe-80c8-714d837eba69"])
            .map{|fragment| fragment["familyname"] }
            .map{|familyname| Fragments::getFragmentsOfGivenFamilyName(familyname) }
            .flatten
            .sort{|o1, o2| o1["unixtime"] <=> o2["unixtime"] }
    end

    # Fragments::getFragmentsForSourceInTimeOrderTransitiveToFamilyMembersLatestOfEachFamily(sourceuuid)
    def self.getFragmentsForSourceInTimeOrderTransitiveToFamilyMembersLatestOfEachFamily(sourceuuid)
        Fragments::getFragmentsForSourceInTimeOrderTransitiveToFamilyMembers(sourceuuid)
            .reverse
            .reduce([]){|fragments, fragment|
                if fragments.none?{|s| s["familyname"] == fragment["familyname"] } then
                    fragments << fragment
                end
                fragments
            }
            .reverse
    end

    # Fragments::openFragment(fragment)
    def self.openFragment(fragment)
        puts "fragment:"
        puts JSON.pretty_generate(fragment)
        if fragment["type"] == "line" then
            puts fragment["line"]
            LucilleCore::pressEnterToContinue()
            return
        end
        if fragment["type"] == "url" then
            system("open '#{fragment["url"]}'")
            return
        end
        if fragment["type"] == "text" then
            system("clear")
            namedhash = fragment["namedhash"]
            text = NyxBlobs::getBlobOrNull(namedhash)
            puts text
            LucilleCore::pressEnterToContinue()
            return
        end
        if fragment["type"] == "aion-point" then
            folderpath = DeskOperator::deskFolderpathForFragmentCreateIfNotExists(fragment)
            system("open '#{folderpath}'")
            return
        end
        if fragment["type"] == "unique-name" then
            uniquename = fragment["name"]
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
        raise "[Fragment error 4bf5cfb1-c2a2]"
    end

end

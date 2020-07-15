
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

    # Fragments::issueLine(line)
    def self.issueLine(line)
        object = {
            "uuid"       => SecureRandom.uuid,
            "nyxNxSet"   => "0f555c97-3843-4dfe-80c8-714d837eba69",
            "unixtime"   => Time.new.to_f,
            "type"       => "line",
            "line"       => line
        }
        NyxObjects::put(object)
        object
    end

    # Fragments::issueUrl(url)
    def self.issueUrl(url)
        object = {
            "uuid"       => SecureRandom.uuid,
            "nyxNxSet"   => "0f555c97-3843-4dfe-80c8-714d837eba69",
            "unixtime"   => Time.new.to_f,
            "type"       => "url",
            "url"        => url
        }
        NyxObjects::put(object)
        object
    end

    # Fragments::issueText(text)
    def self.issueText(text)
        namedhash = NyxBlobs::put(text)
        object = {
            "uuid"       => SecureRandom.uuid,
            "nyxNxSet"   => "0f555c97-3843-4dfe-80c8-714d837eba69",
            "unixtime"   => Time.new.to_f,
            "type"       => "text",
            "namedhash"  => namedhash
        }
        NyxObjects::put(object)
        object
    end

    # Fragments::issueAionPoint(namedhash)
    def self.issueAionPoint(namedhash)
        object = {
            "uuid"       => SecureRandom.uuid,
            "nyxNxSet"   => "0f555c97-3843-4dfe-80c8-714d837eba69",
            "unixtime"   => Time.new.to_f,
            "type"       => "aion-point",
            "namedhash"  => namedhash
        }
        NyxObjects::put(object)
        object
    end

    # Fragments::issueUniqueName(uniquename)
    def self.issueUniqueName(uniquename)
        object = {
            "uuid"       => SecureRandom.uuid,
            "nyxNxSet"   => "0f555c97-3843-4dfe-80c8-714d837eba69",
            "unixtime"   => Time.new.to_f,
            "type"       => "unique-name",
            "name"       => uniquename
        }
        NyxObjects::put(object)
        object
    end

    # Fragments::issueNewFragmentInteractivelyOrNull()
    def self.issueNewFragmentInteractivelyOrNull()
        puts "Making a new Fragment..."
        types = ["line", "url", "text", "fs-location aion-point", "unique-name"]
        type = LucilleCore::selectEntityFromListOfEntitiesOrNull("type", types)
        return if type.nil?
        if type == "line" then
            line = LucilleCore::askQuestionAnswerAsString("line: ")
            return nil if line.size == 0
            return Fragments::issueLine(line)
        end
        if type == "url" then
            url = LucilleCore::askQuestionAnswerAsString("url: ")
            return nil if url.size == 0
            return Fragments::issueUrl(url)
        end
        if type == "text" then
            text = Miscellaneous::editTextUsingTextmate("").strip
            return nil if text.size == 0
            return Fragments::issueText(text)
        end
        if type == "fs-location aion-point" then
            location = Fragments::selectOneLocationOnTheDesktopOrNull()
            return nil if location.nil?
            namedhash = LibrarianOperator::commitLocationDataAndReturnNamedHash(location)
            return Fragments::issueAionPoint(namedhash)
        end
        if type == "unique-name" then
            uniquename = LucilleCore::askQuestionAnswerAsString("unique name: ")
            return nil if uniquename.size == 0
            return Fragments::issueUniqueName(uniquename)
        end
    end

    # Fragments::fragments()
    def self.fragments()
        NyxObjects::getSet("0f555c97-3843-4dfe-80c8-714d837eba69")
    end

    # Fragments::fragmentToString(fragment)
    def self.fragmentToString(fragment)
        str = InMemoryWithOnDiskPersistenceValueCache::getOrNull("e7eb4787-0cfd-4184-a286-1dbec629d9e8:#{fragment["uuid"]}")
        return str if str

        str = (lambda{|fragment|
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

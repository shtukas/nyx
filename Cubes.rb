
# encoding: UTF-8

class CubeCached
    # CubeCached::forget(cube)
    def self.forget(cube)
        InMemoryWithOnDiskPersistenceValueCache::delete("e7eb4787-0cfd-4184-a286-1dbec629d9e8:#{cube["uuid"]}")
    end
end

class Cubes

    # Cubes::selectOneLocationOnTheDesktopOrNull()
    def self.selectOneLocationOnTheDesktopOrNull()
        desktopLocations = LucilleCore::locationsAtFolder("/Users/pascal/Desktop")
                            .select{|filepath| filepath[0,1] != '.' }
                            .select{|filepath| File.basename(filepath) != 'pascal.png' }
                            .select{|filepath| File.basename(filepath) != 'Todo-Inbox' }
                            .sort
        LucilleCore::selectEntityFromListOfEntitiesOrNull("filepath", desktopLocations, lambda{ |location| File.basename(location) })
    end

    # Cubes::issueLine(line)
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

    # Cubes::issueUrl(url)
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

    # Cubes::issueText(text)
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

    # Cubes::issueAionHypercube(namedhash)
    def self.issueAionHypercube(namedhash)
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

    # Cubes::issueUniqueName(uniquename)
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

    # Cubes::issueNewCubeInteractivelyOrNull()
    def self.issueNewCubeInteractivelyOrNull()
        puts "Making a new Cube..."
        types = ["line", "url", "text", "fs-location aion-point", "unique-name"]
        type = LucilleCore::selectEntityFromListOfEntitiesOrNull("type", types)
        return if type.nil?
        if type == "line" then
            line = LucilleCore::askQuestionAnswerAsString("line: ")
            return nil if line.size == 0
            return Cubes::issueLine(line)
        end
        if type == "url" then
            url = LucilleCore::askQuestionAnswerAsString("url: ")
            return nil if url.size == 0
            return Cubes::issueUrl(url)
        end
        if type == "text" then
            text = Miscellaneous::editTextUsingTextmate("").strip
            return nil if text.size == 0
            return Cubes::issueText(text)
        end
        if type == "fs-location aion-point" then
            location = Cubes::selectOneLocationOnTheDesktopOrNull()
            return nil if location.nil?
            namedhash = LibrarianOperator::commitLocationDataAndReturnNamedHash(location)
            return Cubes::issueAionHypercube(namedhash)
        end
        if type == "unique-name" then
            uniquename = LucilleCore::askQuestionAnswerAsString("unique name: ")
            return nil if uniquename.size == 0
            return Cubes::issueUniqueName(uniquename)
        end
    end

    # Cubes::cubes()
    def self.cubes()
        NyxObjects::getSet("0f555c97-3843-4dfe-80c8-714d837eba69")
    end

    # Cubes::cubeToString(cube)
    def self.cubeToString(cube)
        str = InMemoryWithOnDiskPersistenceValueCache::getOrNull("e7eb4787-0cfd-4184-a286-1dbec629d9e8:#{cube["uuid"]}")
        return str if str

        str = (lambda{|cube|
            if cube["type"] == "line" then
                return "[cube] [#{cube["uuid"][0, 4]}] [#{cube["type"]}] #{cube["line"]}"
            end
            if cube["type"] == "url" then
                return "[cube] [#{cube["uuid"][0, 4]}] [#{cube["type"]}] #{cube["url"]}"
            end
            if cube["type"] == "text" then
                namedhashToFirstLine = lambda {|namedhash|
                    text = NyxBlobs::getBlobOrNull(namedhash).strip
                    line = text.size>0 ? text.lines.first.strip : "[empty text]"
                }
                return "[cube] [#{cube["uuid"][0, 4]}] [#{cube["type"]}] #{namedhashToFirstLine.call(cube["namedhash"])}"
            end
            if cube["type"] == "aion-point" then
                return "[cube] [#{cube["uuid"][0, 4]}] [#{cube["type"]}] #{cube["namedhash"]}"
            end
            if cube["type"] == "unique-name" then
                return "[cube] [#{cube["uuid"][0, 4]}] [#{cube["type"]}] #{cube["name"]}"
            end
            raise "[Cubes error 2c53b113-cc79]"
        }).call(cube)

        InMemoryWithOnDiskPersistenceValueCache::set("e7eb4787-0cfd-4184-a286-1dbec629d9e8:#{cube["uuid"]}", str)
        str
    end

    # Cubes::openCube(hypercube, cube)
    def self.openCube(hypercube, cube)
        if cube["type"] == "line" then
            puts cube["line"]
            LucilleCore::pressEnterToContinue()
            return
        end
        if cube["type"] == "url" then
            system("open '#{cube["url"]}'")
            return
        end
        if cube["type"] == "text" then
            system("clear")
            namedhash = cube["namedhash"]
            text = NyxBlobs::getBlobOrNull(namedhash)
            puts text
            LucilleCore::pressEnterToContinue()
            return
        end
        if cube["type"] == "aion-point" then
            folderpath = DeskOperator::deskFolderpathForCubeCreateIfNotExists(hypercube, cube)
            system("open '#{folderpath}'")
            return
        end
        if cube["type"] == "unique-name" then
            uniquename = cube["name"]
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
        raise "[Cube error 4bf5cfb1-c2a2]"
    end
end

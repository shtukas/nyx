
# encoding: UTF-8

class Quarks

    # Quarks::quarks()
    def self.quarks()
        NSCoreObjects::getSet("d65674c7-c8c4-4ed4-9de9-7c600b43eaab")
    end

    # --------------------------------------------------

    # Quarks::makeLine(line)
    def self.makeLine(line)
        {
            "uuid"              => SecureRandom.uuid,
            "nyxNxSet"          => "d65674c7-c8c4-4ed4-9de9-7c600b43eaab",
            "unixtime"          => Time.new.to_f,
            "type"              => "line",
            "line"              => line
        }
    end

    # Quarks::makeUrl(url)
    def self.makeUrl(url)
         {
            "uuid"              => SecureRandom.uuid,
            "nyxNxSet"          => "d65674c7-c8c4-4ed4-9de9-7c600b43eaab",
            "unixtime"          => Time.new.to_f,
            "type"              => "url",
            "url"               => url
        }
    end

    # Quarks::makeFileSystemUniqueString(mark)
    def self.makeFileSystemUniqueString(mark)
         {
            "uuid"              => SecureRandom.uuid,
            "nyxNxSet"          => "d65674c7-c8c4-4ed4-9de9-7c600b43eaab",
            "unixtime"          => Time.new.to_f,
            "type"              => "filesystem-unique-string",
            "mark"              => mark
        }
    end

    # Quarks::makeAionFileSystemLocation(location)
    def self.makeAionFileSystemLocation(location)
        operator = ElizabethX2.new()
        {
            "uuid"              => SecureRandom.uuid,
            "nyxNxSet"          => "d65674c7-c8c4-4ed4-9de9-7c600b43eaab",
            "unixtime"          => Time.new.to_f,
            "type"              => "aion-location",
            "roothash"          => AionCore::commitLocationReturnHash(operator, location)
        }
    end

    # --------------------------------------------------

    # Quarks::issueUrl(url)
    def self.issueUrl(url)
        object = Quarks::makeUrl(url)
        NSCoreObjects::put(object)
        object
    end

    # Quarks::issuefileSystemUniqueString(mark)
    def self.issuefileSystemUniqueString(mark)
        object = Quarks::makeFileSystemUniqueString(mark)
        NSCoreObjects::put(object)
        object
    end

    # Quarks::issueAionFileSystemLocation(location)
    def self.issueAionFileSystemLocation(location)
        object = Quarks::makeAionFileSystemLocation(location)
        NSCoreObjects::put(object)
        object
    end

    # --------------------------------------------------

    # Quarks::determineMarkOrNull()
    def self.determineMarkOrNull()
        op = LucilleCore::selectEntityFromListOfEntitiesOrNull("mode", ["unique string already exists", "issue new unique string"])
        return nil if op.nil?
        mark = nil
        if op == "unique string already exists" then
            mark = LucilleCore::askQuestionAnswerAsString("mark: ")
            return nil if mark.size == 0
        end
        if op == "issue new unique string" then
            mark = "NX141-#{SecureRandom.hex(5)}" # Although filesystem-unique-string is more general than Nx141, by default we create one of those.
            puts "mark: #{mark}"
            LucilleCore::pressEnterToContinue()
        end
        mark
    end

    # Quarks::issueNewQuarkInteractivelyOrNull()
    def self.issueNewQuarkInteractivelyOrNull()
        type = LucilleCore::selectEntityFromListOfEntitiesOrNull("type", ["line", "url", "filesystem-unique-string", "aion-point"])
        if type == "line" then
            line = LucilleCore::askQuestionAnswerAsString("line: ")
            quark = Quarks::makeLine(line)
            quark["description"] = line
            NSCoreObjects::put(quark)
            return quark
        end
        if type == "url" then
            url = LucilleCore::askQuestionAnswerAsString("url: ")
            quark = Quarks::makeUrl(url)
            quark["description"] = LucilleCore::askQuestionAnswerAsString("quark description: ")
            NSCoreObjects::put(quark)
            return quark
        end
        if type == "filesystem-unique-string" then
            mark = Quarks::determineMarkOrNull()
            return if mark.nil?
            quark = Quarks::makeFileSystemUniqueString(mark)
            quark["description"] = LucilleCore::askQuestionAnswerAsString("quark description: ")
            NSCoreObjects::put(quark)
            return quark
        end
        if type == "aion-point" then
            locationname = LucilleCore::askQuestionAnswerAsString("location name on Desktop: ")
            location = "/Users/pascal/Desktop/#{locationname}"
            quark = Quarks::makeAionFileSystemLocation(location)
            quark["description"] = LucilleCore::askQuestionAnswerAsString("quark description: ")
            NSCoreObjects::put(quark)
            return quark
        end
        nil
    end

    # Quarks::makeUnsavedQuarkForTransmutationInteractivelyOrNull()
    def self.makeUnsavedQuarkForTransmutationInteractivelyOrNull()
        type = LucilleCore::selectEntityFromListOfEntitiesOrNull("type", ["line", "url", "filesystem-unique-string", "aion-point"])
        if type == "line" then
            line = LucilleCore::askQuestionAnswerAsString("line: ")
            quark = Quarks::makeLine(line)
            quark["description"] = line
            return quark
        end
        if type == "url" then
            url = LucilleCore::askQuestionAnswerAsString("url: ")
            quark = Quarks::makeUrl(url)
            quark["description"] = LucilleCore::askQuestionAnswerAsString("quark description: ")
            return quark
        end
        if type == "filesystem-unique-string" then
            mark = Quarks::determineMarkOrNull()
            return nil if mark.nil?
            quark = Quarks::makeFileSystemUniqueString(mark)
            quark["description"] = LucilleCore::askQuestionAnswerAsString("quark description: ")
            return quark
        end
        if type == "aion-point" then
            locationname = LucilleCore::askQuestionAnswerAsString("location name on Desktop: ")
            location = "/Users/pascal/Desktop/#{locationname}"
            quark = Quarks::makeAionFileSystemLocation(location)
            quark["description"] = LucilleCore::askQuestionAnswerAsString("quark description: ")
            return quark
        end
        nil
    end

    # --------------------------------------------------

    # Quarks::setDescription(quark, description)
    def self.setDescription(quark, description)
        quark["description"] = description
        NSCoreObjects::put(quark)
        quark
    end

    # Quarks::toString(quark)
    def self.toString(quark)
        if quark["description"] then
            return "[quark] [#{quark["type"]}] #{quark["description"]}"
        end
        if quark["type"] == "line" then
            return "[quark] line: #{quark["line"]}"
        end
        if quark["type"] == "url" then
            return "[quark] url: #{quark["url"]}"
        end
        if quark["type"] == "filesystem-unique-string" then
            return "[quark] filesystem-unique-string: #{quark["mark"]}"
        end
        if quark["type"] == "aion-location" then
            operator = ElizabethX2.new()
            aionobject = AionCore::getAionObjectByHash(operator, quark["roothash"])
            description = aionobject["name"]
            return "[quark] aion-location: #{description}"
        end
        puts quark
        raise "error: 963c91c2-1370-4807-8d89-96c9065de3ea"
    end

    # --------------------------------------------------

    # Quarks::open1(quark)
    def self.open1(quark)
        puts "opening: #{Quarks::toString(quark)}"

        type = quark["type"]
        if type == "line" then
            puts quark["line"]
            LucilleCore::pressEnterToContinue()
            return
        end
        if type == "url" then
            url = quark["url"]
            puts url
            system("open '#{url}'")
            return
        end
        if type == "filesystem-unique-string" then
            location = GalaxyFinder::uniqueStringToLocationOrNull(quark["mark"])
            if location.nil? then
                puts "I could not determine location for mark: #{quark["mark"]}"
                LucilleCore::pressEnterToContinue()
            else
                if File.file?(location) then
                    option = LucilleCore::selectEntityFromListOfEntitiesOrNull("mode", ["open file", "open parent folder"])
                    return if option.nil?
                    if option == "open file" then
                        system("open '#{location}'")
                    end
                    if option == "open parent folder" then
                        system("open '#{File.dirname(location)}'")
                    end
                else
                    system("open '#{location}'")
                end
            end
            return
        end
        if type == "aion-location" then
            operator = ElizabethX2.new()
            nhash = quark["roothash"]
            targetReconstructionFolderpath = "/Users/pascal/Desktop"
            AionCore::exportHashAtFolder(operator, nhash, targetReconstructionFolderpath)
            puts "aion point exported (nhash: #{nhash})"
            options = ["read only", "read ; edit ; update", "read ; transmute"]
            option = LucilleCore::selectEntityFromListOfEntitiesOrNull("mode", options)
            return if option.nil? # We assume read only
            if option == "read only" then

            end
            if option == "read ; edit ; update" then
                # Same as b83fd7f7-b906-44dc-96a0-71b9f1684b3a
                locationname = LucilleCore::askQuestionAnswerAsString("location name on Desktop: ")
                location = "/Users/pascal/Desktop/#{locationname}"
                quark["roothash"] = AionCore::commitLocationReturnHash(operator, location)
                NSCoreObjects::put(quark)
            end
            if option == "read ; transmute" then
                object = Quarks::makeUnsavedQuarkForTransmutationInteractivelyOrNull()
                object["uuid"] = quark["uuid"] # transmutation
                NSCoreObjects::put(object)
            end
            return
        end
        raise "error: c9b7f9a2-c0d0-4a86-add8-3ca411b8c240"
    end

    # Quarks::landing(quark)
    def self.landing(quark)
        loop {

            return if NSCoreObjects::getOrNull(quark["uuid"]).nil?
            quark = NSCoreObjects::getOrNull(quark["uuid"]) # could have been transmuted in the previous loop

            system("clear")

            mx = LCoreMenuItemsNX1.new()

            puts Quarks::toString(quark)
            puts "uuid: #{quark["uuid"]}".yellow

            puts ""

            Arrows::getSourcesForTarget(quark).each{|source|
                mx.item(
                    "source: #{Patricia::toString(source)}",
                    lambda { Patricia::landing(source) }
                )
            }

            puts ""

            mx.item(
                "access".yellow,
                lambda { Quarks::open1(quark) }
            )

            mx.item(
                "start".yellow,
                lambda { 
                    parents = Arrows::getSourcesForTarget(quark)
                    dxthreads = parents.select{|parent| Patricia::isDxThread(parent) }
                    return if dxthreads.empty?
                    if dxthreads.size == 1 then
                        dxthread = dxthreads[0]
                        DxThreads::nextNaturalStepWhenStopped(dxthread, quark)
                        return
                    end
                    puts "I do not yet know how to start a quark which has more than one DxThread parent"
                    LucilleCore::pressEnterToContinue()
                }
            )

            mx.item(
                "transmute".yellow,
                lambda { 
                    object = Quarks::makeUnsavedQuarkForTransmutationInteractivelyOrNull()
                    return if object.nil?
                    object["uuid"] = quark["uuid"] # transmutation
                    NSCoreObjects::put(object)
                }
            )

            mx.item("set/update description".yellow, lambda {
                description = LucilleCore::askQuestionAnswerAsString("description: ")
                return if description == ""
                Quarks::setDescription(quark, description)
            })

            mx.item("edit".yellow, lambda {
                if quark["type"] == "line" then
                    line = Miscellaneous::editTextSynchronously(quark["line"]).strip
                    return if line == ""
                    quark["line"] = line
                    NSCoreObjects::put(quark)
                    return
                end
                if quark["type"] == "url" then
                    url = Miscellaneous::editTextSynchronously(quark["url"]).strip
                    return if url == ""
                    quark["url"] = url
                    NSCoreObjects::put(quark)
                    return
                end
                if quark["type"] == "aion-location" then
                    operator = ElizabethX2.new()
                    nhash = quark["roothash"]
                    targetReconstructionFolderpath = "/Users/pascal/Desktop"
                    AionCore::exportHashAtFolder(operator, nhash, targetReconstructionFolderpath)
                    puts "aion point exported ; edit and ..."
                    LucilleCore::pressEnterToContinue()
                    # Same as b83fd7f7-b906-44dc-96a0-71b9f1684b3a
                    locationname = LucilleCore::askQuestionAnswerAsString("location name on Desktop: ")
                    location = "/Users/pascal/Desktop/#{locationname}"
                    quark["roothash"] = AionCore::commitLocationReturnHash(operator, location)
                    NSCoreObjects::put(quark)
                    return
                end
                puts quark
                raise "error: 08bd13f4-dbb6-4823-aa7e-2e9960936eb6"
            })

            mx.item("json object".yellow, lambda { 
                puts JSON.pretty_generate(quark)
                LucilleCore::pressEnterToContinue()
            })

            mx.item(
                "destroy".yellow,
                lambda { 
                    if LucilleCore::askQuestionAnswerAsBoolean("Are you sure you want to destroy this quark ? ") then
                        Quarks::destroyQuark(quark)
                    end
                }
            )

            puts ""

            status = mx.promptAndRunSandbox()
            break if !status
        }
    end

    # Quarks::destroyQuark(quark)
    def self.destroyQuark(quark)
        if quark["type"] == "filesystem-unique-string" then
            puts "deleting quark filesystem-unique-string: #{Quarks::toString(quark)}"
            location = GalaxyFinder::uniqueStringToLocationOrNull(quark["mark"])
            if location then
                puts "Target file '#{location}'"
                puts "Delete as appropriate"
                system("open '#{File.dirname(location)}'")
                LucilleCore::pressEnterToContinue()
            else
                puts "I could not determine the location of #{quark["mark"]}"
                if !LucilleCore::askQuestionAnswerAsBoolean("Continue with quark deletion ? ") then
                    return
                end
            end
        end
        NSCoreObjects::destroy(quark)
    end
end

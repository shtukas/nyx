
# encoding: UTF-8

class Quarks

    # Quarks::quarks()
    def self.quarks()
        NyxObjects2::getSet("d65674c7-c8c4-4ed4-9de9-7c600b43eaab")
    end

    # --------------------------------------------------

    # Quarks::makeLine(line)
    def self.makeLine(line)
        {
            "uuid"              => SecureRandom.uuid,
            "nyxNxSet"          => "d65674c7-c8c4-4ed4-9de9-7c600b43eaab",
            "unixtime"          => Time.new.to_f,
            "referenceDateTime" => nil,
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
            "referenceDateTime" => nil,
            "type"              => "url",
            "url"               => url
        }
    end

    # Quarks::makeAionFileSystemLocation(aionFileSystemLocation)
    def self.makeAionFileSystemLocation(aionFileSystemLocation)
        {
            "uuid"              => SecureRandom.uuid,
            "nyxNxSet"          => "d65674c7-c8c4-4ed4-9de9-7c600b43eaab",
            "unixtime"          => Time.new.to_f,
            "referenceDateTime" => nil,
            "type"              => "aion-location",
            "roothash"          => AionCore::commitLocationReturnHash(operator, aionFileSystemLocation)
        }
    end

    # --------------------------------------------------

    # Quarks::issueUrl(url)
    def self.issueUrl(url)
        object = Quarks::makeUrl(url)
        NyxObjects2::put(object)
        object
    end

    # Quarks::issueAionFileSystemLocation(aionFileSystemLocation)
    def self.issueAionFileSystemLocation(aionFileSystemLocation)
        object = Quarks::makeAionFileSystemLocation(aionFileSystemLocation)
        NyxObjects2::put(object)
        object
    end

    # --------------------------------------------------

    # Quarks::issueNewQuarkInteractivelyOrNull()
    def self.issueNewQuarkInteractivelyOrNull()
        type = LucilleCore::selectEntityFromListOfEntitiesOrNull("type", ["line", "url", "aion-point"])
        if type == "line" then
            line = LucilleCore::askQuestionAnswerAsString("line: ")
            quark = Quarks::makeLine(line)
            quark["description"] = line
            NyxObjects2::put(quark)
            return quark
        end
        if type == "url" then
            url = LucilleCore::askQuestionAnswerAsString("url: ")
            quark = Quarks::makeUrl(url)
            quark["description"] = LucilleCore::askQuestionAnswerAsString("description: ")
            NyxObjects2::put(quark)
            return quark
        end
        if type == "aion-point" then
            locationname = LucilleCore::askQuestionAnswerAsString("location name on Desktop: ")
            aionFileSystemLocation = "/Users/pascal/Desktop/#{locationname}"
            quark = Quarks::makeAionFileSystemLocation(aionFileSystemLocation)
            quark["description"] = LucilleCore::askQuestionAnswerAsString("description: ")
            NyxObjects2::put(quark)
            return quark
        end
        nil
    end

    # Quarks::makeUnsavedQuarkForTransmutationInteractivelyOrNull()
    def self.makeUnsavedQuarkForTransmutationInteractivelyOrNull()
        type = LucilleCore::selectEntityFromListOfEntitiesOrNull("type", ["line", "url", "aion-point"])
        if type == "line" then
            line = LucilleCore::askQuestionAnswerAsString("line: ")
            quark = Quarks::makeLine(line)
            quark["description"] = line
            return quark
        end
        if type == "url" then
            url = LucilleCore::askQuestionAnswerAsString("url: ")
            quark = Quarks::makeUrl(url)
            quark["description"] = LucilleCore::askQuestionAnswerAsString("description: ")
            return quark
        end
        if type == "aion-point" then
            locationname = LucilleCore::askQuestionAnswerAsString("location name on Desktop: ")
            aionFileSystemLocation = "/Users/pascal/Desktop/#{locationname}"
            quark = Quarks::makeAionFileSystemLocation(aionFileSystemLocation)
            quark["description"] = LucilleCore::askQuestionAnswerAsString("description: ")
            return quark
        end
        nil
    end

    # --------------------------------------------------

    # Quarks::setDescription(quark, description)
    def self.setDescription(quark, description)
        quark["description"] = description
        NyxObjects2::put(quark)
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
                aionFileSystemLocation = "/Users/pascal/Desktop/#{locationname}"
                quark["roothash"] = AionCore::commitLocationReturnHash(operator, aionFileSystemLocation)
                NyxObjects2::put(quark)
            end
            if option == "read ; transmute" then
                object = Patricia::makeNewUnsavedDatapointForTransmutationInteractivelyOrNull()
                object["uuid"] = quark["uuid"] # transmutation
                NyxObjects2::put(object)
            end
            return
        end
        raise "error: c9b7f9a2-c0d0-4a86-add8-3ca411b8c240"
    end

    # Quarks::landing(quark)
    def self.landing(quark)
        loop {

            return if NyxObjects2::getOrNull(quark["uuid"]).nil?
            return if (NyxObjects2::getOrNull(quark["uuid"])["nyxNxSet"] != "d65674c7-c8c4-4ed4-9de9-7c600b43eaab") # could have been transmuted in the previous loop

            system("clear")

            mx = LCoreMenuItemsNX1.new()

            puts Quarks::toString(quark)
            puts "uuid: #{quark["uuid"]}".yellow

            puts ""

            Patricia::mxSourcing(quark, mx)

            puts ""

            Patricia::mxTargetting(quark, mx)

            puts ""

            mx.item(
                "access".yellow,
                lambda { Quarks::open1(quark) }
            )

            mx.item(
                "transmute".yellow,
                lambda { 
                    object = Patricia::makeNewUnsavedDatapointForTransmutationInteractivelyOrNull()
                    object["uuid"] = quark["uuid"] # transmutation
                    NyxObjects2::put(object)
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
                    NyxObjects2::put(quark)
                    return
                end
                if quark["type"] == "url" then
                    url = Miscellaneous::editTextSynchronously(quark["url"]).strip
                    return if url == ""
                    quark["url"] = url
                    NyxObjects2::put(quark)
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
                    aionFileSystemLocation = "/Users/pascal/Desktop/#{locationname}"
                    quark["roothash"] = AionCore::commitLocationReturnHash(operator, aionFileSystemLocation)
                    NyxObjects2::put(quark)
                    return
                end
                puts quark
                raise "error: 08bd13f4-dbb6-4823-aa7e-2e9960936eb6"
            })


            mx.item("json object".yellow, lambda { 
                puts JSON.pretty_generate(quark)
                LucilleCore::pressEnterToContinue()
            })

            Patricia::mxParentsManagement(quark, mx)

            Patricia::mxMoveToNewParent(quark, mx)

            mx.item(
                "destroy".yellow,
                lambda { 
                    if LucilleCore::askQuestionAnswerAsBoolean("are you sure you want to destroy this quark ? ") then
                        NyxObjects2::destroy(quark)
                    end
                }
            )

            puts ""

            status = mx.promptAndRunSandbox()
            break if !status
        }
    end
end

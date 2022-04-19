
# encoding: UTF-8

class Nx111

    # Nx111::iamTypes()
    def self.iamTypes()
        [
            "navigation",
            "log",
            "description-only",
            "text",
            "url",
            "aion-point",
            "unique-string",
            "primitive-file",
            "carrier-of-primitive-files",
            "Dx8Unit"
        ]
    end

    # Nx111::iamTypesForManualMakingOfNyxNodes()
    def self.iamTypesForManualMakingOfNyxNodes()
        [
            "navigation",
            "log",
            "text",
            "url",
            "aion-point",
            "unique-string",
            "primitive-file",
            "carrier-of-primitive-files",
            "Dx8Unit"
        ]
    end

    # Nx111::iamTypesForManualMakingOfCatalystItems()
    def self.iamTypesForManualMakingOfCatalystItems()
        [
            "description-only (default)",
            "text",
            "url",
            "aion-point",
            "unique-string",
            "Dx8Unit"
        ]
    end

    # Nx111::interactivelySelectIamTypeOrNull(types)
    def self.interactivelySelectIamTypeOrNull(types)
        type = LucilleCore::selectEntityFromListOfEntitiesOrNull("iam type", types)
        if type.nil? and types.include?("description-only (default)") then
            return "description-only"
        end
        type
    end

    # Nx111::primitiveFileIamValueFromLocationOrNull(location)
    def self.primitiveFileIamValueFromLocationOrNull(location)
        data = Librarian17PrimitiveFilesAndCarriers::readPrimitiveFileOrNull(location)
        return nil if data.nil?
        dottedExtension, nhash, parts = data
        ["primitive-file", dottedExtension, nhash, parts]
    end

    # Nx111::interactivelyCreateNewIamValueOrNull(types)
    def self.interactivelyCreateNewIamValueOrNull(types)
        type = Nx111::interactivelySelectIamTypeOrNull(types)
        return nil if type.nil?
        if type == "navigation" then
            return ["navigation"]
        end
        if type == "log" then
            return ["log"]
        end
        if type == "description-only" then
            return ["description-only"]
        end
        if type == "text" then
            text = Librarian0Utils::editTextSynchronously("")
            nhash = Librarian12LocalBlobsService::putBlob(text)
            return ["text", nhash]
        end
        if type == "url" then
            url = LucilleCore::askQuestionAnswerAsString("url (empty to abort): ")
            return nil if url == ""
            return ["url", url]
        end
        if type == "aion-point" then
            location = Librarian0Utils::interactivelySelectDesktopLocationOrNull()
            return nil if location.nil?
            return nil if !File.exists?(location)
            rootnhash = AionCore::commitLocationReturnHash(Librarian14ElizabethLocalStandard.new(), location)
            return ["aion-point", rootnhash]
        end
        if type == "unique-string" then
            uniquestring = LucilleCore::askQuestionAnswerAsString("unique string (use 'Nx01-#{SecureRandom.hex(6)}' if need one): ")
            return nil if uniquestring == ""
            return ["unique-string", uniquestring]
        end
        if type == "primitive-file" then
            location = Librarian0Utils::interactivelySelectDesktopLocationOrNull()
            return nil if location.nil?
            return Nx111::primitiveFileIamValueFromLocationOrNull(location)
        end
        if type == "carrier-of-primitive-files" then
            return ["carrier-of-primitive-files"]
        end
        if type == "Dx8Unit" then
            unitId = Utils::nx45()
            location = Librarian0Utils::interactivelySelectDesktopLocationOrNull()
            return nil if location.nil?
            return nil if !File.exists?(location)
            rootnhash = AionCore::commitLocationReturnHash(Librarian24ElizabethForDx8Units.new(unitId, "upload"), location)
            configuration = {
                "unitId"   => unitId,
                "status"   => "standard",
                "rootnhash" => rootnhash
            }
            return ["Dx8Unit", configuration]
        end
        raise "(error: aae1002c-2f78-4c2b-9455-bdd0b5c0ebd6): #{type}"
    end

    # Nx111::accessIamCarrierPossibleStorageMutation(item)
    def self.accessIamCarrierPossibleStorageMutation(item)
        iAmValue = item["iam"]
        if iAmValue[0] == "navigation" then
            puts "This is a navigation node"
            LucilleCore::pressEnterToContinue()
            return
        end
        if iAmValue[0] == "log" then
            puts "This is a log"
            LucilleCore::pressEnterToContinue()
            return
        end
        if iAmValue[0] == "description-only" then
            puts "This is a description-only"
            LucilleCore::pressEnterToContinue()
            return
        end
        if iAmValue[0] == "text" then
            nhash = iAmValue[1]
            text1 = Librarian12LocalBlobsService::getBlobOrNull(nhash)
            text2 = Librarian0Utils::editTextSynchronously(text1)
            if text1 != text2 then
                iAmValue[1] = Librarian12LocalBlobsService::putBlob(text2)
                item["iam"] = iAmValue
                Librarian6Objects::commit(item)
            end
            return
        end
        if iAmValue[0] == "url" then
            url = iAmValue[1]
            puts "url: #{url}"
            Librarian0Utils::openUrlUsingSafari(url)
            LucilleCore::pressEnterToContinue()
            return
        end
        if iAmValue[0] == "aion-point" then
            tx46Id = Librarian15BecauseReadWrite::issueTx46ReturnIdentifier(item)

            rootnhash = iAmValue[1]
            exportFolder = "/Users/pascal/Desktop/#{item["description"]} (#{tx46Id})"
            puts "export folder: #{exportFolder}"
            FileUtils.mkdir(exportFolder)
            AionCore::exportHashAtFolder(Librarian14ElizabethLocalStandard.new(), rootnhash, exportFolder)
            system("open '#{exportFolder}'")
            return
        end
        if iAmValue[0] == "unique-string" then
            uniquestring = iAmValue[1]
            Nx111::findAndAccessUniqueString(uniquestring)
            return
        end
        if iAmValue[0] == "primitive-file" then
            _, dottedExtension, nhash, parts = iAmValue
            location = "/Users/pascal/Desktop"
            filepath = Librarian17PrimitiveFilesAndCarriers::exportPrimitiveFileAtLocation(item["uuid"], dottedExtension, parts, location)
            LucilleCore::pressEnterToContinue()
            if File.exists?(filepath) and LucilleCore::askQuestionAnswerAsBoolean("delete file on the desktop ? ") then
                FileUtils.rm(filepath)
            end
            return
        end
        if iAmValue[0] == "carrier-of-primitive-files" then
            Librarian17PrimitiveFilesAndCarriers::exportCarrier(item)
            return
        end
        if iAmValue[0] == "Dx8Unit" then
            configuration = iAmValue[1]

            if configuration["status"] == "standard" then
                tx46Id = Librarian15BecauseReadWrite::issueTx46ReturnIdentifier(item)
                
                unitId = configuration["unitId"]
                rootnhash = configuration["rootnhash"]
                exportFolder = "/Users/pascal/Desktop/#{item["description"]} (#{tx46Id})"
                puts "export folder: #{exportFolder}"
                FileUtils.mkdir(exportFolder)
                AionCore::exportHashAtFolder(Librarian24ElizabethForDx8Units.new(unitId, "readonly"), rootnhash, exportFolder)
                system("open '#{exportFolder}'")
                return
            end

            raise "(error: 3d84d2b9-56c3-4762-b6a8-8a50c66b9240): #{item}, #{iAmValue}"
        end
        raise "(error: 3cbb1e64-0d18-48c5-bd28-f4ba584659a3): #{item}"
    end

    # Nx111::atomuuidToNx111(atomuuid)
    def self.atomuuidToNx111(atomuuid)
        atom = Librarian6Objects::getObjectByUUIDOrNull(atomuuid)
        puts JSON.pretty_generate(atom)

        if atom["type"] == "aion-point" then
            return ["aion-point", atom["rootnhash"]]
        end

        if atom["type"] == "description-only" then
            return ["description-only"]
        end

        if atom["type"] == "text" then
            return ["text", atom["payload"]]
        end

        if atom["type"] == "url" then
            return ["url", atom["payload"]]
        end

        if atom["type"] =="unique-string" then
            return ["unique-string", atom["payload"]]
        end

        raise "()"
    end

    # ----------------------------------------------------------------------
    # The art of the unique string

    # Nx111::uniqueStringIsInAionPointObject(object, uniquestring)
    def self.uniqueStringIsInAionPointObject(object, uniquestring)
        if object["aionType"] == "indefinite" then
            return false
        end
        if object["aionType"] == "directory" then
            if object["name"].downcase.include?(uniquestring.downcase) then
                return true
            end
            return object["items"].any?{|nhash| Nx111::uniqueStringIsInNhash(nhash, uniquestring) }
        end
        if object["aionType"] == "file" then
            return object["name"].downcase.include?(uniquestring.downcase)
        end
    end

    # Nx111::uniqueStringIsInNhash(nhash, uniquestring)
    def self.uniqueStringIsInNhash(nhash, uniquestring)
        # This function will cause all the objects from all aion-structures to remain alive on the local cache
        # but doesn't download the data blobs

        # This function is memoised
        answer = XCache::getOrNull("4cd81dd8-822b-4ec7-8065-728e2dfe2a8a:#{nhash}:#{uniquestring}")
        if answer then
            return JSON.parse(answer)[0]
        end
        object = AionCore::getAionObjectByHash(Librarian14ElizabethLocalStandard.new(), nhash)
        answer = Nx111::uniqueStringIsInAionPointObject(object, uniquestring)
        XCache::set("4cd81dd8-822b-4ec7-8065-728e2dfe2a8a:#{nhash}:#{uniquestring}", JSON.generate([answer]))
        answer
    end

    # Nx111::findAndAccessUniqueString(uniquestring)
    def self.findAndAccessUniqueString(uniquestring)
        puts "unique string: #{uniquestring}"
        location = Librarian0Utils::uniqueStringLocationUsingFileSystemSearchOrNull(uniquestring)
        if location then
            puts "location: #{location}"
            if LucilleCore::askQuestionAnswerAsBoolean("open ? ", true) then
                system("open '#{location}'")
            end
            return
        end
        puts "Unique string not found in Galaxy"
        puts "Looking inside aion-points..."
        puts "" # To accomodate Utils::putsOnPreviousLine

        puts "This functionality needs implementing (a2af6b27-132b-44c1-935a-739df2eaf627)"
        LucilleCore::pressEnterToContinue()

        puts "I could not find the unique string inside aion-points"
        LucilleCore::pressEnterToContinue()
    end

end

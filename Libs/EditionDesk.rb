
# encoding: UTF-8

class AionTransforms

    # AionTransforms::extractTopName(operator, rootnhash)
    def self.extractTopName(operator, rootnhash)
        AionCore::getAionObjectByHash(operator, rootnhash)["name"]
    end

    # AionTransforms::rewriteThisAionRootWithNewTopNameRespectDottedExtensionIfTheresOne(operator, rootnhash, name1)
    def self.rewriteThisAionRootWithNewTopNameRespectDottedExtensionIfTheresOne(operator, rootnhash, name1)
        aionObject = AionCore::getAionObjectByHash(operator, rootnhash)
        name2 = aionObject["name"]
        # name1 : name we want
        # name2 : name we have, possibly with an .extension
        if File.extname(name2) then
            aionObject["name"] = "#{name1}#{File.extname(name2)}"
        else
            aionObject["name"] = name1
        end
        blob = JSON.generate(aionObject)
        operator.commitBlob(blob)
    end
end

class UniqueStringsFunctions
    # UniqueStringsFunctions::uniqueStringIsInAionPointObject(object, uniquestring)
    def self.uniqueStringIsInAionPointObject(object, uniquestring)
        if object["aionType"] == "indefinite" then
            return false
        end
        if object["aionType"] == "directory" then
            if object["name"].downcase.include?(uniquestring.downcase) then
                return true
            end
            return object["items"].any?{|nhash| UniqueStringsFunctions::uniqueStringIsInNhash(nhash, uniquestring) }
        end
        if object["aionType"] == "file" then
            return object["name"].downcase.include?(uniquestring.downcase)
        end
    end

    # UniqueStringsFunctions::uniqueStringIsInNhash(nhash, uniquestring)
    def self.uniqueStringIsInNhash(nhash, uniquestring)
        # This function will cause all the objects from all aion-structures to remain alive on the local cache
        # but doesn't download the data blobs

        # This function is memoised
        answer = XCache::getOrNull("4cd81dd8-822b-4ec7-8065-728e2dfe2a8a:#{nhash}:#{uniquestring}")
        if answer then
            return JSON.parse(answer)[0]
        end
        object = AionCore::getAionObjectByHash(InfinityDriveElizabeth.new(), nhash)
        answer = UniqueStringsFunctions::uniqueStringIsInAionPointObject(object, uniquestring)
        XCache::set("4cd81dd8-822b-4ec7-8065-728e2dfe2a8a:#{nhash}:#{uniquestring}", JSON.generate([answer]))
        answer
    end

    # UniqueStringsFunctions::findAndAccessUniqueString(uniquestring)
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
        Librarian20LocalObjectsStore::objects().each{|item|
            Utils::putsOnPreviousLine("looking into #{item["uuid"]}")
            next if item["iam"].nil?
            next if item["iam"]["type"] != "aion-point"
            rootnhash = item["iam"]["rootnhash"]
            if UniqueStringsFunctions::uniqueStringIsInNhash(rootnhash, uniquestring) then
                LxAction::action("landing", item)
                return
            end
        }

        puts "I could not find the unique string inside aion-points"
        LucilleCore::pressEnterToContinue()
    end
end

=begin

The Edition Desk replaces the original Nx111 export on the desktop, but notably allows for better editions of text elements
(without the synchronicity currently required by text edit)

Conventions:

Each item is exported at a location with a basename of the form <description>|itemuuid|nx111uuid<optional dotted extension>

The type (file versus folder) of the location as well as the structure of the folder are nx111 type dependent.

=end

class EditionDesk

    # ----------------------------------------------------
    # Utils

    # EditionDesk::pathToEditionDesk()
    def self.pathToEditionDesk()
        "#{Config::pathToLocalDidact()}/EditionDesk"
    end

    # EditionDesk::getMaxIndex()
    def self.getMaxIndex()
        locations = LucilleCore::locationsAtFolder(EditionDesk::pathToEditionDesk())
        return 1 if locations.empty?
        locations
            .map{|location| File.basename(location).split("|").first.to_i }
            .max
    end

    # EditionDesk::decideEditionLocation(item)
    def self.decideEditionLocation(item)
        # This function returns the location if there already is one, or otherwise returns a new one.

        

        index1 = EditionDesk::getMaxIndex() + 1
        description = item["description"] ? Utils::sanitiseStringForFilenaming(item["description"]).gsub("|", "-") : item["uuid"]
        itemuuid = item["uuid"]
        nx111uuid = item["iam"]["uuid"]

        part3and4 = "#{itemuuid}|#{nx111uuid}"
        LucilleCore::locationsAtFolder(EditionDesk::pathToEditionDesk())
            .each{|location|
                if File.basename(location).include?(part3and4) then
                    return location
                end
            }

        name1 = "#{index1.to_s.rjust(6, "0")}|#{description}|#{part3and4}"

        "#{EditionDesk::pathToEditionDesk()}/#{name1}"
    end

    # ----------------------------------------------------
    # Read and Write, the basics.

    # EditionDesk::exportItemToDeskIfNotAlreadyExportedAndAccess(item)
    def self.exportItemToDeskIfNotAlreadyExportedAndAccess(item)
        if item["iam"].nil? then
            puts "For the moment I can only EditionDesk::exportAndAccess iam's nx111 elements"
        end
        nx111 = item["iam"]
        if nx111["type"] == "navigation" then
            puts "This is a navigation node"
            LucilleCore::pressEnterToContinue()
            return
        end
        if nx111["type"] == "log" then
            puts "This is a log"
            LucilleCore::pressEnterToContinue()
            return
        end
        if nx111["type"] == "description-only" then
            puts "This is a description-only"
            LucilleCore::pressEnterToContinue()
            return
        end
        if nx111["type"] == "text" then
            location = "#{EditionDesk::decideEditionLocation(item)}.txt"
            if File.exists?(location) then
                system("open '#{location}'")
                return
            end
            nhash = nx111["nhash"]
            text = EnergyGridDatablobs::getBlobOrNull(nhash)
            File.open(location, "w"){|f| f.puts(text) }
            system("open '#{location}'")
            return
        end
        if nx111["type"] == "url" then
            url = nx111["url"]
            puts "url: #{url}"
            Librarian0Utils::openUrlUsingSafari(url)
            return
        end
        if nx111["type"] == "aion-point" then
            operator = EnergyGridElizabeth.new() 
            rootnhash = nx111["rootnhash"]
            exportLocation = EditionDesk::decideEditionLocation(item)
            rootnhash = AionTransforms::rewriteThisAionRootWithNewTopNameRespectDottedExtensionIfTheresOne(operator, rootnhash, File.basename(exportLocation))
            # At this point, the top name of the roothash may not necessarily equal the export location basename if the aion root was a file with a dotted extension
            # So we need to update the export location by substituting the old extension-less basename with the one that actually is going to be used during the aion export
            actuallocationbasename = AionTransforms::extractTopName(operator, rootnhash)
            exportLocation = "#{File.dirname(exportLocation)}/#{actuallocationbasename}"
            if File.exists?(exportLocation) then
                system("open '#{exportLocation}'")
                return
            end
            AionCore::exportHashAtFolder(operator, rootnhash, EditionDesk::pathToEditionDesk())
            puts "Item exported at #{exportLocation}"
            system("open '#{exportLocation}'")
            return
        end
        if nx111["type"] == "unique-string" then
            uniquestring = nx111["uniquestring"]
            UniqueStringsFunctions::findAndAccessUniqueString(uniquestring)
            return
        end
        if nx111["type"] == "primitive-file" then
            filepath = PrimitiveFiles::writePrimitiveFileAtEditionDeskReturnFilepath(item, nx111)
            system("open '#{filepath}'")
            return
        end
        if nx111["type"] == "carrier-of-primitive-files" then
            exportFolderpath = EditionDesk::decideEditionLocation(item)
            if File.exists?(exportFolderpath) then
                system("open '#{exportFolderpath}'")
                return
            end
            FileUtils.mkdir(exportFolderpath)
            Carriers::getCarrierContents(item["uuid"])
                .each{|ix|
                    dottedExtension = ix["iam"]["dottedExtension"]
                    nhash = ix["iam"]["nhash"]
                    parts = ix["iam"]["parts"]
                    PrimitiveFiles::exportPrimitiveFileAtFolderSimpleCase(exportFolderpath, ix["uuid"], dottedExtension, parts)
                }
            system("open '#{exportFolderpath}'")
            return
        end
        if nx111["type"] == "Dx8Unit" then

            accessDx8UnitFolderLocation = lambda {|location|
                InfinityDriveUtils::ensureInfinityDrive()
                system("open '#{location}'")
                LucilleCore::pressEnterToContinue()
                if LucilleCore::askQuestionAnswerAsBoolean("Destroy Dx8Unit folder ? ") then
                    LucilleCore::removeFileSystemLocation(location)
                end
            }

            unitId = nx111["unitId"]
            location = Dx8UnitsUtils::dx8UnitFolder(unitId)
            puts "location: #{location}"
            if File.exists?(Dx8UnitsUtils::infinityRepository()) then
                accessDx8UnitFolderLocation.call(location)
            else
                if LucilleCore::askQuestionAnswerAsBoolean("Infinity drive is not connected, want to access ? ") then
                    accessDx8UnitFolderLocation.call(location)
                else
                    puts "Ok, not accessing the file."
                end
            end
            return
        end
        raise "(error: a32e7164-1c42-4ad9-b4d7-52dc935b53e1): #{item}"
    end

    # EditionDesk::updateItemFromDeskLocationOrNothing(location)
    def self.updateItemFromDeskLocationOrNothing(location)
        filename = File.basename(location)
        inedx1, description, itemuuid, nx111uuid = filename.split("|")
        if nx111uuid.include?(".") then
            nx111uuid, _ = nx111uuid.split(".")
        end
        item = Librarian20LocalObjectsStore::getObjectByUUIDOrNull(itemuuid)
        return if item.nil?
        nx111 = item["iam"]
        return if nx111.nil?
        return if nx111["uuid"] != nx111uuid
        # At this time we have the item and the item has a nx111 that has the same uuid as the location on disk

        #puts "EditionDesk: Updating #{File.basename(location)}"

        if nx111["type"] == "navigation" then
            puts "This should not happen because nothing was exported."
            raise "(error: 81a685a2-ef9f-4ba3-9559-08905e718a3d)"
        end
        if nx111["type"] == "log" then
            puts "This should not happen because nothing was exported."
            raise "(error: 6750eb47-2227-4755-a7b1-8eda4c4d5d18)"
        end
        if nx111["type"] == "description-only" then
            puts "This should not happen because nothing was exported."
            raise "(error: 10930cec-07b5-451d-a648-85f72899ee73)"
        end
        if nx111["type"] == "text" then
            text = IO.read(location)
            nhash = EnergyGridDatablobs::putBlob(text)
            return if nx111["nhash"] == nhash
            nx111["nhash"] = nhash
            puts JSON.pretty_generate(nx111)
            item["iam"] = nx111
            Librarian20LocalObjectsStore::commit(item)
            return
        end
        if nx111["type"] == "url" then
            puts "This should not happen because nothing was exported."
            raise "(error: 563d3ad6-7d82-485b-afc5-b9aeba6fb88b)"
        end
        if nx111["type"] == "aion-point" then
            operator = EnergyGridElizabeth.new()
            rootnhash = AionCore::commitLocationReturnHash(operator, location)
            rootnhash = AionTransforms::rewriteThisAionRootWithNewTopNameRespectDottedExtensionIfTheresOne(operator, rootnhash, Utils::sanitiseStringForFilenaming(item["description"]))
            return if nx111["rootnhash"] == rootnhash
            nx111["rootnhash"] = rootnhash
            #puts JSON.pretty_generate(nx111)
            item["iam"] = nx111
            Librarian20LocalObjectsStore::commit(item)
            return
        end
        if nx111["type"] == "unique-string" then
            puts "This should not happen because nothing was exported."
            raise "(error: 00aa930f-eedc-4a95-bb0d-fecc3387ae03)"
            return
        end
        if nx111["type"] == "primitive-file" then
            nx111v2 = PrimitiveFiles::locationToPrimitiveFileNx111OrNull(nx111["uuid"], location)
            return if nx111v2.nil?
            #puts JSON.pretty_generate(nx111v2)
            return if item["iam"].to_s = nx111v2.to_s
            item["iam"] = nx111v2
            Librarian20LocalObjectsStore::commit(item)
            return
        end
        if nx111["type"] == "carrier-of-primitive-files" then

            innerLocations = LucilleCore::locationsAtFolder(location)
            # We make a fiirst pass to ensure everything is a file
            status = innerLocations.all?{|loc| File.file?(loc) }
            if !status then
                puts "The folder (#{location}) has elements that are not files!"
                LucilleCore::pressEnterToContinue()
                return
            end
            innerLocations.each{|innerFilepath|

                # So..... unlike a regular upload, some of the files in there can already be existing 
                # primitive files that were exported.

                # The nice thing is that primitive files carry their own uuid as Nyx objects.
                # We can use that to know if the location is an existing primitive file and can be ignored

                id = File.basename(innerFilepath)[0, "10202204-1516-1710-9579-87e475258c29".size]
                if Librarian20LocalObjectsStore::getObjectByUUIDOrNull(id) then
                    # puts "#{File.basename(innerFilepath)} is already a node"
                    # Note that in this case we are not picking up possible modifications of the primitive files
                else
                    puts "#{File.basename(innerFilepath)} is new and needs upload"
                    primitiveFileObject = Nx100s::issuePrimitiveFileFromLocationOrNull(innerFilepath)
                    #puts "Primitive file:"
                    #puts JSON.pretty_generate(primitiveFileObject)
                    #puts "Link: (owner: #{item["uuid"]}, file: #{primitiveFileObject["uuid"]})"
                    Nx60s::issueClaim(item["uuid"], primitiveFileObject["uuid"])

                    #puts "Writing #{primitiveFileObject["uuid"]}"
                    PrimitiveFiles::writePrimitiveFileAtEditionDeskCarrierFolderReturnFilepath(primitiveFileObject, File.basename(location), primitiveFileObject["iam"])

                    #puts "Removing #{innerFilepath}"
                    FileUtils.rm(innerFilepath)
                end
            }

            return
        end
        if nx111["type"] == "Dx8Unit" then
            puts "This should not happen because nothing was exported."
            raise "(error: 44dd0a3e-9c18-4936-a0fa-cf3b5ef6d19f)"
        end
        raise "(error: 69fcf4bf-347a-4e5f-91f8-3a97d6077c98): nx111: #{nx111}"
    end
end

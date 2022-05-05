
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
        object = AionCore::getAionObjectByHash(InfinityElizabethPureDrive.new(), nhash)
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
        Librarian6ObjectsLocal::objects().each{|item|
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

The type (file versus folder) of the location as well as the structure of the folder are nx11 type dependent.

=end

class EditionDesk

    # EditionDesk::pathToEditionDesk()
    def self.pathToEditionDesk()
        "#{Config::pathToLocalDidact()}/EditionDesk"
    end

    # EditionDesk::exportLocationName(item)
    def self.exportLocationName(item)
        description = item["description"].gsub("|", "-")
        itemuuid = item["uuid"]
        nx111uuid = item["iam"]["uuid"]
        "#{description}|#{itemuuid}|#{nx111uuid}"
    end

    # EditionDesk::exportLocation(item)
    def self.exportLocation(item)
        "#{EditionDesk::pathToEditionDesk()}/#{EditionDesk::exportLocationName(item)}"
    end

    # ----------------------------------------------------

    # EditionDesk::exportPrimitiveFileAtLocation(someuuid, dottedExtension, parts, location) # targetFilepath
    def self.exportPrimitiveFileAtLocation(someuuid, dottedExtension, parts, location)
        targetFilepath = "#{location}/#{someuuid}#{dottedExtension}"
        File.open(targetFilepath, "w"){|f|  
            parts.each{|nhash|
                blob = InfinityDatablobs_XCacheLookupThenDriveLookupWithLocalXCaching::getBlobOrNull(nhash)
                raise "(error: c3e18110-2d9a-42e6-9199-6f8564cf96d2)" if blob.nil?
                f.write(blob)
            }
        }
        targetFilepath
    end

    # EditionDesk::exportIfNotAlreadyExportedAndAccess(item)
    def self.exportIfNotAlreadyExportedAndAccess(item)
        if item["iam"].nil? then
            puts "For the moment I can only EditionDesk::exportAndAccess iam's nx111 elements "
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
            location = "#{EditionDesk::exportLocation(item)}.txt"
            if File.exists?(location) then
                system("open '#{location}'")
                return
            end
            nhash = nx111["nhash"]
            text = InfinityDatablobs_XCacheLookupThenDriveLookupWithLocalXCaching::getBlobOrNull(nhash)
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
            operator = InfinityElizabeth_XCacheLookupThenDriveLookupWithLocalXCaching.new() 
            rootnhash = nx111["rootnhash"]
            exportLocation = EditionDesk::exportLocation(item)
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
            _, dottedExtension, nhash, parts = nx111
            filepath = EditionDesk::exportPrimitiveFileAtLocation(item["uuid"], dottedExtension, parts, EditionDesk::pathToEditionDesk())
            system("open '#{filepath}'")
            return
        end
        if nx111["type"] == "carrier-of-primitive-files" then
            exportFolderpath = EditionDesk::exportLocation(item)
            if File.exists?(exportFolderpath) then
                system("open '#{exportFolderpath}'")
                return
            end
            FileUtils.mkdir(exportFolderpath)
            Librarian17PrimitiveFilesAndCarriers::carrierContents(item["uuid"])
                .each{|ix|
                    dottedExtension = ix["iam"]["dottedExtension"]
                    nhash = ix["iam"]["nhash"]
                    parts = ix["iam"]["parts"]
                    EditionDesk::exportPrimitiveFileAtLocation(ix["uuid"], dottedExtension, parts, exportFolderpath)
                }
            system("open '#{exportFolderpath}'")
            return
        end
        if nx111["type"] == "Dx8Unit" then
            unitId = nx111["unitId"]
            location = Dx8UnitsUtils::dx8UnitFolder(unitId)
            puts "location: #{location}"
            if File.exists?(Dx8UnitsUtils::infinityRepository()) then
                system("open '#{location}'")
                LucilleCore::pressEnterToContinue()
            else
                if LucilleCore::askQuestionAnswerAsBoolean("Infinity drive is not connected, want to access ? ") then
                    InfinityDrive::ensureInfinityDrive()
                    system("open '#{location}'")
                    LucilleCore::pressEnterToContinue()
                else
                    puts "Ok, not accessing the file."
                end
            end
            return
        end
        raise "(error: 3cbb1e64-0d18-48c5-bd28-f4ba584659a3): #{item}"
    end
end

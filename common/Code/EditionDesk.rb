
# encoding: UTF-8

class AionTransforms

    # AionTransforms::extractTopName(operator, rootnhash)
    def self.extractTopName(operator, rootnhash)
        AionCore::getAionObjectByHash(operator, rootnhash)["name"]
    end

    # AionTransforms::rewriteThisAionRootWithNewTopNameRespectDottedExtensionIfThereIsOne(operator, rootnhash, name1)
    def self.rewriteThisAionRootWithNewTopNameRespectDottedExtensionIfThereIsOne(operator, rootnhash, name1)
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
        "#{Config::pathToDataBankStargate()}/EditionDesk"
    end

    # EditionDesk::getMaxIndex()
    def self.getMaxIndex()
        locations = LucilleCore::locationsAtFolder(EditionDesk::pathToEditionDesk())
        return 1 if locations.empty?
        locations
            .map{|location| File.basename(location).split("|").first.to_i }
            .max
    end

    # EditionDesk::decideEditionLocation(item, nx111)
    def self.decideEditionLocation(item, nx111)
        # This function returns the location if there already is one, or otherwise returns a new one.
        
        description = item["description"] ? CommonUtils::sanitiseStringForFilenaming(item["description"]).gsub("|", "-") : item["uuid"]

        part3and4 = "#{item["uuid"]}|#{nx111["uuid"]}"
        LucilleCore::locationsAtFolder(EditionDesk::pathToEditionDesk())
            .each{|location|
                if File.basename(location).include?(part3and4) then
                    return location
                end
            }

        index1 = EditionDesk::getMaxIndex() + 1
        name1 = "#{index1}|#{description}|#{part3and4}"

        "#{EditionDesk::pathToEditionDesk()}/#{name1}"
    end

    # ----------------------------------------------------
    # Read and Write, the basics.

    # EditionDesk::accessItemNx111Pair(item, nx111)
    def self.accessItemNx111Pair(item, nx111)
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
            puts "description only: #{item["description"].green}"
            LucilleCore::pressEnterToContinue()
            return
        end
        if nx111["type"] == "text" then
            location = "#{EditionDesk::decideEditionLocation(item, nx111)}.txt"
            if File.exists?(location) then
                system("open '#{location}'")
                return
            end
            nhash = nx111["nhash"]
            text = Fx12sElizabethV2.new(item["uuid"]).getBlobOrNull(nhash)
            File.open(location, "w"){|f| f.puts(text) }
            system("open '#{location}'")
            return
        end
        if nx111["type"] == "url" then
            url = nx111["url"]
            puts "url: #{url}"
            CommonUtils::openUrlUsingSafari(url)
            return
        end
        if nx111["type"] == "aion-point" then
            operator = Fx12sElizabethV2.new(item["uuid"]) 
            rootnhash = nx111["rootnhash"]
            exportLocation = EditionDesk::decideEditionLocation(item, nx111)
            rootnhash = AionTransforms::rewriteThisAionRootWithNewTopNameRespectDottedExtensionIfThereIsOne(operator, rootnhash, File.basename(exportLocation))
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
            exportFolderpath = EditionDesk::decideEditionLocation(item, nx111)
            if File.exists?(exportFolderpath) then
                system("open '#{exportFolderpath}'")
                return
            end
            FileUtils.mkdir(exportFolderpath)
            Carriers::getCarrierContents(item["uuid"])
                .each{|ix|
                    nx111 = ix["i1as"][0] # primitive files only have one Nx111 in their i1as
                    dottedExtension = nx111["dottedExtension"]
                    nhash = nx111["nhash"]
                    parts = nx111["parts"]
                    PrimitiveFiles::exportPrimitiveFileAtFolderSimpleCase(exportFolderpath, ix["uuid"], dottedExtension, parts)
                }
            system("open '#{exportFolderpath}'")
            return
        end
        if nx111["type"] == "Dx8Unit" then
            unitId = nx111["unitId"]
            location = Dx8UnitsUtils::dx8UnitFolder(unitId)
            puts "location: #{location}"
            if LucilleCore::locationsAtFolder(location).size == 1 and LucilleCore::locationsAtFolder(location).first[-5, 5] == ".webm" then
                location2 = LucilleCore::locationsAtFolder(location).first
                if File.basename(location2).include?("'") then
                    location3 = "#{File.dirname(location2)}/#{File.basename(location2).gsub("'", "-")}"
                    FileUtils.mv(location2, location3)
                    location2 = location3
                end
                puts "opening: #{location2}"
                system("open '#{location2}'")
                return
            end
            system("open '#{location}'")
            return
        end
        raise "(error: a32e7164-1c42-4ad9-b4d7-52dc935b53e1): #{item}"
    end

    # EditionDesk::accessItem(item)
    def self.accessItem(item)
        if item["i1as"].nil? then
            raise "(error: b7242cb5-2a6b-43ea-b217-ce972e1440b0) For the moment I can only EditionDesk::exportAndAccess nx111 elements"
        end
        nx111 = I1as::selectOneNx111OrNullAutoSelectIfOne(item["i1as"])
        return if nx111.nil?
        EditionDesk::accessItemNx111Pair(item, nx111)
    end

    # EditionDesk::updateItemFromDeskLocationOrNothing(location)
    def self.updateItemFromDeskLocationOrNothing(location)
        filename = File.basename(location)
        _, description, itemuuid, nx111uuid = filename.split("|")
        if nx111uuid.include?(".") then
            nx111uuid, _ = nx111uuid.split(".")
        end
        item = Librarian::getObjectByUUIDOrNull(itemuuid)
        return if item.nil?

        nx111 = item["i1as"].select{|nx111| nx111["uuid"] == nx111uuid }.first
        return if nx111.nil?

        nx111 = nx111.clone

        # At this time we have the item, and we have selected the nx111 that has the same uuid as the location on disk

        #puts "EditionDesk: Updating #{File.basename(location)}"

        replaceNx111 = lambda {|item, nx111|
            item["i1as"] = item["i1as"].map{|nx| 
                if nx["uuid"] == nx111["uuid"] then
                    nx111
                else
                    nx
                end
            }
            item
        }

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
            nhash = Fx12sElizabethV2.new(item["uuid"]).commitBlob(text)
            return if nx111["nhash"] == nhash
            nx111["nhash"] = nhash
            #puts JSON.pretty_generate(nx111)
            item = replaceNx111.call(item, nx111)
            Librarian::commit(item)
            return
        end
        if nx111["type"] == "url" then
            puts "This should not happen because nothing was exported."
            raise "(error: 563d3ad6-7d82-485b-afc5-b9aeba6fb88b)"
        end
        if nx111["type"] == "aion-point" then
            operator = Fx12sElizabethV2.new(item["uuid"])
            rootnhash = AionCore::commitLocationReturnHash(operator, location)
            rootnhash = AionTransforms::rewriteThisAionRootWithNewTopNameRespectDottedExtensionIfThereIsOne(operator, rootnhash, CommonUtils::sanitiseStringForFilenaming(item["description"]))
            return if nx111["rootnhash"] == rootnhash
            nx111["rootnhash"] = rootnhash
            item = replaceNx111.call(item, nx111)
            Librarian::commit(item)
            return
        end
        if nx111["type"] == "unique-string" then
            puts "This should not happen because nothing was exported."
            raise "(error: 00aa930f-eedc-4a95-bb0d-fecc3387ae03)"
            return
        end
        if nx111["type"] == "primitive-file" then
            nx111v2 = PrimitiveFiles::locationToPrimitiveFileNx111OrNull(item["uuid"], nx111["uuid"], location)
            return if nx111v2.nil?
            #puts JSON.pretty_generate(nx111v2)
            return if item["i1as"].select{|nx| nx["uuid"] == nx111["uuid"] }.first["nhash"] == nx111v2["nhash"]
            item = replaceNx111.call(item, nx111v2)
            Librarian::commit(item)
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
                if Librarian::getObjectByUUIDOrNull(id) then
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
                    PrimitiveFiles::writePrimitiveFileAtEditionDeskCarrierFolderReturnFilepath(primitiveFileObject, File.basename(location), primitiveFileObject["i1as"][0])

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

    # EditionDesk::pickUpAndGarbageCollection()
    def self.pickUpAndGarbageCollection()
        LucilleCore::locationsAtFolder("#{Config::pathToDataBankStargate()}/EditionDesk").each{|location|

            issueTx202ForLocation = lambda{|location|
                tx202 = {
                    "unixtime" => Time.new.to_f,
                    "trace"    => CommonUtils::locationTrace(location)
                }
                XCache::set("51b218b8-b69d-4f7e-b503-39b0f8abf29b:#{location}", JSON.generate(tx202))
            }

            getTx202ForLocationOrNull = lambda{|location|
                tx202 = XCache::getOrNull("51b218b8-b69d-4f7e-b503-39b0f8abf29b:#{location}")
                if tx202 then
                    return JSON.parse(tx202)
                else
                    return nil
                end
            }

            getTx202ForLocation = lambda{|location|
                tx202 = XCache::getOrNull("51b218b8-b69d-4f7e-b503-39b0f8abf29b:#{location}")
                if tx202 then
                    tx202 =  JSON.parse(tx202)
                else
                    tx202 = {
                        "unixtime" => Time.new.to_f,
                        "trace"    => CommonUtils::locationTrace(location)
                    }
                    XCache::set("51b218b8-b69d-4f7e-b503-39b0f8abf29b:#{location}", JSON.generate(tx202))
                end
                tx202
            }

            tx202 = getTx202ForLocationOrNull.call(location)

            if tx202.nil? then
                puts "Edition desk updating location: #{File.basename(location)}"
                EditionDesk::updateItemFromDeskLocationOrNothing(location)
                issueTx202ForLocation.call(location)
                next
            end

            tx202 = getTx202ForLocation.call(location)

            if tx202["trace"] == CommonUtils::locationTrace(location) then # Nothing has happened at the location since the last time we checked
                if (Time.new.to_i - tx202["unixtime"]) > 86400*30 then # We keep them for 30 days
                    puts "Edition desk processing location: (removing) [please update the code]: #{File.basename(location)}"
                    #LucilleCore::removeFileSystemLocation(location)
                end
                next
            end

            puts "Edition desk updating location: #{File.basename(location)}"
            EditionDesk::updateItemFromDeskLocationOrNothing(location)

            # And we make a new one with updated unixtime and updated trace
            issueTx202ForLocation.call(location)
        }
    end
end

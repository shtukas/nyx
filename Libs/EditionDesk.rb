
# encoding: UTF-8

# nx111 items : index|description|itemuuid|nx111uuid
# collections : index|description|itemuuid|label

class EditionDesk

    # ----------------------------------------------------
    # Utils

    # EditionDesk::pathToEditionDesk()
    def self.pathToEditionDesk()
        "/Users/pascal/Desktop"
    end

    # EditionDesk::getMaxIndex(parentLocation)
    def self.getMaxIndex(parentLocation)
        locations = LucilleCore::locationsAtFolder(parentLocation)
        return 1 if locations.empty?
        locations
            .map{|location| File.basename(location).split("|").first.to_i }
            .max
    end

    # ----------------------------------------------------
    # names and locations

    # EditionDesk::decideItemNx111PairEditionLocation(parentLocation, item, nx111) [boolean, string], first element indicates whether the file was already there or not
    def self.decideItemNx111PairEditionLocation(parentLocation, item, nx111)
        # This function returns the location if there already is one, or otherwise returns a new one.
        
        part3and4 = "#{item["uuid"]}|#{nx111["uuid"]}"
        LucilleCore::locationsAtFolder(parentLocation)
            .each{|location|
                if File.basename(location).include?(part3and4) then
                    return [true, location]
                end
            }

        index1 = EditionDesk::getMaxIndex(parentLocation) + 1
        name1 = "#{index1}|#{LxFunction::function("toString", item).gsub("|","-")}|#{part3and4}"

        [false, "#{parentLocation}/#{name1}"]
    end

    # EditionDesk::decideCollectionItemEditionLocation(item, label)
    def self.decideCollectionItemEditionLocation(item, label)
        # This function returns the location if there already is one, or otherwise returns a new one.
        
        part3andLabel = "#{item["uuid"]}|#{label}"
        LucilleCore::locationsAtFolder(EditionDesk::pathToEditionDesk())
            .each{|location|
                if File.basename(location).include?(part3andLabel) then
                    return location
                end
            }

        index1 = EditionDesk::getMaxIndex(EditionDesk::pathToEditionDesk()) + 1
        name1 = "#{index1}|#{LxFunction::function("toString", item).gsub("|","-")}|#{part3andLabel}"

        "#{EditionDesk::pathToEditionDesk()}/#{name1}"
    end

    # EditionDesk::locationToItemNx111PairOrNull(location) # null or [item, nx111]
    # This function takes a location, tries and interpret the location name as a index|description|itemuuid|nx111uuid and return [item, nx111]
    def self.locationToItemNx111PairOrNull(location)
        filename = File.basename(location)

        elements = filename.split("|")

        return if elements.size != 4

        _, description, itemuuid, nx111uuidOnDisk = elements

        if nx111uuidOnDisk.include?(".") then
            nx111uuidOnDisk, _ = nx111uuidOnDisk.split(".")
        end

        item = Librarian::getObjectByUUIDOrNullEnforceUnique(itemuuid)

        return nil if item.nil?
        return nil if item["nx111"].nil?

        nx111 = item["nx111"].clone

        # The below happens when the nx111 has been manually updated (created a new one) 
        # after the previous edition desk export. In which case we ignore the one 
        # on disk since it's not relevant anymore.
        return nil if nx111["uuid"] != nx111uuidOnDisk 

        [item, nx111]
    end

    # ----------------------------------------------------
    # Nx111 carriers (access)

    # EditionDesk::getLocationOrAccessItemNx111Pair(parentLocation, item, nx111) # location or nil
    def self.getLocationOrAccessItemNx111Pair(parentLocation, item, nx111)
        return nil if nx111.nil?
        if nx111["type"] == "text" then
            # In this case we are not using the flag, in fact the check was already there when the flag was introduced and we left it like that
            flag, location = EditionDesk::decideItemNx111PairEditionLocation(parentLocation, item, nx111)
            if flag then
                return location
            end
            location = "#{location}.txt"
            nhash = nx111["nhash"]
            text = EnergyGridUniqueBlobs::getBlobOrNull(nhash)
            File.open(location, "w"){|f| f.puts(text) }
            return location
        end
        if nx111["type"] == "url" then
            url = nx111["url"]
            puts "url: #{url}"
            CommonUtils::openUrlUsingSafari(url)
            return
        end
        if nx111["type"] == "file" then
            flag, location = EditionDesk::decideItemNx111PairEditionLocation(parentLocation, item, nx111)
            return location if flag

            dottedExtension = nx111["dottedExtension"]
            nhash = nx111["nhash"]
            parts = nx111["parts"]
            
            dataIslandFilepath = PrimitiveFiles::decideFilepathForPrimitiveFileDataIsland(parts)
            if !File.exists(dataIslandFilepath) then
                puts "I could not find a data island for nhash: #{nhash}. Edition aborted."
                LucilleCore::pressEnterToContinue()
                return
            end
            dataIsland = EnergyGridImmutableDataIsland.new(dataIslandFilepath)

            filepath = flag ? location : "#{location}#{dottedExtension}"
            File.open(filepath, "w"){|f|
                parts.each{|nhash|
                    blob = dataIsland.getBlobOrNull(nhash)
                    raise "(error: a614a728-fb28-455f-9430-43aab78ea35f)" if blob.nil?
                    f.write(blob)
                }
            }
            return filepath
        end
        if nx111["type"] == "aion-point" then
            rootnhash = nx111["rootnhash"]
            operator = EnergyGridImmutableDataIsland.new()

            flag, exportLocation = EditionDesk::decideItemNx111PairEditionLocation(parentLocation, item, nx111) # can come with an extension
            rootnhash = AionTransforms::rewriteThisAionRootWithNewTopName(operator, rootnhash, File.basename(exportLocation))
            # At this point, the top name of the roothash may not necessarily equal the export location basename if the aion root was a file with a dotted extension
            # So we need to update the export location by substituting the old extension-less basename with the one that actually is going to be used during the aion export
            actuallocationbasename = AionTransforms::extractTopName(operator, rootnhash)
            exportLocation = "#{File.dirname(exportLocation)}/#{actuallocationbasename}"
            if File.exists?(exportLocation) then
                return exportLocation
            end
            AionCore::exportHashAtFolder(operator, rootnhash, parentLocation)
            puts "Item exported at #{exportLocation}"
            return exportLocation
        end
        if nx111["type"] == "unique-string" then
            uniquestring = nx111["uniquestring"]
            UniqueStringsFunctions::findAndAccessUniqueString(uniquestring)
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
                location = location2
            end
            return location
        end
        raise "(error: a32e7164-1c42-4ad9-b4d7-52dc935b53e1): #{item}"
    end

    # EditionDesk::accessItemNx111Pair(parentLocation, item, nx111)
    def self.accessItemNx111Pair(parentLocation, item, nx111)
        return if nx111.nil?
        location = EditionDesk::getLocationOrAccessItemNx111Pair(parentLocation, item, nx111)
        return if location.nil? # something wasn't right or it was a url that is already open
        system("open '#{location}'")

        # (comment group: f3bfa5db-2000-488d-90a5-1770c63a34f9)
        # Because we want to keep the items after the last access instead of after the last modification
        # we reset the Tx202 now
        XCache::destroy("51b218b8-b69d-4f7e-b503-39b0f8abf29b:#{location}")
    end

    # ----------------------------------------------------
    # Nx111 carriers (pickup)

    # EditionDesk::locationToAttemptedNx111Update(location)
    def self.locationToAttemptedNx111Update(location)
        
        elements = EditionDesk::locationToItemNx111PairOrNull(location)

        return if elements.nil?

        item, nx111 = elements

        # puts "EditionDesk: Updating #{File.basename(location)}"

        if nx111["type"] == "text" then
            text = IO.read(location)
            nhash = EnergyGridUniqueBlobs::putBlob(text)
            return if nx111["nhash"] == nhash
            nx111["nhash"] = nhash
            item["nx111"] = nx111
            Librarian::commit(item)
            return
        end
        if nx111["type"] == "url" then
            puts "This should not happen because nothing was exported."
            raise "(error: 563d3ad6-7d82-485b-afc5-b9aeba6fb88b)"
        end
        if nx111["type"] == "file" then
            # Let's compute the hash of the file and see if something has changed
            filehash = CommonUtils::filepathToContentHash(location)
            return if nx111["nhash"] == filehash
            data = PrimitiveFiles::locationToPrimitiveFileDataArrayOrNull(location) # [dottedExtension, nhash, parts]
            raise "(error: 79A50CC2-CDA1-4BCA-B11E-F7AC1A54E0F3)" if data.nil?
            dottedExtension, nhash, parts = data
            return if nhash == nx111["nhash"]
            nx111["dottedExtension"] = dottedExtension
            nx111["nhash"] = nhash
            nx111["parts"] = parts
            item["nx111"] = nx111
            Librarian::commit(item)
            return
        end
        if nx111["type"] == "aion-point" then
            dataIsland = EnergyGridImmutableDataIslandsOperator::getIslandForNhash(nx111["rootnhash"])
            rootnhash = AionCore::commitLocationReturnHash(dataIsland, location)
            rootnhash = AionTransforms::rewriteThisAionRootWithNewTopName(dataIsland, rootnhash, CommonUtils::sanitiseStringForFilenaming(item["description"]))
            return if nx111["rootnhash"] == rootnhash
            nx111["rootnhash"] = rootnhash
            item["nx111"] = nx111
            Librarian::commit(item)
            return
        end
        if nx111["type"] == "unique-string" then
            puts "This should not happen because nothing was exported."
            raise "(error: 00aa930f-eedc-4a95-bb0d-fecc3387ae03)"
            return
        end
        if nx111["type"] == "Dx8Unit" then
            puts "This should not happen because nothing was exported."
            raise "(error: 44dd0a3e-9c18-4936-a0fa-cf3b5ef6d19f)"
        end
        raise "(error: 69fcf4bf-347a-4e5f-91f8-3a97d6077c98): nx111: #{nx111}"
    end

    # ----------------------------------------------------
    # Collections (access)

    # EditionDesk::accessCollectionItemItemsPair(collectionitem, items, label)
    def self.accessCollectionItemItemsPair(collectionitem, items, label)
        # The logic here is dirrerent. We create a directory for the collection and put the children inside
        parentLocation = EditionDesk::decideCollectionItemEditionLocation(collectionitem, label)
        if !File.exists?(parentLocation) then
            FileUtils.mkdir(parentLocation)
        end
        puts "I am going to write the Iam::implementsNx111(collectionitem) children here: #{parentLocation}"
        puts "This is a read only export (!)"
        items
            .select{|ix| Iam::implementsNx111(ix) }
            .each{|ix|
                next if ix["type"] == "url"
                EditionDesk::getLocationOrAccessItemNx111Pair(parentLocation, ix, ix["nx111"])
            }
        system("open '#{parentLocation}'")

        # (comment group: f3bfa5db-2000-488d-90a5-1770c63a34f9)
        # Because we want to keep the items after the last access instead of after the last modification
        # we reset the Tx202 now
        XCache::destroy("51b218b8-b69d-4f7e-b503-39b0f8abf29b:#{parentLocation}")
    end

    # ----------------------------------------------------
    # Operations

    # EditionDesk::batchPickUpAndGarbageCollection_v1()
    # This function dates from the time the edition desk was in DataBank and we were using 
    # Tx202 to manage it. On 26th June 2022 we moved the edition desk to be the Desktop 
    # and we no longer need to use automatic management
    def self.batchPickUpAndGarbageCollection_v1()
        LucilleCore::locationsAtFolder(EditionDesk::pathToEditionDesk()).each{|location|

            issueTx202ForLocation = lambda{|location|
                tx202 = {
                    "unixtime" => Time.new.to_f,
                    "trace"    => CommonUtils::locationTrace(location)
                }
                XCache::set("51b218b8-b69d-4f7e-b503-39b0f8abf29b:#{location}", JSON.generate(tx202))
                tx202
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
                tx202 = getTx202ForLocationOrNull.call(location)
                return tx202 if tx202
                issueTx202ForLocation.call(location)
            }

            tx202 = getTx202ForLocationOrNull.call(location)

            if tx202.nil? then
                puts "Edition desk updating location: #{File.basename(location)}"
                EditionDesk::locationToAttemptedNx111Update(location)
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
            EditionDesk::locationToAttemptedNx111Update(location)

            # And we make a new one with updated unixtime and updated trace
            # Issuing a new one is a cheap way to update the unixtime
            issueTx202ForLocation.call(location)
        }
    end

    # EditionDesk::batchPickUp_v2()
    def self.batchPickUp_v2()
        LucilleCore::locationsAtFolder(EditionDesk::pathToEditionDesk()).each{|location|
            next if EditionDesk::locationToItemNx111PairOrNull(location).nil?
            puts "Edition desk updating location: #{File.basename(location)}"
            EditionDesk::locationToAttemptedNx111Update(location)
        }
    end
end

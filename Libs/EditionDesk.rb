
# encoding: UTF-8

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

    # EditionDesk::getMaxIndex(parentLocation)
    def self.getMaxIndex(parentLocation)
        locations = LucilleCore::locationsAtFolder(parentLocation)
        return 1 if locations.empty?
        locations
            .map{|location| File.basename(location).split("|").first.to_i }
            .max
    end

    # ----------------------------------------------------
    # Nx111 carriers (utils)

    # EditionDesk::decideItemNx111PairEditionLocation(parentLocation, item, nx111) [boolean, string], first element indicates whether the file was already there or not
    def self.decideItemNx111PairEditionLocation(parentLocation, item, nx111)
        # This function returns the location if there already is one, or otherwise returns a new one.
        
        part2and3 = "#{item["uuid"]}|#{nx111["uuid"]}"
        LucilleCore::locationsAtFolder(parentLocation)
            .each{|location|
                if File.basename(location).include?(part2and3) then
                    return [true, location]
                end
            }

        index1 = EditionDesk::getMaxIndex(parentLocation) + 1
        name1 = "#{index1}|#{part2and3}"

        [false, "#{parentLocation}/#{name1}"]
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
            text = EnergyGridElizabeth.new().getBlobOrNull(nhash)
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
            parts = nx111["parts"]
            filepath = flag ? location : "#{location}#{dottedExtension}"
            File.open(filepath, "w"){|f|
                parts.each{|nhash|
                    blob = EnergyGridElizabeth.new().getBlobOrNull(nhash)
                    raise "(error: a614a728-fb28-455f-9430-43aab78ea35f)" if blob.nil?
                    f.write(blob)
                }
            }
            return filepath
        end
        if nx111["type"] == "aion-point" then
            operator = EnergyGridElizabeth.new() 
            rootnhash = nx111["rootnhash"]
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
    end

    # ----------------------------------------------------
    # Nx111 carriers (pickup)

    # EditionDesk::locationToItemNx111PairOrNull(location) # null or [item, nx111]
    # This function takes a location, tries and interpret the location name as a (index, itemuuid, nx111uuid) and return [item, nx111]
    def self.locationToItemNx111PairOrNull(location)
        filename = File.basename(location)

        elements = filename.split("|")

        return if elements.size != 3

        _, itemuuid, nx111uuidOnDisk = elements

        if nx111uuidOnDisk.include?(".") then
            nx111uuidOnDisk, _ = nx111uuidOnDisk.split(".")
        end

        item = Librarian::getObjectByUUIDOrNull(itemuuid)

        return nil if item.nil?
        return nil if item["nx111"].nil?

        nx111 = item["nx111"].clone

        # The below happens when the nx111 has been manually updated (created a new one) 
        # after the previous edition desk export. In which case we ignore the one 
        # on disk since it's not relevant anymore.
        return nil if nx111["uuid"] != nx111uuidOnDisk 

        [item, nx111]
    end

    # EditionDesk::locationToAttemptedNx111Update(location)
    def self.locationToAttemptedNx111Update(location)
        
        elements = EditionDesk::locationToItemNx111PairOrNull(location)
        return if elements.nil?

        item, nx111 = elements

        # puts "EditionDesk: Updating #{File.basename(location)}"

        if nx111["type"] == "text" then
            text = IO.read(location)
            nhash = EnergyGridElizabeth.new().commitBlob(text)
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
            nx111["dottedExtension"] = dottedExtension
            nx111["nhash"] = nhash
            nx111["parts"] = parts
            item["nx111"] = nx111
            Librarian::commit(item)
            return
        end
        if nx111["type"] == "aion-point" then
            operator = EnergyGridElizabeth.new()
            rootnhash = AionCore::commitLocationReturnHash(operator, location)
            rootnhash = AionTransforms::rewriteThisAionRootWithNewTopName(operator, rootnhash, CommonUtils::sanitiseStringForFilenaming(item["description"]))
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
    # Collections (utils)

    # EditionDesk::decideCollectionItemEditionLocation(item, label)
    def self.decideCollectionItemEditionLocation(item, label)
        # This function returns the location if there already is one, or otherwise returns a new one.
        
        part2andLabel = "#{item["uuid"]}|#{label}"
        LucilleCore::locationsAtFolder(EditionDesk::pathToEditionDesk())
            .each{|location|
                if File.basename(location).include?(part2andLabel) then
                    return location
                end
            }

        index1 = EditionDesk::getMaxIndex(EditionDesk::pathToEditionDesk()) + 1
        name1 = "#{index1}|#{part2andLabel}"

        "#{EditionDesk::pathToEditionDesk()}/#{name1}"
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
    end

    # ----------------------------------------------------
    # Operations

    # EditionDesk::batchPickUpAndGarbageCollection()
    def self.batchPickUpAndGarbageCollection()
        LucilleCore::locationsAtFolder("#{Config::pathToDataBankStargate()}/EditionDesk").each{|location|

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
end


class AsteroidsUtils

    # AsteroidsUtils::editTextSynchronously(text)
    def self.editTextSynchronously(text)
        filename = SecureRandom.uuid
        filepath = "/tmp/#{filename}"
        File.open(filepath, 'w') {|f| f.write(text)}
        system("open '#{filepath}'")
        print "> press enter when done: "
        input = STDIN.gets
        IO.read(filepath)
    end

    # AsteroidsUtils::openUrl(url)
    def self.openUrl(url)
        system("open -a Safari '#{url}'")
    end
end

class AsteroidsBlobsPoints

    # AsteroidsBlobsPoints::pathToDataLake()
    def self.pathToDataLake()
        "/Users/pascal/Galaxy/DataBank/Catalyst/Asteroids-Field"
    end

    # AsteroidsBlobsPoints::uuidToAsteroidFilepath(uuid)
    def self.uuidToAsteroidFilepath(uuid)
        "#{AsteroidsBlobsPoints::pathToDataLake()}/#{uuid}.sqlite3"
    end

    # AsteroidsBlobsPoints::prepareDatabaseIfNotExists(uuid)
    def self.prepareDatabaseIfNotExists(uuid)
        filepath = AsteroidsBlobsPoints::uuidToAsteroidFilepath(uuid)
        return if File.exists?(filepath)
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117  
        db.busy_handler { |count| true }
        db.execute "create table _data_ (_key_ string, _value_ blob)", []
        db.close
    end

    # AsteroidsBlobsPoints::set(uuid, key, value)
    def self.set(uuid, key, value)
        AsteroidsBlobsPoints::prepareDatabaseIfNotExists(uuid)
        db = SQLite3::Database.new(AsteroidsBlobsPoints::uuidToAsteroidFilepath(uuid))
        db.busy_timeout = 117  
        db.busy_handler { |count| true }
        db.transaction 
        db.execute "delete from _data_ where _key_=?", [key]
        db.execute "insert into _data_ (_key_, _value_) values (?,?)", [key, value]
        db.commit 
        db.close
    end

    # AsteroidsBlobsPoints::getOrNull(uuid, key)
    def self.getOrNull(uuid, key)
        AsteroidsBlobsPoints::prepareDatabaseIfNotExists(uuid)
        db = SQLite3::Database.new(AsteroidsBlobsPoints::uuidToAsteroidFilepath(uuid))
        db.busy_timeout = 117  
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = nil
        db.execute("select * from _data_ where _key_=?", [key]) do |row|
            answer = row['_value_']
        end
        db.close
        answer
    end

    # AsteroidsBlobsPoints::destroyPoint(uuid)
    def self.destroyPoint(uuid)
        LucilleCore::locationsAtFolder(AsteroidsBlobsPoints::pathToDataLake())
        .select{|location|
            (File.basename(location) == "#{uuid}.sqlite3") or File.basename(location).start_with?("#{uuid}-SHA256-")
        }
        .each{|location|
            puts "Delete data file: #{location}"
            FileUtils.rm(location)
        }
    end
end

class AsteroidsBinaryBlobsService

    # AsteroidsBinaryBlobsService::filepathToContentHash(filepath)
    def self.filepathToContentHash(filepath)
        "SHA256-#{Digest::SHA256.file(filepath).hexdigest}"
    end

    # AsteroidsBinaryBlobsService::putBlob(uuid, blob)
    def self.putBlob(uuid, blob)
        nhash = "SHA256-#{Digest::SHA256.hexdigest(blob)}"
        AsteroidsBlobsPoints::set(uuid, nhash, blob)
        nhash
    end

    # AsteroidsBinaryBlobsService::getBlobOrNull(uuid, nhash)
    def self.getBlobOrNull(uuid, nhash)

        blob = AsteroidsBlobsPoints::getOrNull(uuid, nhash)
        return blob if blob

        # When I did the original data migration, some blobs endded up in Asteroids-TheBigBlobs. Don't ask why...
        # (Actually, they were too big for sqlite, and the existence of those big blogs in the first place is because
        # "ClickableType" data exist in one big blob 🙄)

        filepath = "/Users/pascal/Galaxy/DataBank/Catalyst/Asteroids-TheLargeMigrationBlobs/#{uuid}-#{nhash}.data"
        return IO.read(filepath) if File.exists?(filepath)

        nil
    end
end

class AsteroidElizabeth

    def initialize(uuid)
        @uuid = uuid
    end

    def commitBlob(blob)
        AsteroidsBinaryBlobsService::putBlob(@uuid, blob)
    end

    def filepathToContentHash(filepath)
        AsteroidsBinaryBlobsService::filepathToContentHash(filepath)
    end

    def readBlobErrorIfNotFound(nhash)
        blob = AsteroidsBinaryBlobsService::getBlobOrNull(@uuid, nhash)
        raise "[AsteroidElizabeth error: 2400b1c6-42ff-49d0-b37c-fbd37f179e01]" if blob.nil?
        blob
    end

    def datablobCheck(nhash)
        begin
            readBlobErrorIfNotFound(nhash)
            true
        rescue
            false
        end
    end
end

class AsteroidDatabase
    # AsteroidDatabase::databaseFilepath()
    def self.databaseFilepath()
        "/Users/pascal/Galaxy/DataBank/Catalyst/Asteroids.sqlite3"
    end

    # AsteroidDatabase::commitAsteroidComponents(uuid, unixtime, description, type, payload)
    def self.commitAsteroidComponents(uuid, unixtime, description, type, payload)
        db = SQLite3::Database.new(AsteroidDatabase::databaseFilepath())
        db.busy_timeout = 117  
        db.busy_handler { |count| true }
        db.transaction 
        db.execute "delete from _datacarrier_ where _uuid_=?", [uuid]
        db.execute "insert into _datacarrier_ (_uuid_, _unixtime_, _description_, _type_, _payload_) values (?,?,?,?,?)", [uuid, unixtime, description, type, payload]
        db.commit 
        db.close
    end

    # AsteroidDatabase::commitAsteroid(asteroid)
    def self.commitAsteroid(asteroid)
        uuid        = asteroid["uuid"]
        unixtime    = asteroid["unixtime"]
        description = asteroid["description"]
        type        = asteroid["type"]
        payload     = asteroid["payload"]
        AsteroidDatabase::commitAsteroidComponents(uuid, unixtime, description, type, payload)
    end

    # AsteroidDatabase::getAsteroidOrNull(uuid)
    def self.getAsteroidOrNull(uuid)
        db = SQLite3::Database.new(AsteroidDatabase::databaseFilepath())
        db.busy_timeout = 117  
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = nil
        db.execute("select * from _datacarrier_ where _uuid_=?", [uuid]) do |row|
            answer = {
                "uuid"        => row['_uuid_'], 
                "unixtime"    => row['_unixtime_'],
                "description" => row['_description_'],
                "type"        => row['_type_'],
                "payload"     => row['_payload_']
            }
        end
        db.close
        answer
    end

    # AsteroidDatabase::getAsteroids()
    def self.getAsteroids()
        db = SQLite3::Database.new(AsteroidDatabase::databaseFilepath())
        db.busy_timeout = 117  
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = []
        db.execute("select * from _datacarrier_", []) do |row|
            answer << {
                "uuid"        => row['_uuid_'], 
                "unixtime"    => row['_unixtime_'],
                "description" => row['_description_'],
                "type"        => row['_type_'],
                "payload"     => row['_payload_']
            }
        end
        db.close
        answer
    end

    # AsteroidDatabase::destroyAsteroid(uuid)
    def self.destroyAsteroid(uuid)
        puts "Delete database asteroid record uuid: #{uuid}"
        db = SQLite3::Database.new(AsteroidDatabase::databaseFilepath())
        db.busy_timeout = 117  
        db.busy_handler { |count| true }
        db.transaction 
        db.execute "delete from _datacarrier_ where _uuid_=?", [uuid]
        db.commit 
        db.close
    end
end

class AsteroidsInterface

    # AsteroidsInterface::getAsteroidOrNull(uuid)
    def self.getAsteroidOrNull(uuid)
        AsteroidDatabase::getAsteroidOrNull(uuid)
    end

    # AsteroidsInterface::getAsteroids()
    def self.getAsteroids()
        AsteroidDatabase::getAsteroids()
    end

    # AsteroidsInterface::asteroidToString(asteroid)
    def self.asteroidToString(asteroid)
        if asteroid["type"] == "Line" then
            description = asteroid["description"]
            # -------------------------------------------------
            # Correction of a mistake resulting from bad data transfer
            if (description.size % 2 == 0) and (description[0, description.size/2] == description[description.size/2, description.size]) then
                description = description[0, description.size/2]
            end
            # -------------------------------------------------
            return "[nereid] [line] #{description}"    
        end
        if asteroid["type"] == "Url" and asteroid["description"] == asteroid["payload"] then
            return "[nereid] [url] #{asteroid["payload"]}"    
        end
        if asteroid["type"] == "AionPoint" then
            return "[nereid] [#{asteroid["type"].downcase}] #{asteroid["description"]}"  
        end
        "[nereid] [#{asteroid["type"].downcase}] #{asteroid["description"]} | #{asteroid["payload"]}"
    end

    # AsteroidsInterface::asteroidUUIDToString(uuid)
    def self.asteroidUUIDToString(uuid)
        asteroid = AsteroidsInterface::getAsteroidOrNull(uuid)
        return "[could not find asteroid #{uuid}]" if asteroid.nil?
        AsteroidsInterface::asteroidToString(asteroid)
    end

    # AsteroidsInterface::commitAsteroid(asteroid)
    def self.commitAsteroid(asteroid)
        AsteroidDatabase::commitAsteroid(asteroid)
    end

    # AsteroidsInterface::issueLineAsteroid(line)
    def self.issueLineAsteroid(line)
        uuid = SecureRandom.uuid
        AsteroidDatabase::commitAsteroidComponents(uuid, Time.new.to_i, line, "Line", "")
        AsteroidDatabase::getAsteroidOrNull(uuid)
    end

    # AsteroidsInterface::issueURLAsteroid(url)
    def self.issueURLAsteroid(url)
        uuid = SecureRandom.uuid
        AsteroidDatabase::commitAsteroidComponents(uuid, Time.new.to_i, link, "Url", link)
        AsteroidDatabase::getAsteroidOrNull(uuid)
    end

    # AsteroidsInterface::issueTextAsteroid(description, text)
    def self.issueTextAsteroid(description, text)
        uuid = SecureRandom.uuid
        payload = AsteroidsBinaryBlobsService::putBlob(uuid, text)
        AsteroidDatabase::commitAsteroidComponents(uuid, Time.new.to_i, description, "Text", payload)
        AsteroidDatabase::getAsteroidOrNull(uuid)
    end

    # AsteroidsInterface::issueAionPointAsteroid(location)
    def self.issueAionPointAsteroid(location)
        uuid = SecureRandom.uuid
        payload = AionCore::commitLocationReturnHash(AsteroidElizabeth.new(uuid), location)
        AsteroidDatabase::commitAsteroidComponents(uuid, Time.new.to_i, File.basename(location), "AionPoint", payload)
        AsteroidDatabase::getAsteroidOrNull(uuid)
    end

    # AsteroidsInterface::interactivelyIssueNewAsteroidOrNull()
    def self.interactivelyIssueNewAsteroidOrNull()
        type = LucilleCore::selectEntityFromListOfEntitiesOrNull("type", ["Line", "Url", "Text", "ClickableType", "AionPoint"])
        return nil if type.nil?
        if type == "Line" then
            uuid = SecureRandom.uuid
            unixtime = Time.new.to_i
            description = LucilleCore::askQuestionAnswerAsString("description: ")
            return nil if description == ""
            payload = ""
            AsteroidDatabase::commitAsteroidComponents(uuid, unixtime, description, "Line", payload)
            return AsteroidDatabase::getAsteroidOrNull(uuid)
        end
        if type == "Url" then
            uuid = SecureRandom.uuid
            unixtime = Time.new.to_i
            url = LucilleCore::askQuestionAnswerAsString("url: ")
            return nil if url == ""
            payload = url
            description = LucilleCore::askQuestionAnswerAsString("description (optional): ")
            if description == "" then
                description = payload
            end
            AsteroidDatabase::commitAsteroidComponents(uuid, unixtime, description, "Url", payload)
            return AsteroidDatabase::getAsteroidOrNull(uuid)
        end
        if type == "Text" then
            uuid = SecureRandom.uuid
            unixtime = Time.new.to_i
            text = Utils::editTextSynchronously("")
            payload = AsteroidsBinaryBlobsService::putBlob(uuid, text)
            description = LucilleCore::askQuestionAnswerAsString("description: ")
            return nil if description == ""
            AsteroidDatabase::commitAsteroidComponents(uuid, unixtime, description, "Text", payload)
            return AsteroidDatabase::getAsteroidOrNull(uuid)
        end
        if type == "ClickableType" then
            uuid = SecureRandom.uuid
            unixtime = Time.new.to_i

            filenameOnTheDesktop = LucilleCore::askQuestionAnswerAsString("filename (on Desktop): ")
            filepath = "/Users/pascal/Desktop/#{filenameOnTheDesktop}"
            return nil if !File.exists?(filepath)

            nhash = AsteroidsBinaryBlobsService::putBlob(uuid, IO.read(filepath))
            dottedExtension = File.extname(filenameOnTheDesktop)
            payload = "#{nhash}|#{dottedExtension}"

            description = LucilleCore::askQuestionAnswerAsString("description (optional): ")
            if description == "" then
                description = payload
            end

            AsteroidDatabase::commitAsteroidComponents(uuid, unixtime, description, "ClickableType", payload)
            return AsteroidDatabase::getAsteroidOrNull(uuid)
        end
        if type == "AionPoint" then
            uuid = SecureRandom.uuid
            unixtime = Time.new.to_i

            locationNameOnTheDesktop = LucilleCore::askQuestionAnswerAsString("location name (on Desktop): ")
            location = "/Users/pascal/Desktop/#{locationNameOnTheDesktop}"
            return nil if !File.exists?(location)

            payload = AionCore::commitLocationReturnHash(AsteroidElizabeth.new(uuid), location)

            description = LucilleCore::askQuestionAnswerAsString("description (optional): ")
            if description == "" then
                description = payload
            end

            AsteroidDatabase::commitAsteroidComponents(uuid, unixtime, description, "AionPoint", payload)
            return AsteroidDatabase::getAsteroidOrNull(uuid)
        end
        nil
    end

    # AsteroidsInterface::landing(uuid)
    def self.landing(uuid)

        asteroid = AsteroidsInterface::getAsteroidOrNull(uuid)
        return if asteroid.nil?

        loop {

            return if AsteroidsInterface::getAsteroidOrNull(asteroid["uuid"]).nil? # could have been deleted in the previous loop
            asteroid = AsteroidsInterface::getAsteroidOrNull(asteroid["uuid"])      # could have been transmuted in the previous loop

            mx = LCoreMenuItemsNX1.new()

            puts AsteroidsInterface::asteroidToString(asteroid)
            puts "uuid: #{asteroid["uuid"]}".yellow

            puts ""

            mx.item("access".yellow,lambda { 
                AsteroidsInterface::access(asteroid["uuid"]) 
            })

            mx.item("set/update description".yellow, lambda {
                description = AsteroidsUtils::editTextSynchronously(asteroid["description"])
                return if description == ""
                asteroid["description"] = description
                AsteroidDatabase::commitAsteroid(asteroid)
            })

            mx.item("edit".yellow, lambda { AsteroidsInterface::edit(asteroid["uuid"]) })

            mx.item("transmute".yellow, lambda { 
                AsteroidsInterface::transmuteOrNull(asteroid["uuid"])
            })

            mx.item("json object".yellow, lambda { 
                puts JSON.pretty_generate(asteroid)
                LucilleCore::pressEnterToContinue()
            })

            mx.item("destroy".yellow, lambda { 
                if LucilleCore::askQuestionAnswerAsBoolean("Are you sure you want to destroy this asteroid ? ") then
                    AsteroidsInterface::destroyAsteroid(asteroid["uuid"])
                end
            })

            puts ""

            status = mx.promptAndRunSandbox()
            break if !status
        }
    end

    # AsteroidsInterface::access(uuid)
    def self.access(uuid)

        asteroid = AsteroidsInterface::getAsteroidOrNull(uuid)
        return if asteroid.nil?

        if asteroid["type"] == "Line" then
            puts asteroid["description"]
            LucilleCore::pressEnterToContinue()
            return
        end
        if asteroid["type"] == "Url" then
            puts "opening '#{asteroid["payload"]}'"
            AsteroidsUtils::openUrl(asteroid["payload"])
            LucilleCore::pressEnterToContinue()
            return
        end
        if asteroid["type"] == "Text" then
            puts "opening text '#{asteroid["payload"]}'"
            type = LucilleCore::selectEntityFromListOfEntitiesOrNull("type", ["read-only", "read-write"])
            return if type.nil?
            if type == "read-only" then
                text = AsteroidsBinaryBlobsService::getBlobOrNull(asteroid["uuid"], asteroid["payload"])
                filepath = "/Users/pascal/Desktop/#{asteroid["uuid"]}.txt"
                File.open(filepath, "w"){|f| f.write(text) }
                puts "I have exported the file at '#{filepath}'"
                LucilleCore::pressEnterToContinue()
            end
            if type == "read-write" then
                text = AsteroidsBinaryBlobsService::getBlobOrNull(asteroid["uuid"], asteroid["payload"])
                text = AsteroidsUtils::editTextSynchronously(text)
                asteroid["payload"] = AsteroidsBinaryBlobsService::putBlob(asteroid["uuid"], text)
                AsteroidDatabase::commitAsteroid(asteroid)
            end
            return
        end
        if asteroid["type"] == "ClickableType" then
            puts "opening file '#{asteroid["payload"]}'"
            type = LucilleCore::selectEntityFromListOfEntitiesOrNull("type", ["read-only", "read-write"])
            return if type.nil?
            if type == "read-only" then
                blobuuid, extension = asteroid["payload"].split("|")
                filepath = "/Users/pascal/Desktop/#{asteroid["uuid"]}#{extension}"
                blob = AsteroidsBinaryBlobsService::getBlobOrNull(asteroid["uuid"], blobuuid)
                File.open(filepath, "w"){|f| f.write(blob) }
                puts "I have exported the file at '#{filepath}'"
                LucilleCore::pressEnterToContinue()
            end
            if type == "read-write" then
                blobuuid, extension = asteroid["payload"].split("|")
                filepath = "/Users/pascal/Desktop/#{asteroid["uuid"]}#{extension}"
                blob = AsteroidsBinaryBlobsService::getBlobOrNull(asteroid["uuid"], blobuuid)
                File.open(filepath, "w"){|f| f.write(blob) }
                puts "I have exported the file at '#{filepath}'"
                puts "When done, you will enter the filename of the replacement"
                LucilleCore::pressEnterToContinue()
                filename = LucilleCore::askQuestionAnswerAsString("desktop filename (empty to abort): ")
                return if filename == ""
                filepath = "/Users/pascal/Desktop/#{filename}"
                return nil if !File.exists?(filepath)

                nhash = AsteroidsBinaryBlobsService::putBlob(asteroid["uuid"], IO.read(filepath))
                dottedExtension = File.extname(filename)
                payload = "#{nhash}|#{dottedExtension}"

                asteroid["payload"] = payload
                AsteroidDatabase::commitAsteroid(asteroid)
            end
            return
        end
        if asteroid["type"] == "AionPoint" then
            puts "opening aion point '#{asteroid["payload"]}'"
            type = LucilleCore::selectEntityFromListOfEntitiesOrNull("type", ["read-only", "read-write"])
            return if type.nil?
            if type == "read-only" then
                nhash = asteroid["payload"]
                targetReconstructionFolderpath = "/Users/pascal/Desktop"
                AionCore::exportHashAtFolder(AsteroidElizabeth.new(asteroid["uuid"]), nhash, targetReconstructionFolderpath)
                puts "Export completed"
                LucilleCore::pressEnterToContinue()
            end
            if type == "read-write" then
                nhash = asteroid["payload"]
                targetReconstructionFolderpath = "/Users/pascal/Desktop"
                AionCore::exportHashAtFolder(AsteroidElizabeth.new(asteroid["uuid"]), nhash, targetReconstructionFolderpath)
                puts "Export completed"
                puts "When done, you will enter the location name of the replacement"
                LucilleCore::pressEnterToContinue()
                locationname = LucilleCore::askQuestionAnswerAsString("desktop location name (empty to abort): ")
                return if locationname == ""
                location = "/Users/pascal/Desktop/#{locationname}"
                return nil if !File.exists?(location)
                payload = AionCore::commitLocationReturnHash(AsteroidElizabeth.new(asteroid["uuid"]), location)
                asteroid["payload"] = payload
                AsteroidDatabase::commitAsteroid(asteroid)
            end
            return
        end
        raise "[error: 456c8df0-efb7-4588-b30d-7884b33442b9]"
    end

    # AsteroidsInterface::accessTodoListingEdition(uuid)
    def self.accessTodoListingEdition(uuid)

        asteroid = AsteroidsInterface::getAsteroidOrNull(uuid)
        return if asteroid.nil?

        if asteroid["type"] == "Line" then
            puts asteroid["description"]
            return
        end
        if asteroid["type"] == "Url" then
            puts "opening '#{asteroid["payload"]}'"
            AsteroidsUtils::openUrl(asteroid["payload"])
            return
        end
        if asteroid["type"] == "Text" then
            puts "opening text '#{asteroid["payload"]}'"
            text = AsteroidsBinaryBlobsService::getBlobOrNull(asteroid["uuid"], asteroid["payload"])
            text = AsteroidsUtils::editTextSynchronously(text)
            asteroid["payload"] = AsteroidsBinaryBlobsService::putBlob(asteroid["uuid"], text)
            AsteroidDatabase::commitAsteroid(asteroid)
            return
        end
        if asteroid["type"] == "ClickableType" then
            puts "opening file '#{asteroid["payload"]}'"
            blobuuid, extension = asteroid["payload"].split("|")
            filepath = "/Users/pascal/Desktop/#{asteroid["uuid"]}#{extension}"
            blob = AsteroidsBinaryBlobsService::getBlobOrNull(asteroid["uuid"], blobuuid)
            File.open(filepath, "w"){|f| f.write(blob) }
            puts "I have exported the file at '#{filepath}'"
            system("open '#{filepath}'")
            return
        end
        if asteroid["type"] == "AionPoint" then
            puts "opening aion point '#{asteroid["payload"]}'"
            nhash = asteroid["payload"]
            targetReconstructionFolderpath = "/Users/pascal/Desktop"
            AionCore::exportHashAtFolder(AsteroidElizabeth.new(asteroid["uuid"]), nhash, targetReconstructionFolderpath)
            puts "Export completed"

            aionObject = AionCore::getAionObjectByHash(AsteroidElizabeth.new(asteroid["uuid"]), nhash)
            location = "/Users/pascal/Desktop/#{aionObject["name"]}"

            if location[-7, 7] == ".webloc" then
                system("open '#{location}'")
            end
            if [".png", ".pdf"].include?(location[-4, 4]) then
                system("open '#{location}'")
            end
            return
        end
        raise "[error: 456c8df0-efb7-4588-b30d-7884b33442b9]"
    end

    # AsteroidsInterface::postAccessCleanUpTodoListingEdition(uuid)
    def self.postAccessCleanUpTodoListingEdition(uuid)

        asteroid = AsteroidsInterface::getAsteroidOrNull(uuid)
        return if asteroid.nil?

        if asteroid["type"] == "Line" then
            return
        end
        if asteroid["type"] == "Url" then
            return
        end
        if asteroid["type"] == "Text" then
            return
        end
        if asteroid["type"] == "ClickableType" then
            puts "cleaning file '#{asteroid["payload"]}'"
            blobuuid, extension = asteroid["payload"].split("|")
            filepath = "/Users/pascal/Desktop/#{asteroid["uuid"]}#{extension}"
            return if !File.exists?(filepath)
            LucilleCore::removeFileSystemLocation(filepath)
            return
        end
        if asteroid["type"] == "AionPoint" then
            puts "cleaning aion point '#{asteroid["payload"]}'"
            nhash = asteroid["payload"]
            aionObject = AionCore::getAionObjectByHash(AsteroidElizabeth.new(asteroid["uuid"]), nhash)
            location = "/Users/pascal/Desktop/#{aionObject["name"]}"
            return if !File.exists?(location)
            LucilleCore::removeFileSystemLocation(location)
            return
        end
        raise "[error: 456c8df0-efb7-4588-b30d-7884b33442b9]"
    end

    # AsteroidsInterface::edit(uuid): -> new asteroid with same uuid, or null
    def self.edit(uuid)

        asteroid = AsteroidsInterface::getAsteroidOrNull(uuid)
        return if asteroid.nil?

        if asteroid["type"] == "Line" then
            line = LucilleCore::askQuestionAnswerAsString("line: ")
            return nil if line == ""
            asteroid["description"] = line
            asteroid["payload"] = ""
            AsteroidDatabase::commitAsteroid(asteroid)
            return asteroid
        end
        if asteroid["type"] == "Url" then
            url = LucilleCore::askQuestionAnswerAsString("url: ")
            if url != "" then
                asteroid["payload"] = url
            end

            description = LucilleCore::askQuestionAnswerAsString("description (empty for not changing): ")
            if description != "" then
                asteroid["description"] = description
            end        

            AsteroidDatabase::commitAsteroid(asteroid)
            return asteroid
        end
        if asteroid["type"] == "Text" then
            text = AsteroidsBinaryBlobsService::getBlobOrNull(asteroid["uuid"], asteroid["payload"])
            text = Utils::editTextSynchronously(text)
            asteroid["payload"] = AsteroidsBinaryBlobsService::putBlob(asteroid["uuid"], text)

            description = LucilleCore::askQuestionAnswerAsString("description (empty for not changing): ")
            if description != "" then
                asteroid["description"] = description
            end

            AsteroidDatabase::commitAsteroid(asteroid)
            return asteroid
        end
        if asteroid["type"] == "ClickableType" then
            filenameOnTheDesktop = LucilleCore::askQuestionAnswerAsString("filename (on Desktop): ")
            filepath = "/Users/pascal/Desktop/#{filenameOnTheDesktop}"
            if File.exists?(filepath) then
                nhash = AsteroidsBinaryBlobsService::putBlob(asteroid["uuid"], IO.read(filepath))
                dottedExtension = File.extname(filenameOnTheDesktop)
                payload = "#{nhash}|#{dottedExtension}"
                asteroid["payload"] = payload
            end

            description = LucilleCore::askQuestionAnswerAsString("description (empty for not changing): ")
            if description != "" then
                asteroid["description"] = description
            end

            AsteroidDatabase::commitAsteroid(asteroid)
            return asteroid
        end
        if asteroid["type"] == "AionPoint" then
            locationNameOnTheDesktop = LucilleCore::askQuestionAnswerAsString("location name (on Desktop): ")
            location = "/Users/pascal/Desktop/#{locationNameOnTheDesktop}"
            if File.exists?(location) then
                payload = AionCore::commitLocationReturnHash(AsteroidElizabeth.new(asteroid["uuid"]), location)
                asteroid["payload"] = payload
            end

            description = LucilleCore::askQuestionAnswerAsString("description (empty for not changing): ")
            if description != "" then
                asteroid["description"] = description
            end

            AsteroidDatabase::commitAsteroid(asteroid)
            return asteroid
        end
        raise "[error: 707CAFD7-46CF-489B-B829-5F4816C4911D]"
    end

    # AsteroidsInterface::transmuteOrNull(uuid): -> new asteroid with same uuid, or null
    def self.transmuteOrNull(uuid)

        asteroid = AsteroidsInterface::getAsteroidOrNull(uuid)
        return if asteroid.nil?

        type = LucilleCore::selectEntityFromListOfEntitiesOrNull("type", ["Line", "Url", "Text", "ClickableType", "AionPoint"])
        return nil if type.nil?
        if type == "Line" then
            asteroid["type"] = "Line"
            description = LucilleCore::askQuestionAnswerAsString("description: ")
            return nil if description == ""
            asteroid["description"] = description
            asteroid["payload"] = ""
            AsteroidDatabase::commitAsteroid(asteroid)
            return asteroid
        end
        if type == "Url" then
            asteroid["type"] = "Url"

            url = LucilleCore::askQuestionAnswerAsString("url: ")
            return nil if url == ""
            asteroid["payload"] = url

            description = LucilleCore::askQuestionAnswerAsString("description (empty for not changing): ")
            if description != "" then
                asteroid["description"] = description
            end 

            AsteroidDatabase::commitAsteroid(asteroid)
            return asteroid
        end
        if type == "Text" then
            asteroid["type"] = "Text"
            text = Utils::editTextSynchronously("")
            asteroid["payload"] = AsteroidsBinaryBlobsService::putBlob(asteroid["uuid"], text)

            description = LucilleCore::askQuestionAnswerAsString("description (empty for not changing): ")
            if description != "" then
                asteroid["description"] = description
            end 

            AsteroidDatabase::commitAsteroid(asteroid)
            return asteroid
        end
        if type == "ClickableType" then
            asteroid["type"] = "ClickableType"

            filenameOnTheDesktop = LucilleCore::askQuestionAnswerAsString("filename (on Desktop): ")
            filepath = "/Users/pascal/Desktop/#{filenameOnTheDesktop}"
            return nil if !File.exists?(filepath)

            nhash = AsteroidsBinaryBlobsService::putBlob(asteroid["uuid"], IO.read(filepath))
            dottedExtension = File.extname(filenameOnTheDesktop)
            payload = "#{nhash}|#{dottedExtension}"
            asteroid["payload"] = payload

            description = LucilleCore::askQuestionAnswerAsString("description (empty for not changing): ")
            if description != "" then
                asteroid["description"] = description
            end 

            AsteroidDatabase::commitAsteroid(asteroid)
            return asteroid
        end
        if type == "AionPoint" then
            asteroid["type"] = "AionPoint"

            locationNameOnTheDesktop = LucilleCore::askQuestionAnswerAsString("location name (on Desktop): ")
            location = "/Users/pascal/Desktop/#{locationNameOnTheDesktop}"
            return nil if !File.exists?(location)

            payload = AionCore::commitLocationReturnHash(AsteroidElizabeth.new(asteroid["uuid"]), location)
            asteroid["payload"] = payload

            description = LucilleCore::askQuestionAnswerAsString("description (empty for not changing): ")
            if description != "" then
                asteroid["description"] = description
            end 

            AsteroidDatabase::commitAsteroid(asteroid)
            return asteroid
        end
    end

    # AsteroidsInterface::destroyAsteroid(uuid)
    def self.destroyAsteroid(uuid)
        AsteroidDatabase::destroyAsteroid(uuid)
        AsteroidsBlobsPoints::destroyPoint(uuid)
    end
end

class AsteroidsFsck
    # AsteroidsFsck::fsckAsteroid(asteroid)
    def self.fsckAsteroid(asteroid)
        if asteroid["type"] == "Line" then
            puts "checking #{asteroid["type"]}"
            return
        end
        if asteroid["type"] == "Url" then
            puts "checking #{asteroid["type"]}"
            return
        end  
        if asteroid["type"] == "Text" then
            blob = AsteroidsBinaryBlobsService::getBlobOrNull(asteroid["uuid"], asteroid["payload"])
            if blob.nil? then
                puts "Could not extract Text blob payload: #{asteroid["payload"]}".red
                exit
            end
            return
        end
        if asteroid["type"] == "ClickableType" then
            blob = AsteroidsBinaryBlobsService::getBlobOrNull(asteroid["uuid"], asteroid["payload"].split("|").first)
            if blob.nil? then
                puts "Could not extract ClickableType blob payload: #{asteroid["payload"]}".red
                exit
            end
            return
        end 
        if asteroid["type"] == "AionPoint" then
            puts "checking AionPoint: #{asteroid["payload"]}"
            status = AionFsck::structureCheckAionHash(AsteroidElizabeth.new(asteroid["uuid"]), asteroid["payload"])
            if !status then
                puts "Could not validate payload: #{asteroid["payload"]}".red
                exit
            end
            return
        end
        puts asteroid
        raise "cfe763bb-013b-4ae6-a611-935dca16260b"
    end

    # AsteroidsFsck::fsck()
    def self.fsck()
        AsteroidsInterface::getAsteroids()
            .each{|asteroid| AsteroidsFsck::fsckAsteroid(asteroid) }
    end
end


# encoding: UTF-8

class ElbramElizabeth

    # @filepath

    def initialize(filepath)
        @filepath = filepath
    end

    def commitBlob(blob)
        BinaryBlobsService::putBlob(blob)
    end

    def filepathToContentHash(filepath)
        "SHA256-#{Digest::SHA256.file(filepath).hexdigest}"
    end

    def readBlobErrorIfNotFound(nhash)

        blob = BinaryBlobsService::getBlobOrNull(nhash)
        return blob if blob

        # Some operations may accidentally call those functions on a marble that has died, that create an empty file
        raise "a57bb88e-d793-4b15-bb7d-3ff7d41ee3ce" if !File.exists?(@filepath)
        db = SQLite3::Database.new(@filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        blob = nil
        db.execute("select * from _data_ where _key_=?", [nhash]) do |row|
            blob = row['_value_']
        end
        db.close

        if blob then
            commitBlob(blob)
            return blob
        end

        # When I did the original data migration, some blobs endded up in Asteroids-TheBigBlobs. Don't ask why...
        # (Actually, they were too big for sqlite, and the existence of those big blogs in the first place is because
        # "ClickableType" data exist in one big blob 🙄)

        filepath = "/Users/pascal/Galaxy/DataBank/Catalyst/Elbrams-TheLargeMigrationBlobs/#{nhash}.data"
        if File.exists?(filepath) then
            blob = IO.read(filepath)
            commitBlob(blob)
            return blob
        end

        raise "[Error: 2400b1c6-42ff-49d0-b37c-fbd37f179e01, nhash: #{nhash}]"
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

class Elbram

    # @filepath

    # -----------------------------------------------------

    def initialize(filepath)
        raise "a57bb88e-d791-4b15-bb7d-3ff7d41ee3ce" if !File.exists?(filepath)
        @filepath = filepath
    end

    # -----------------------------------------------------

    def set(key, value)
        Elbrams::set(@filepath, key, value)
    end

    def getOrNull(key)
        Elbrams::getOrNull(@filepath, key)
    end

    def get(key)
        value = getOrNull(key)
        raise "error: 3cc77bfa-ab61-451d-bb0b-902540684a84: could not extract mandatory key '#{key}' at marble '#{@filepath}'" if value.nil?
        value
    end

    # -----------------------------------------------------

    def filepath()
        @filepath
    end

    def isStillAlive()
        File.exists?(@filepath)
    end

    def destroy()
        FileUtils.rm(@filepath)
    end

    # -----------------------------------------------------

    def hasNote()
        text = getOrNull("note")
        !text.nil? and text.size > 0 
    end

    def getNote()
        getOrNull("note") || ""
    end

    def editNote()
        text = getNote()
        text = Utils::editTextSynchronously(text)
        set("note", text)
    end

end

class Elbrams

    # Elbrams::set(filepath, key, value)
    def self.set(filepath, key, value)
        # Some operations may accidentally call those functions on a marble that has died, that create an empty file
        raise "f6d2b713-7fa5-44a6-afff-97c8553b325d" if !File.exists?(filepath)
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.transaction 
        db.execute "delete from _data_ where _key_=?", [key]
        db.execute "insert into _data_ (_key_, _value_) values (?,?)", [key, value]
        db.commit 
        db.close
    end

    # Elbrams::getOrNull(filepath, key)
    def self.getOrNull(filepath, key)
        # Some operations may accidentally call those functions on a marble that has died, that create an empty file
        raise "a57bb88e-d795-4b15-bb7d-3ff7d41ee3ce" if !File.exists?(filepath)
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        value = nil
        db.execute("select * from _data_ where _key_=?", [key]) do |row|
            value = row['_value_']
        end
        db.close
        value

        return value if value

        nhash = key
        f1 = "/Users/pascal/Galaxy/DataBank/Catalyst/Elbrams-TheLargeMigrationBlobs/#{nhash}.data"
        if File.exists?(f1) then
            return IO.read(f1) 
        end

        nil
    end

    # Elbrams::get(filepath, key)
    def self.get(filepath, key)
        value = Elbrams::getOrNull(filepath, key)
        raise "error: e5849f2e-d4e8-44a9-ac8a-8bcd721cc043: could not extract mandatory key '#{key}' at marble '#{filepath}'" if value.nil?
        value
    end

    # Elbrams::domains()
    def self.domains()
        ["anniversaries", "quarks"]
    end

    # Elbrams::filepaths(domain)
    def self.filepaths(domain)
        LucilleCore::locationsAtFolder("/Users/pascal/Galaxy/DataBank/Catalyst/Elbrams/#{domain}")
    end

    # Elbrams::marblesOfGivenDomainInOrder(domain)
    def self.marblesOfGivenDomainInOrder(domain)
        LucilleCore::locationsAtFolder("/Users/pascal/Galaxy/DataBank/Catalyst/Elbrams/#{domain}")
            .sort
            .map{|filepath| Elbram.new(filepath)}
    end

    # Elbrams::getFilepathByIdAtDomainOrNull(domain, id)
    def self.getFilepathByIdAtDomainOrNull(domain, id)
        Elbrams::filepaths(domain).each{|filepath|
            return filepath if (Elbrams::get(filepath, "uuid") == id)
        }
        nil
    end

    # Elbrams::issueNewEmptyElbram(filepath)
    def self.issueNewEmptyElbram(filepath)
        raise "[37d4ec0d-5562-47c1-861c-ca08078e26b0: #{filepath}]" if File.exists?(filepath)

        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.execute "create table _data_ (_key_ string, _value_ blob)", []
        db.close

        Elbram.new(filepath)
    end

    # Elbrams::access(marble)
    def self.access(marble)

        filepath = marble.filepath()

        return if !marble.isStillAlive()

        if Elbrams::get(filepath, "type") == "Line" then
            return
        end
        if Elbrams::get(filepath, "type") == "Url" then
            puts "opening '#{Elbrams::get(filepath, "payload")}'"
            Utils::openUrl(Elbrams::get(filepath, "payload"))
            return
        end
        if Elbrams::get(filepath, "type") == "Text" then
            puts "opening text '#{Elbrams::get(filepath, "payload")}' (edit mode)"
            nhash = Elbrams::get(filepath, "payload")
            text1 = ElbramElizabeth.new(filepath).readBlobErrorIfNotFound(nhash)
            text2 = Utils::editTextSynchronously(text1)
            if (text1 != text2) and LucilleCore::askQuestionAnswerAsBoolean("commit changes ? ") then
                payload = ElbramElizabeth.new(filepath).commitBlob(text2)
                Elbrams::set(filepath, "payload", payload)
            end
            return
        end
        if Elbrams::get(filepath, "type") == "ClickableType" then
            puts "opening file '#{Elbrams::get(filepath, "payload")}'"
            nhash, extension = Elbrams::get(filepath, "payload").split("|")
            filepath = "/Users/pascal/Desktop/#{nhash}#{extension}"
            blob = ElbramElizabeth.new(filepath).readBlobErrorIfNotFound(nhash)
            File.open(filepath, "w"){|f| f.write(blob) }
            puts "I have exported the file at '#{filepath}'"
            system("open '#{filepath}'")
            return
        end
        if Elbrams::get(filepath, "type") == "AionPoint" then
            puts "opening aion point '#{Elbrams::get(filepath, "payload")}'"
            nhash = Elbrams::get(filepath, "payload")
            targetReconstructionFolderpath = "/Users/pascal/Desktop"
            AionCore::exportHashAtFolder(ElbramElizabeth.new(filepath), nhash, targetReconstructionFolderpath)
            puts "Export completed"
            return
        end
        raise "[error: 456c8df0-efb7-4588-b30d-7884b33442b9]"
    end

    # Elbrams::postAccessCleanUp(marble)
    def self.postAccessCleanUp(marble)

        filepath = marble.filepath()

        return if !marble.isStillAlive()

        if Elbrams::get(filepath, "type") == "Line" then
            return
        end
        if Elbrams::get(filepath, "type") == "Url" then
            return
        end
        if Elbrams::get(filepath, "type") == "Text" then
            return
        end
        if Elbrams::get(filepath, "type") == "ClickableType" then
            puts "cleaning file '#{Elbrams::get(filepath, "payload")}'"
            nhash, extension = Elbrams::get(filepath, "payload").split("|")
            filepath = "/Users/pascal/Desktop/#{nhash}#{extension}"
            return if !File.exists?(filepath)
            LucilleCore::removeFileSystemLocation(filepath)
            return
        end
        if Elbrams::get(filepath, "type") == "AionPoint" then
            puts "cleaning aion point '#{Elbrams::get(filepath, "payload")}'"
            nhash = Elbrams::get(filepath, "payload")
            aionObject = AionCore::getAionObjectByHash(ElbramElizabeth.new(filepath), nhash)
            location = "/Users/pascal/Desktop/#{aionObject["name"]}"
            return if !File.exists?(location)
            LucilleCore::removeFileSystemLocation(location)
            return
        end
        raise "[error: 456c8df0-efb7-4588-b30d-7884b33442b9]"
    end

    # Elbrams::edit(marble)
    def self.edit(marble)

        filepath = marble.filepath()

        if Elbrams::get(filepath, "type") == "Line" then
            line = LucilleCore::askQuestionAnswerAsString("line: ")
            return nil if line == ""
            Elbrams::set(filepath, "description", line)
            Elbrams::set(filepath, "payload", "")
            return
        end
        if Elbrams::get(filepath, "type") == "Url" then
            description = LucilleCore::askQuestionAnswerAsString("description (empty for not changing): ")
            if description != "" then
                Elbrams::set(filepath, "description", description)
            end  
            url = LucilleCore::askQuestionAnswerAsString("url: ")
            if url != "" then
                Elbrams::set(filepath, "payload", url)
            end
            return
        end
        if Elbrams::get(filepath, "type") == "Text" then
            description = LucilleCore::askQuestionAnswerAsString("description (empty for not changing): ")
            if description != "" then
                Elbrams::set(filepath, "description", description)
            end
            nhash = Elbrams::get(filepath, "payload")
            text1 = ElbramElizabeth.new(filepath).readBlobErrorIfNotFound(nhash)
            text2 = Utils::editTextSynchronously(text1)
            payload = ElbramElizabeth.new(filepath).commitBlob(text2)
            Elbrams::set(filepath, "payload", payload)
            return
        end
        if Elbrams::get(filepath, "type") == "ClickableType" then
            description = LucilleCore::askQuestionAnswerAsString("description (empty for not changing): ")
            if description != "" then
                Elbrams::set(filepath, "description", description)
            end
            filenameOnTheDesktop = LucilleCore::askQuestionAnswerAsString("filename (on Desktop): ")
            f1 = "/Users/pascal/Desktop/#{filenameOnTheDesktop}"
            if File.exists?(f1) then
                nhash = ElbramElizabeth.new(filepath).commitBlob(IO.read(f1)) # bad choice, this file could be large
                dottedExtension = File.extname(filenameOnTheDesktop)
                payload = "#{nhash}|#{dottedExtension}"
                Elbrams::set(filepath, "payload", payload)
            else
                puts "Could not find file: #{f1}"
            end
            return
        end
        if Elbrams::get(filepath, "type") == "AionPoint" then
            description = LucilleCore::askQuestionAnswerAsString("description (empty for not changing): ")
            if description != "" then
                Elbrams::set(filepath, "description", description)
            end
            locationNameOnTheDesktop = LucilleCore::askQuestionAnswerAsString("location name (on Desktop): ")
            location = "/Users/pascal/Desktop/#{locationNameOnTheDesktop}"
            if File.exists?(location) then
                payload = AionCore::commitLocationReturnHash(ElbramElizabeth.new(filepath), location)
                Elbrams::set(filepath, "payload", payload)
            else
                puts "Could not find file: #{filepath}"
            end
            return
        end
        raise "[error: 707CAFD7-46CF-489B-B829-5F4816C4911D]"
    end

    # Elbrams::transmute(marble)
    def self.transmute(marble)
        puts "Elbrams::transmute(marble) is not implemented yet"
        LucilleCore::pressEnterToContinue()
    end
end

class ElbramsFsck
    # ElbramsFsck::fsckElbram(marble)
    def self.fsckElbram(marble)

        filepath = marble.filepath()

        puts "fsck: #{filepath} (#{Elbrams::get(filepath, "domain")}, #{Elbrams::get(filepath, "type")})"

        raise "[error: f88fcaad-2882-4fd6-ac1e-a85a83f761b6] ; filepath: #{filepath}" if Elbrams::get(filepath, "uuid").nil?
        raise "[error: 5ff068b9-b9fb-4826-a6ad-398d8b0709bd] ; filepath: #{filepath}" if Elbrams::get(filepath, "unixtime").nil?
        raise "[error: 6d283c5e-3c50-45ef-8c26-2e10a563fb53] ; filepath: #{filepath}" if Elbrams::get(filepath, "domain").nil?

        if !["anniversaries", "waves", "quarks"].include?(Elbrams::get(filepath, "domain")) then
            raise "[error: eacdf935-09d1-4e64-a16f-49c5de81c775] ; filepath: #{filepath}"
        end

        raise "[error: dfb12670-1391-4cb1-ba4f-0541b77aad9b] ; filepath: #{filepath}" if Elbrams::get(filepath, "description").nil?
        raise "[error: bf1662b8-b1aa-4610-ae17-9c3992a0e24d] ; filepath: #{filepath}" if Elbrams::get(filepath, "type").nil?

        if !["Line", "Url", "Text", "ClickableType", "AionPoint"].include?(Elbrams::get(filepath, "type")) then
            raise "[error: 2ca6437e-5566-41d5-8cc9-620d0623bed9] ; filepath: #{filepath}"
        end

        raise "[error: 672db530-20ca-4981-ab4b-0c7b832e205b] ; filepath: #{filepath}" if Elbrams::get(filepath, "payload").nil?

        if Elbrams::get(filepath, "domain") == "anniversaries" then
            raise "[error: 0912e41d-676b-4b54-82ec-fb45698fd902] ; filepath: #{filepath}" if marble.getOrNull("startdate").nil?
            raise "[error: 52e24a4f-6a12-4d76-ae4c-94fce3a88a87] ; filepath: #{filepath}" if marble.getOrNull("repeatType").nil?
            raise "[error: dfbe3fb4-d4a9-4e78-bb0f-4d3e00a06618] ; filepath: #{filepath}" if marble.getOrNull("lastCelebrationDate").nil?
        end

        if Elbrams::get(filepath, "domain") == "waves" then
            raise "[error: b4ea09e4-db79-416c-b3da-857305e37e46] ; filepath: #{filepath}" if marble.getOrNull("repeatType").nil?
            raise "[error: 38eec138-5ffe-44c5-a2bc-6b13c9bb4f60] ; filepath: #{filepath}" if marble.getOrNull("repeatValue").nil?
            raise "[error: fda08d22-406e-4dc4-89f7-db590b10db8c] ; filepath: #{filepath}" if marble.getOrNull("lastDoneDateTime").nil?
        end

        if Elbrams::get(filepath, "type") == "Line" then
            return
        end

        if Elbrams::get(filepath, "type") == "Url" then
            if !Elbrams::get(filepath, "payload").start_with?("http") then
                raise "[error: 4f2bab70-1ed5-476a-bd12-402355bbdb6b] ; filepath: #{filepath}"
            end
            return
        end

        if Elbrams::get(filepath, "type") == "Text" then
            if marble.getOrNull(Elbrams::get(filepath, "payload")).nil? then
                raise "[error: f220bac1-4ab1-40df-b751-7573d3adc685] ; filepath: #{filepath}"
            end
            return
        end
        if Elbrams::get(filepath, "type") == "ClickableType" then
            nhash = Elbrams::get(filepath, "payload").split("|").first
            if marble.getOrNull(nhash).nil? then
                raise "[error: c195269a-264b-4a0b-b1d8-fb0175c12cbf] ; filepath: #{filepath}"
            end
            return
        end 
        if Elbrams::get(filepath, "type") == "AionPoint" then
            nhash = Elbrams::get(filepath, "payload")
            status = AionFsck::structureCheckAionHash(ElbramElizabeth.new(filepath), nhash)
            if !status then
                raise "[error: 53BBC142-23CA-4939-9691-32F7C6FC9C65] ; filepath: #{filepath}"
            end
            return
        end
        raise "[cfe763bb-013b-4ae6-a611-935dca16260b: #{filepath}]"
    end

    # ElbramsFsck::fsck()
    def self.fsck()
        Elbrams::domains()
            .map{|domain| Elbrams::marblesOfGivenDomainInOrder(domain) }
            .flatten
            .each{|marble|
                ElbramsFsck::fsckElbram(marble)
            }
    end
end
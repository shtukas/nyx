
# encoding: UTF-8

class MarbleElizabeth

    # @filepath

    def initialize(filepath)
        @filepath = filepath
    end

    def commitBlob(blob)
        nhash = "SHA256-#{Digest::SHA256.hexdigest(blob)}"
        db = SQLite3::Database.new(@filepath)
        db.busy_timeout = 117  
        db.busy_handler { |count| true }
        db.transaction 
        db.execute "delete from _data_ where _key_=?", [nhash]
        db.execute "insert into _data_ (_key_, _value_) values (?,?)", [nhash, blob]
        db.commit 
        db.close
        nhash
    end

    def filepathToContentHash(filepath)
        "SHA256-#{Digest::SHA256.file(filepath).hexdigest}"
    end

    def readBlobErrorIfNotFound(nhash)

        db = SQLite3::Database.new(@filepath)
        db.busy_timeout = 117  
        db.busy_handler { |count| true }
        db.results_as_hash = true
        blob = nil
        db.execute("select * from _data_ where _key_=?", [nhash]) do |row|
            blob = row['_value_']
        end
        db.close
        return blob if blob

        # When I did the original data migration, some blobs endded up in Asteroids-TheBigBlobs. Don't ask why...
        # (Actually, they were too big for sqlite, and the existence of those big blogs in the first place is because
        # "ClickableType" data exist in one big blob 🙄)

        filepath = "/Users/pascal/Galaxy/DataBank/Catalyst/Marbles-TheLargeMigrationBlobs/#{nhash}.data"
        if File.exists?(filepath) then
            return IO.read(filepath) 
        end

        raise "[AsteroidElizabeth error: 2400b1c6-42ff-49d0-b37c-fbd37f179e01]"
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

class Marble

    # @filepath

    # -----------------------------------------------------

    def initialize(filepath)
        raise "a57bb88e-d791-4b15-bb7d-3ff7d41ee3ce" if !File.exists?(filepath)
        @filepath = filepath
    end

    def uuid()
        get("uuid")
    end

    def unixtime()
        get("unixtime")
    end

    def domain()
        get("domain")
    end

    def description()
        get("description")
    end

    def type()
        get("type")
    end

    def payload()
        get("payload")
    end

    # -----------------------------------------------------

    def set(key, value)
        db = SQLite3::Database.new(@filepath)
        db.busy_timeout = 117  
        db.busy_handler { |count| true }
        db.transaction 
        db.execute "delete from _data_ where _key_=?", [key]
        db.execute "insert into _data_ (_key_, _value_) values (?,?)", [key, value]
        db.commit 
        db.close
    end

    def getOrNull(key)
        db = SQLite3::Database.new(@filepath)
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
end

class Marbles

    # Marbles::marbles()
    def self.marbles()
        LucilleCore::locationsAtFolder("/Users/pascal/Galaxy/DataBank/Catalyst/Marbles").map{|filepath|
            Marble.new(filepath)
        }
    end

    # Marbles::marblesOfGivenDomain(domain)
    def self.marblesOfGivenDomain(domain)
        Marbles::marbles().select{|marble|
            marble.domain() == domain
        }
    end

    # Marbles::issueNewOrUseExistingMarble(filepath)
    def self.issueNewOrUseExistingMarble(filepath)
        if !File.exists?(filepath) then
            db = SQLite3::Database.new(filepath)
            db.busy_timeout = 117  
            db.busy_handler { |count| true }
            db.execute "create table _data_ (_key_ string, _value_ blob)", []
            db.close
        end
        Marble.new(filepath)
    end
end

class MarblesFsck
    # MarblesFsck::fsckMarble(marble)
    def self.fsckMarble(marble)

        puts "fsck: #{marble.filepath()}"

        raise "[error: f88fcaad-2882-4fd6-ac1e-a85a83f761b6] ; filepath: #{filepath}" if marble.uuid().nil?
        raise "[error: 5ff068b9-b9fb-4826-a6ad-398d8b0709bd] ; filepath: #{filepath}" if marble.unixtime().nil?
        raise "[error: 6d283c5e-3c50-45ef-8c26-2e10a563fb53] ; filepath: #{filepath}" if marble.domain().nil?

        if !["anniversaries", "calendar", "waves", "quarks"].include?(marble.domain()) then
            raise "[error: eacdf935-09d1-4e64-a16f-49c5de81c775] ; filepath: #{filepath}"
        end

        raise "[error: dfb12670-1391-4cb1-ba4f-0541b77aad9b] ; filepath: #{filepath}" if marble.description().nil?
        raise "[error: bf1662b8-b1aa-4610-ae17-9c3992a0e24d] ; filepath: #{filepath}" if marble.type().nil?

        if !["Line", "Url", "Text", "ClickableType", "AionPoint"].include?(marble.type()) then
            raise "[error: 2ca6437e-5566-41d5-8cc9-620d0623bed9] ; filepath: #{filepath}"
        end

        raise "[error: 672db530-20ca-4981-ab4b-0c7b832e205b] ; filepath: #{filepath}" if marble.payload().nil?

        if marble.domain() == "anniversaries" then
            raise "[error: 0912e41d-676b-4b54-82ec-fb45698fd902] ; filepath: #{filepath}" if marble.getOrNull("startdate").nil?
            raise "[error: 52e24a4f-6a12-4d76-ae4c-94fce3a88a87] ; filepath: #{filepath}" if marble.getOrNull("repeatType").nil?
            raise "[error: dfbe3fb4-d4a9-4e78-bb0f-4d3e00a06618] ; filepath: #{filepath}" if marble.getOrNull("lastCelebrationDate").nil?
        end

        if marble.type() == "Line" then
            return
        end

        if marble.type() == "Url" then
            if !marble.payload().start_with?("http") then
                raise "[error: 4f2bab70-1ed5-476a-bd12-402355bbdb6b] ; filepath: #{filepath}"
            end
            return
        end

        if marble.type() == "Text" then
            if marble.getOrNull(marble.payload()).nil? then
                raise "[error: f220bac1-4ab1-40df-b751-7573d3adc685] ; filepath: #{filepath}"
            end
            return
        end
        if marble.type() == "ClickableType" then
            nhash = marble.payload().split("|").first
            if marble.getOrNull(nhash).nil? then
                raise "[error: c195269a-264b-4a0b-b1d8-fb0175c12cbf] ; filepath: #{filepath}"
            end
            return
        end 
        if asteroid["type"] == "AionPoint" then
            nhash = marble.payload()
            status = AionFsck::structureCheckAionHash(MarbleElizabeth.new(marble.filepath()), nhash)
            if !status then
                puts "Could not validate payload: #{asteroid["payload"]}".red
                exit
            end
            return
        end
        raise "[cfe763bb-013b-4ae6-a611-935dca16260b: #{marble.filepath()}]"
    end

    # MarblesFsck::fsck()
    def self.fsck()
        LucilleCore::locationsAtFolder("/Users/pascal/Galaxy/DataBank/Catalyst/Marbles")
            .each{|filepath|
                marble = Marble.new(filepath)
                MarblesFsck::fsckMarble(marble)
            }
    end
end
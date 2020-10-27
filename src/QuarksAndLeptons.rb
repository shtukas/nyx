
# encoding: UTF-8

class Quark

    # Quark::quarks()
    def self.quarks()
        NyxObjects2::getSet("d65674c7-c8c4-4ed4-9de9-7c600b43eaab")
    end

    # Quark::issueLine(line)
    def self.issueLine(line)
        # We need to create the quark and the lepton (in the opposite order)

        leptonfilename = "#{SecureRandom.uuid}.sqlite3"
        leptonfilepath = Lepton::leptonFilenameToFilepath(leptonfilename)
        Lepton::createLeptonLine(leptonfilepath, line)

        object = {
            "uuid"              => SecureRandom.uuid,
            "nyxNxSet"          => "d65674c7-c8c4-4ed4-9de9-7c600b43eaab",
            "unixtime"          => Time.new.to_f,
            "referenceDateTime" => nil,
            "leptonfilename"    => leptonfilename
        }
        NyxObjects2::put(object)
        object
    end

    # Quark::issueUrl(url)
    def self.issueUrl(url)
        # We need to create the quark and the lepton (in the opposite order)

        leptonfilename = "#{SecureRandom.uuid}.sqlite3"
        leptonfilepath = Lepton::leptonFilenameToFilepath(leptonfilename)
        Lepton::createLeptonUrl(leptonfilepath, url)

        object = {
            "uuid"              => SecureRandom.uuid,
            "nyxNxSet"          => "d65674c7-c8c4-4ed4-9de9-7c600b43eaab",
            "unixtime"          => Time.new.to_f,
            "referenceDateTime" => nil,
            "leptonfilename"    => leptonfilename
        }
        NyxObjects2::put(object)
        object
    end

    # Quark::issueAionFileSystemLocation(aionFileSystemLocation)
    def self.issueAionFileSystemLocation(aionFileSystemLocation)
        # We need to create the quark and the lepton (in the opposite order)

        leptonfilename = "#{SecureRandom.uuid}.sqlite3"
        leptonfilepath = Lepton::leptonFilenameToFilepath(leptonfilename)
        Lepton::createLeptonAionFileSystemLocation(leptonfilepath, aionFileSystemLocation)

        object = {
            "uuid"              => SecureRandom.uuid,
            "nyxNxSet"          => "d65674c7-c8c4-4ed4-9de9-7c600b43eaab",
            "unixtime"          => Time.new.to_f,
            "referenceDateTime" => nil,
            "leptonfilename"    => leptonfilename
        }
        NyxObjects2::put(object)
        object
    end

    # Quark::toString(quark)
    def self.toString(quark)
        leptonfilename = quark["leptonfilename"]
        leptonfilepath = Lepton::leptonFilenameToFilepath(leptonfilename)
        "[quark] #{Lepton::getDescription(leptonfilepath)}"
    end

    # Quark::landing(quark)
    def self.landing(quark)
        loop {

            return if NyxObjects2::getOrNull(quark["uuid"]).nil?

            system("clear")

            mx = LCoreMenuItemsNX1.new()

            source = Arrows::getSourcesForTarget(quark)
            source.each{|source|
                mx.item(
                    "source: #{NyxObjectInterface::toString(source)}",
                    lambda { NyxObjectInterface::landing(source) }
                )
            }

            puts ""

            puts Quark::toString(quark).green
            puts "filename: #{quark["leptonfilename"]}".yellow
            puts "filepath: #{Lepton::leptonFilenameToFilepath(quark["leptonfilename"])}".yellow

            puts ""

            Arrows::getTargetsForSource(quark).each{|target|
                menuitems.item(
                    "target: #{NyxObjectInterface::toString(target)}",
                    lambda { NyxObjectInterface::landing(target) }
                )
            }

            puts ""

            status = mx.promptAndRunSandbox()
            break if !status
        }
    end
end

class Lepton

    # Lepton::leptonFilenameToFilepath(filename)
    def self.leptonFilenameToFilepath(filename)
        "/Users/pascal/Galaxy/Leptons/#{filename}"
    end

    # Lepton::createLeptonLine(filepath, line)
    def self.createLeptonLine(filepath, line)
        db = SQLite3::Database.new(filepath)
        db.execute("create table lepton (_key_ text, _value_ data);")
        db.execute "insert into lepton (_key_, _value_) values ( ?, ? )", ["18da4008-6cb2-4df0-b9d5-bb9e3b4f949a", "line"]
        db.execute "insert into lepton (_key_, _value_) values ( ?, ? )", ["374809ce-ee4c-46c4-9639-c7028731ce64", line]
        db.close
    end

    # Lepton::createLeptonUrl(filepath, url)
    def self.createLeptonUrl(filepath, url)
        db = SQLite3::Database.new(filepath)
        db.execute("create table lepton (_key_ text, _value_ data);")
        db.execute "insert into lepton (_key_, _value_) values ( ?, ? )", ["18da4008-6cb2-4df0-b9d5-bb9e3b4f949a", "url"]
        db.execute "insert into lepton (_key_, _value_) values ( ?, ? )", ["374809ce-ee4c-46c4-9639-c7028731ce64", url]
        db.close
    end

    # Lepton::createLeptonAionFileSystemLocation(leptonFilepath, aionFileSystemLocation)
    def self.createLeptonAionFileSystemLocation(leptonFilepath, aionFileSystemLocation)
        db = SQLite3::Database.new(leptonFilepath)
        db.execute("create table lepton (_key_ text, _value_ data);")
        db.close

        operator = ElizabethLepton.new(leptonFilepath)
        roothash = AionCore::commitLocationReturnHash(operator, aionFileSystemLocation)

        db = SQLite3::Database.new(leptonFilepath)
        db.execute "insert into lepton (_key_, _value_) values ( ?, ? )", ["18da4008-6cb2-4df0-b9d5-bb9e3b4f949a", "aion-location"]
        db.execute "insert into lepton (_key_, _value_) values ( ?, ? )", ["374809ce-ee4c-46c4-9639-c7028731ce64", roothash]
        db.close
    end

    # Lepton::getDescription(filepath)
    def self.getDescription(filepath)
        db = SQLite3::Database.new(filepath)
        db.results_as_hash = true # to get the results as hash
        type = nil
        db.execute( "select * from lepton where _key_=?" , ["18da4008-6cb2-4df0-b9d5-bb9e3b4f949a"]) do |row|
          type = row["_value_"]
        end
        type = type || "unkown type for lepton file #{filepath}, how did that happen?"
        description = nil
        if type == "line" then
            db.execute("select * from lepton where _key_=?", ["374809ce-ee4c-46c4-9639-c7028731ce64"]) do |row|
              description = row["_value_"]
            end
        end
        if type == "url" then
            db.execute("select * from lepton where _key_=?", ["374809ce-ee4c-46c4-9639-c7028731ce64"]) do |row|
              description = row["_value_"]
            end
        end
        if type == "aion-location" then
            db.execute("select * from lepton where _key_=?", ["374809ce-ee4c-46c4-9639-c7028731ce64"]) do |row|
              description = "aion root: #{row["_value_"]}"
            end
        end
        description = description || "description not extracted for leptop file #{description} (type: #{type})"
        db.close
        "[lepton] [#{type}] #{description}"
    end

end

# -------------------------------------------------------------------------------------

class ElizabethLepton

    # @databaseFilepath

    def initialize(databaseFilepath)
        @databaseFilepath = databaseFilepath
    end

    def commitBlob(blob)
        nhash = "SHA256-#{Digest::SHA256.hexdigest(blob)}"
        db = SQLite3::Database.new(@databaseFilepath)
        db.execute "delete from lepton where _key_=?", [nhash]
        db.execute "insert into lepton (_key_, _value_) values ( ?, ? )", [nhash, blob]
        db.close
        nhash
    end

    def filepathToContentHash(filepath)
        "SHA256-#{Digest::SHA256.file(filepath).hexdigest}"
    end

    def readBlobErrorIfNotFound(nhash)
        db = SQLite3::Database.new(@databaseFilepath)
        db.results_as_hash = true # to get the results as hash
        blob = nil
        db.execute( "select * from lepton where _key_=?", [nhash] ) do |row|
          blob = row["_value_"]
        end
        db.close
        raise "[Elizabeth error: fc1dd1aa]" if blob.nil?
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

#AionCore::commitLocationReturnHash(operator, location)
#AionCore::exportHashAtFolder(operator, nhash, targetReconstructionFolderpath)
#AionFsck::structureCheckAionHash(operator, nhash)

# -------------------------------------------------------------------------------------


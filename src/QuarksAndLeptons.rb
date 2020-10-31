
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
        leptonFilepath = Lepton::leptonFilenameToFilepath(leptonfilename)
        type = Lepton::getTypeOrNull(leptonFilepath)
        if type == "line" then
            return "[quark] line: #{Lepton::getTypeLineLineOrNull(leptonFilepath)}"
        end
        if type == "url" then
            return "[quark] url: #{Lepton::getTypeUrlUrlOrNull(leptonFilepath)}"
        end
        if type == "aion-location" then
            operator = ElizabethLepton.new(leptonFilepath)
            nhash = Lepton::getTypeAionLocationRootHashOrNull(leptonFilepath)
            aionobject = AionCore::getAionObjectByHash(operator, nhash)
            return "[quark] aion-point: #{aionobject["name"]}" # name of the root object
        end
        puts quark
        puts leptonFilepath
        raise "error: 797be22c-9470-4fb9-bde1-ca9d401f2d62"
    end

    # Quark::access(quark)
    def self.access(quark)
        puts "access: #{Quark::toString(quark)}"
        filepath = Lepton::leptonFilenameToFilepath(quark["leptonfilename"])
        type = Lepton::getTypeOrNull(filepath)
        if type == "line" then
            puts Lepton::getTypeLineLineOrNull(filepath)
            LucilleCore::pressEnterToContinue()
        end
        if type == "url" then
            url = Lepton::getTypeUrlUrlOrNull(filepath)
            puts url
            system("open '#{url}'")
        end
        if type == "aion-location" then
            leptonFilename = quark["leptonfilename"]
            leptonFilepath = Lepton::leptonFilenameToFilepath(leptonFilename)
            operator = ElizabethLepton.new(leptonFilepath)
            nhash = Lepton::getTypeAionLocationRootHashOrNull(leptonFilepath)
            targetReconstructionFolderpath = "/Users/pascal/Desktop"
            AionCore::exportHashAtFolder(operator, nhash, targetReconstructionFolderpath)
        end
        LucilleCore::pressEnterToContinue()
    end

    # Quark::destroyQuarkAndLepton(quark)
    def self.destroyQuarkAndLepton(quark)
        leptonfilename = quark["leptonfilename"]
        leptonfilepath = Lepton::leptonFilenameToFilepath(leptonfilename)
        puts "deleting file: #{leptonfilepath}"
        FileUtils.rm(leptonfilepath)
        puts "deleting quark:"
        puts JSON.pretty_generate(quark)
        NyxObjects2::destroy(quark)
    end

    # Quark::landing(quark)
    def self.landing(quark)
        loop {

            return if NyxObjects2::getOrNull(quark["uuid"]).nil?

            system("clear")

            mx = LCoreMenuItemsNX1.new()

            puts Quark::toString(quark)
            puts "filename: #{quark["leptonfilename"]}".yellow
            puts "filepath: #{Lepton::leptonFilenameToFilepath(quark["leptonfilename"])}".yellow

            puts ""

            mx.item(
                "access",
                lambda { Quark::access(quark) }
            )

            mx.item("set/update description".yellow, lambda {
                puts "Not yet implemented"
                LucilleCore::pressEnterToContinue()
            })

            mx.item("add to set".yellow, lambda {
                set = Sets::selectExistingSetOrMakeNewOneOrNull()
                return if set.nil?
                Arrows::issueOrException(set, quark)
            })

            mx.item(
                "destroy",
                lambda { Quark::destroyQuarkAndLepton(quark) }
            )

            puts ""

            source = Arrows::getSourcesForTarget(quark)
            source.each{|source|
                mx.item(
                    "source: #{NyxObjectInterface::toString(source)}",
                    lambda { NyxObjectInterface::landing(source) }
                )
            }

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

    # Lepton::getTypeOrNull(filepath)
    def self.getTypeOrNull(filepath)
        db = SQLite3::Database.new(filepath)
        db.results_as_hash = true # to get the results as hash
        type = nil
        db.execute( "select * from lepton where _key_=?" , ["18da4008-6cb2-4df0-b9d5-bb9e3b4f949a"]) do |row|
          type = row["_value_"]
        end
        db.close
        type
    end

    # Lepton::getTypeLineLineOrNull(filepath)
    def self.getTypeLineLineOrNull(filepath)
        db = SQLite3::Database.new(filepath)
        db.results_as_hash = true # to get the results as hash
        line = nil
        db.execute( "select * from lepton where _key_=?" , ["374809ce-ee4c-46c4-9639-c7028731ce64"]) do |row|
          line = row["_value_"]
        end
        db.close
        line
    end

    # Lepton::getTypeUrlUrlOrNull(filepath)
    def self.getTypeUrlUrlOrNull(filepath)
        db = SQLite3::Database.new(filepath)
        db.results_as_hash = true # to get the results as hash
        url = nil
        db.execute( "select * from lepton where _key_=?" , ["374809ce-ee4c-46c4-9639-c7028731ce64"]) do |row|
          url = row["_value_"]
        end
        db.close
        url
    end

    # Lepton::getTypeAionLocationRootHashOrNull(filepath)
    def self.getTypeAionLocationRootHashOrNull(filepath)
        db = SQLite3::Database.new(filepath)
        db.results_as_hash = true # to get the results as hash
        roothash = nil
        db.execute( "select * from lepton where _key_=?" , ["374809ce-ee4c-46c4-9639-c7028731ce64"]) do |row|
          roothash = row["_value_"]
        end
        db.close
        roothash
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


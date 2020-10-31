
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
        leptonfilepath = LeptonFunctions::leptonFilenameToFilepath(leptonfilename)
        LeptonFunctions::createLeptonLine(leptonfilepath, line)

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
        leptonfilepath = LeptonFunctions::leptonFilenameToFilepath(leptonfilename)
        LeptonFunctions::createLeptonUrl(leptonfilepath, url)

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
        leptonfilepath = LeptonFunctions::leptonFilenameToFilepath(leptonfilename)
        LeptonFunctions::createLeptonAionFileSystemLocation(leptonfilepath, aionFileSystemLocation)

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
        leptonFilepath = LeptonFunctions::leptonFilenameToFilepath(leptonfilename)
        description = LeptonFunctions::getDescription(leptonFilepath)
        "[quark] #{description}"
    end

    # Quark::access(quark)
    def self.access(quark)
        puts "access: #{Quark::toString(quark)}"
        filepath = LeptonFunctions::leptonFilenameToFilepath(quark["leptonfilename"])
        type = LeptonFunctions::getTypeOrNull(filepath)
        if type == "line" then
            puts LeptonFunctions::getTypeLineLineOrNull(filepath)
            LucilleCore::pressEnterToContinue()
        end
        if type == "url" then
            url = LeptonFunctions::getTypeUrlUrlOrNull(filepath)
            puts url
            system("open '#{url}'")
        end
        if type == "aion-location" then
            leptonFilename = quark["leptonfilename"]
            leptonFilepath = LeptonFunctions::leptonFilenameToFilepath(leptonFilename)
            operator = ElizabethLepton.new(leptonFilepath)
            nhash = LeptonFunctions::getTypeAionLocationRootHashOrNull(leptonFilepath)
            targetReconstructionFolderpath = "/Users/pascal/Desktop"
            AionCore::exportHashAtFolder(operator, nhash, targetReconstructionFolderpath)
        end
        LucilleCore::pressEnterToContinue()
    end

    # Quark::destroyQuarkAndLepton(quark)
    def self.destroyQuarkAndLepton(quark)
        leptonfilename = quark["leptonfilename"]
        leptonfilepath = LeptonFunctions::leptonFilenameToFilepath(leptonfilename)
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
            puts "filepath: #{LeptonFunctions::leptonFilenameToFilepath(quark["leptonfilename"])}".yellow

            puts ""

            mx.item(
                "access".yellow,
                lambda { Quark::access(quark) }
            )

            mx.item("set/update description".yellow, lambda {
                leptonfilename = LeptonFunctions::leptonFilenameToFilepath(quark["leptonfilename"])
                description = LucilleCore::askQuestionAnswerAsString("description: ")
                return if description == ""
                LeptonFunctions::setDescription(leptonfilename, description)
            })

            mx.item("add to set".yellow, lambda {
                set = Sets::selectExistingSetOrMakeNewOneOrNull()
                return if set.nil?
                Arrows::issueOrException(set, quark)
            })

            mx.item(
                "destroy".yellow,
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

    # @filename
    # @filepath

    def initialize(filename)
        @filename = filename
        @filepath = LeptonFunctions::leptonFilenameToFilepath(filename)
    end

    def getFilepath()
        @filepath
    end

    def getDescription()
        LeptonFunctions::getDescription(@filepath)
    end

end

class LeptonFunctions

    # --------------------------------------------------------------
    # Real estate

    # LeptonFunctions::leptonFilenameToFilepath(filename)
    def self.leptonFilenameToFilepath(filename)
        "/Users/pascal/Galaxy/Leptons/#{filename}"
    end

    # --------------------------------------------------------------
    # Makers

    # LeptonFunctions::createLeptonLine(filepath, line)
    def self.createLeptonLine(filepath, line)
        db = SQLite3::Database.new(filepath)
        db.execute("create table lepton (_key_ text, _value_ data);")
        db.execute "insert into lepton (_key_, _value_) values ( ?, ? )", ["18da4008-6cb2-4df0-b9d5-bb9e3b4f949a", "line"]
        db.execute "insert into lepton (_key_, _value_) values ( ?, ? )", ["374809ce-ee4c-46c4-9639-c7028731ce64", line]
        db.close
    end

    # LeptonFunctions::createLeptonUrl(filepath, url)
    def self.createLeptonUrl(filepath, url)
        db = SQLite3::Database.new(filepath)
        db.execute("create table lepton (_key_ text, _value_ data);")
        db.execute "insert into lepton (_key_, _value_) values ( ?, ? )", ["18da4008-6cb2-4df0-b9d5-bb9e3b4f949a", "url"]
        db.execute "insert into lepton (_key_, _value_) values ( ?, ? )", ["374809ce-ee4c-46c4-9639-c7028731ce64", url]
        db.close
    end

    # LeptonFunctions::createLeptonAionFileSystemLocation(leptonFilepath, aionFileSystemLocation)
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

    # --------------------------------------------------------------
    # Getters

    # LeptonFunctions::getValueOrNull(db, key)
    def self.getValueOrNull(db, key)
        db.results_as_hash = true # to get the results as hash
        db.execute( "select * from lepton where _key_=?" , [key]) do |row|
          return row["_value_"]
        end
        nil
    end

    # LeptonFunctions::getDescription(filepath)
    def self.getDescription(filepath)
        db = SQLite3::Database.new(filepath)
        db.results_as_hash = true # to get the results as hash

        description = LeptonFunctions::getValueOrNull(db, "9fb612ab-698c-4f6a-ab99-5aadb3f727d0")
        return description if description

        type = LeptonFunctions::getValueOrNull(db, "18da4008-6cb2-4df0-b9d5-bb9e3b4f949a")
        type = type || "unkown type for lepton file #{filepath}, how did that happen?"
        
        description = nil

        if type == "line" then
            description = LeptonFunctions::getValueOrNull(db, "374809ce-ee4c-46c4-9639-c7028731ce64") # line
        end

        if type == "url" then
            description = LeptonFunctions::getValueOrNull(db, "374809ce-ee4c-46c4-9639-c7028731ce64") # url
        end

        if type == "aion-location" then
            aionroothash = LeptonFunctions::getValueOrNull(db, "374809ce-ee4c-46c4-9639-c7028731ce64") # aion root hash
            operator = ElizabethLepton.new(filepath)
            aionobject = AionCore::getAionObjectByHash(operator, aionroothash)
            description = aionobject["name"]
        end

        if  description.nil? then
            return "description not extracted for lepton file #{filepath} (type: #{type})"
        end

        db.close
        "[lepton] [#{type}] #{description}"
    end

    # LeptonFunctions::getTypeOrNull(filepath)
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

    # LeptonFunctions::getTypeLineLineOrNull(filepath)
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

    # LeptonFunctions::getTypeUrlUrlOrNull(filepath)
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

    # LeptonFunctions::getTypeAionLocationRootHashOrNull(filepath)
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

    # --------------------------------------------------------------
    # Setters

    # LeptonFunctions::setValueOrNull(db, key, value)
    def self.setValueOrNull(db, key, value)
        db.execute "delete from lepton where _key_=?", [key]
        db.execute "insert into lepton (_key_, _value_) values ( ?, ? )", [key, value]
    end

    # LeptonFunctions::setDescription(filepath, description)
    def self.setDescription(filepath, description)
        db = SQLite3::Database.new(filepath)
        LeptonFunctions::setValueOrNull(db, "9fb612ab-698c-4f6a-ab99-5aadb3f727d0", description)
        db.close
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



# encoding: UTF-8

class Lepton

    # @filename
    # @filepath

    def initialize(filename)
        @filename = filename
        @filepath = LeptonsFunctions::leptonFilenameToFilepath(filename)
    end

    def getFilepath()
        @filepath
    end

    def getDescription()
        LeptonsFunctions::getDescription(@filepath)
    end

end

class LeptonsFunctions

    # --------------------------------------------------------------
    # Real estate

    # LeptonsFunctions::leptonFilenameToFilepath(filename)
    def self.leptonFilenameToFilepath(filename)
        "/Users/pascal/Galaxy/Leptons/#{filename}"
    end

    # LeptonsFunctions::filepaths()
    def self.filepaths()
        Dir.entries("/Users/pascal/Galaxy/Leptons")
            .select{|filename|
                filename[-8, 8] == ".sqlite3"
            }
            .map{|filename|
                "/Users/pascal/Galaxy/Leptons/#{filename}"
            }
    end

    # LeptonsFunctions::getQuarkForLeptonFilenameOrNull(filename)
    def self.getQuarkForLeptonFilenameOrNull(filename)
        Quarks::quarks().select{|quark| quark["leptonfilename"] == filename }.first
    end

    # --------------------------------------------------------------
    # Makers

    # LeptonsFunctions::createLeptonLine(filepath, line)
    def self.createLeptonLine(filepath, line)
        db = SQLite3::Database.new(filepath)
        db.execute("create table lepton (_key_ text, _value_ data);")
        db.execute "insert into lepton (_key_, _value_) values ( ?, ? )", ["18da4008-6cb2-4df0-b9d5-bb9e3b4f949a", "line"]
        db.execute "insert into lepton (_key_, _value_) values ( ?, ? )", ["374809ce-ee4c-46c4-9639-c7028731ce64", line]
        db.close
    end

    # LeptonsFunctions::createLeptonUrl(filepath, url)
    def self.createLeptonUrl(filepath, url)
        db = SQLite3::Database.new(filepath)
        db.execute("create table lepton (_key_ text, _value_ data);")
        db.execute "insert into lepton (_key_, _value_) values ( ?, ? )", ["18da4008-6cb2-4df0-b9d5-bb9e3b4f949a", "url"]
        db.execute "insert into lepton (_key_, _value_) values ( ?, ? )", ["374809ce-ee4c-46c4-9639-c7028731ce64", url]
        db.close
    end

    # LeptonsFunctions::createLeptonAionFileSystemLocation(leptonFilepath, aionFileSystemLocation)
    def self.createLeptonAionFileSystemLocation(leptonFilepath, aionFileSystemLocation)
        db = SQLite3::Database.new(leptonFilepath)
        db.execute("create table lepton (_key_ text, _value_ data);")
        db.close

        operator = ElizabethLeptons.new(leptonFilepath)
        roothash = AionCore::commitLocationReturnHash(operator, aionFileSystemLocation)

        db = SQLite3::Database.new(leptonFilepath)
        db.execute "insert into lepton (_key_, _value_) values ( ?, ? )", ["18da4008-6cb2-4df0-b9d5-bb9e3b4f949a", "aion-location"]
        db.execute "insert into lepton (_key_, _value_) values ( ?, ? )", ["374809ce-ee4c-46c4-9639-c7028731ce64", roothash]
        db.close
    end

    # --------------------------------------------------------------
    # Getters

    # LeptonsFunctions::getValueOrNull(db, key)
    def self.getValueOrNull(db, key)
        db.results_as_hash = true # to get the results as hash
        db.execute( "select * from lepton where _key_=?" , [key]) do |row|
          return row["_value_"]
        end
        nil
    end

    # LeptonsFunctions::getStoredDescriptionOrNull(filepath)
    def self.getStoredDescriptionOrNull(filepath)
        db = SQLite3::Database.new(filepath)
        description = LeptonsFunctions::getValueOrNull(db, "9fb612ab-698c-4f6a-ab99-5aadb3f727d0")
        db.close
        description
    end

    # LeptonsFunctions::getDescription(filepath)
    def self.getDescription(filepath)
        db = SQLite3::Database.new(filepath)
        db.results_as_hash = true # to get the results as hash

        type = LeptonsFunctions::getValueOrNull(db, "18da4008-6cb2-4df0-b9d5-bb9e3b4f949a")
        type = type || "unkown type for lepton file #{filepath}, how did that happen?"

        description = LeptonsFunctions::getValueOrNull(db, "9fb612ab-698c-4f6a-ab99-5aadb3f727d0")
        return "[#{type}] #{description}" if description

        description = nil

        if type == "line" then
            description = LeptonsFunctions::getValueOrNull(db, "374809ce-ee4c-46c4-9639-c7028731ce64") # line
        end

        if type == "url" then
            description = LeptonsFunctions::getValueOrNull(db, "374809ce-ee4c-46c4-9639-c7028731ce64") # url
        end

        if type == "aion-location" then
            aionroothash = LeptonsFunctions::getValueOrNull(db, "374809ce-ee4c-46c4-9639-c7028731ce64") # aion root hash
            operator = ElizabethLeptons.new(filepath)
            aionobject = AionCore::getAionObjectByHash(operator, aionroothash)
            description = aionobject["name"]
        end

        if  description.nil? then
            return "description not extracted for lepton file #{filepath} (type: #{type})"
        end

        db.close
        "[#{type}] #{description}"
    end

    # LeptonsFunctions::getTypeOrNull(filepath)
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

    # LeptonsFunctions::getTypeLineLineOrNull(filepath)
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

    # LeptonsFunctions::getTypeUrlUrlOrNull(filepath)
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

    # LeptonsFunctions::getTypeAionLocationRootHashOrNull(filepath)
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

    # LeptonsFunctions::setValueOrNull(db, key, value)
    def self.setValueOrNull(db, key, value)
        db.execute "delete from lepton where _key_=?", [key]
        db.execute "insert into lepton (_key_, _value_) values ( ?, ? )", [key, value]
    end

    # LeptonsFunctions::setDescription(filepath, description)
    def self.setDescription(filepath, description)
        db = SQLite3::Database.new(filepath)
        LeptonsFunctions::setValueOrNull(db, "9fb612ab-698c-4f6a-ab99-5aadb3f727d0", description)
        db.close
    end

end

# -------------------------------------------------------------------------------------

class ElizabethLeptons

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


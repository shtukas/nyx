
# encoding: UTF-8

class DxPure

    # ------------------------------------------------------------
    # Basic IO (1)

    # DxPure::makeNewPureFile(filepath)
    def self.makeNewPureFile(filepath)
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("create table _dx_ (_key_ text primary key, _value_ blob)", [])
        db.close
    end

    # DxPure::insertIntoPure(filepath, key, value)
    def self.insertIntoPure(filepath, key, value)
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        db.execute("delete from _dx_ where _key_=?", [key])
        db.execute("insert into _dx_ (_key_, _value_) values (?, ?)", [key, value])
        db.close
    end

    # DxPure::readValueOrNull(filepath, key)
    def self.readValueOrNull(filepath, key)
        db = SQLite3::Database.new(filepath)
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        value = nil
        db.execute("select _value_ from _dx_ where _key_=?", [key]) do |row|
            value = row["_value_"]
        end
        db.close
        value
    end

    # DxPure::getMikuType(filepath)
    def self.getMikuType(filepath)
        # We are working with the assumption that we can't fail the look up of a mikutype from the file itself
        mikuType = DxPure::readValueOrNull(filepath, "mikuType")
        if mikuType.nil? then
            raise "(error: c0fb51dc-13d3-4abe-a628-06e0daa02d38) could not extract mikuType from file #{filepath}"
        end
        mikuType
    end

    # ------------------------------------------------------------
    # Basic IO (2)

    # DxPure::sha1ToLocalFilepath(sha1)
    def self.sha1ToLocalFilepath(sha1)
        filepath = "#{Config::pathToLocalDataBankStargate()}/DxPure/#{sha1[0, 2]}/#{sha1}.sqlite3"
        if !File.exists?(File.dirname(filepath)) then
            FileUtils.mkdir(File.dirname(filepath))
        end
        filepath
    end

    # DxPure::sha1ToEnergyGrid1Filepath(sha1)
    def self.sha1ToEnergyGrid1Filepath(sha1)
        filepath = "#{StargateCentral::pathToCentral()}/DxPure/#{sha1[0, 2]}/#{sha1}.sqlite3"
        if !File.exists?(File.dirname(filepath)) then
            FileUtils.mkdir(File.dirname(filepath))
        end
        filepath
    end


    # ------------------------------------------------------------
    # Basic Utils

    # DxPure::getMikuTypeOrNull(sha1)
    def self.getMikuTypeOrNull(sha1)
        filepath = DxPure::sha1ToLocalFilepath(sha1)
        return nil if !File.exists?(filepath)
        DxPure::getMikuType(filepath)
    end

    # ------------------------------------------------------------
    # Issues

    # DxPure::dxPureTypes()
    def self.dxPureTypes()
        ["url"]
    end

    # DxPure::interactivelyIssueNewOrNull(owner) # null or sha1
    def self.interactivelyIssueNewOrNull(owner)
        type = LucilleCore::selectEntityFromListOfEntitiesOrNull("DxPure type", DxPure::dxPureTypes())
        return nil if type.nil?
        if type == "url" then
            return DxPureUrl::interactivelyIssueNewOrNull(owner)
        end
        raise "(error: af59a943-db42-4190-a79e-d313aafc4165) type: #{type}" 
    end

    # ------------------------------------------------------------
    # Data

    # DxPure::toString(sha1)
    def self.toString(sha1)
        filepath = DxPure::sha1ToLocalFilepath(sha1)
        if !File.exists?(filepath) then
            return "(error: I cannot see the file #{filepath} for DxPure::toString(#{sha1}))"
        end
        mikuType = DxPure::getMikuType(filepath)
        if mikuType == "DxPureUrl" then
            return DxPureUrl::toString(filepath)
        end
        raise "(error: 00809174-4b82-4138-8810-20be99eb1219) DxPure toString: unsupported mikuType: #{mikuType}"
    end

    # ------------------------------------------------------------
    # Operations

    # DxPure::access(sha1)
    def self.access(sha1)
        filepath = DxPure::sha1ToLocalFilepath(sha1)
        if !File.exists?(filepath) then
            puts "I cannot see the file #{filepath}. Operation access aborted."
            LucilleCore::pressEnterToContinue()
            return
        end
        mikuType = DxPure::getMikuType(filepath)
        if mikuType == "DxPureUrl" then
            DxPureUrl::access(filepath)
            return 
        end
        raise "(error: 9a06ba98-9ec5-4dd5-94c8-1a87dd566506) DxPure access: unsupported mikuType: #{mikuType}"
    end

    # ------------------------------------------------------------
    # Fsck

    # DxPure::fsckFileRaiseError(filepath)
    def self.fsckFileRaiseError(filepath)
        mikuType = DxPure::getMikuType(filepath)

        ensureAttributeExists = lambda {|filepath, attrname|
            if DxPure::readValueOrNull(filepath, attrname).nil? then
                raise "(error: 5d636d7d-0a9c-4ef9-8abc-0992c99dafde) filepath: #{filepath}, attrname: #{attrname}"
            end
        }

        if mikuType == "DxPureUrl" then
            ensureAttributeExists.call(filepath, "randomValue")
            ensureAttributeExists.call(filepath, "mikuType")
            ensureAttributeExists.call(filepath, "unixtime")
            ensureAttributeExists.call(filepath, "datetime")
            ensureAttributeExists.call(filepath, "owner")
            ensureAttributeExists.call(filepath, "url")
            return
        end

        raise "(error: fa74feac-37c6-4525-93ba-933f52d54321) DxPure fsck: unsupported mikuType: #{mikuType}"
    end

    # ------------------------------------------------------------
    # Collection Management

    # DxPure::localFilepathsEnumerator()
    def self.localFilepathsEnumerator()
        Enumerator.new do |filepaths|
            Find.find("#{Config::pathToLocalDataBankStargate()}/DxPure") do |path|
                next if path[-8, 8] != ".sqlite3"
                filepaths << path
            end
        end
    end
end

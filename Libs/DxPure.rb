
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

    # DxPure::sha1ToFilepath(sha1)
    def self.sha1ToFilepath(sha1)
        "/Users/pascal/Galaxy/DataBank/Stargate/DxPure/#{sha1[0, 2]}/#{sha1}.sqlite3"
    end

    # ------------------------------------------------------------
    # Basic Utils

    # DxPure::getMikuTypeOrNull(sha1)
    def self.getMikuTypeOrNull(sha1)
        filepath = DxPure::sha1ToFilepath(sha1)
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
        filepath = DxPure::sha1ToFilepath(sha1)
        if !File.exists?(filepath) then
            return "(error: I cannot see the file #{filepath} for DxPure::toString(#{sha1}))"
        end
        mikuType = DxPure::getMikuType(filepath)
        if mikuType == "DxPureUrl" then
            return DxPureUrl::toString(filepath)
        end
    end

    # ------------------------------------------------------------
    # Operations

    # DxPure::access(sha1)
    def self.access(sha1)
        filepath = DxPure::sha1ToFilepath(sha1)
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
    end
end

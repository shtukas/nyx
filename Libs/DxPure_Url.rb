
# encoding: UTF-8

def makeNewDxPureFile(filepath)
    db = SQLite3::Database.new(filepath)
    db.busy_timeout = 117
    db.busy_handler { |count| true }
    db.results_as_hash = true
    db.execute("create table _dx_ (_key_ text primary key, _value_ blob)", [])
    db.close
end

def insertIntoDxPure(filepath, key, value)
    db = SQLite3::Database.new(filepath)
    db.busy_timeout = 117
    db.busy_handler { |count| true }
    db.results_as_hash = true
    db.execute("delete from _dx_ where _key_=?", [key])
    db.execute("insert into _dx_ (_key_, _value_) values (?, ?)", [key, value])
    db.close
end

class DxPure_Url

=begin
DxPure_Url:
    "randomValue"  : String
    "mikuType"     : "DxPure_Url"
    "unixtime"     : Float
    "datetime"     : DateTime Iso 8601 UTC Zulu
    "owner"        : String
    "url"          : String
    "savedInVault" : Boolean
=end

    # DxPure_Url::make(owner, url) # sha1, sha1 in the full filename of the pure immutable content-addressed data island, of the form <sha1>.sqlite3
    def self.make(owner, url)

        randomValue  = SecureRandom.hex
        mikuType     = "DxPure_Url"
        unixtime     = Time.new.to_i
        datetime     = Time.new.utc.iso8601
        # owner
        # url
        savedInVault = "false"

        filepath1 = "/tmp/#{SecureRandom.hex}.sqlite3"
        makeNewDxPureFile(filepath1)
        insertIntoDxPure(filepath1, "randomValue", randomValue)
        insertIntoDxPure(filepath1, "mikuType", mikuType)
        insertIntoDxPure(filepath1, "unixtime", unixtime)
        insertIntoDxPure(filepath1, "datetime", datetime)
        insertIntoDxPure(filepath1, "owner", owner)
        insertIntoDxPure(filepath1, "url", url)
        insertIntoDxPure(filepath1, "savedInVault", savedInVault)

        sha1 = Digest::SHA1.file(filepath1).hexdigest

        filepath2 = "/Users/pascal/Galaxy/DataBank/Stargate/DxPure/#{sha1[0, 2]}/#{sha1}.sqlite3"
        if !File.exists?(File.dirname(filepath2)) then
            FileUtils.mkdir(File.dirname(filepath2))
        end

        FileUtils.mv(filepath1, filepath2)

        sha1
    end
end

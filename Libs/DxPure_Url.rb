
# encoding: UTF-8

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
        DxPure::makeNewPureFile(filepath1)

        DxPure::insertIntoPure(filepath1, "randomValue", randomValue)
        DxPure::insertIntoPure(filepath1, "mikuType", mikuType)
        DxPure::insertIntoPure(filepath1, "unixtime", unixtime)
        DxPure::insertIntoPure(filepath1, "datetime", datetime)
        DxPure::insertIntoPure(filepath1, "owner", owner)
        DxPure::insertIntoPure(filepath1, "url", url)
        DxPure::insertIntoPure(filepath1, "savedInVault", savedInVault)

        sha1 = Digest::SHA1.file(filepath1).hexdigest

        filepath2 = "/Users/pascal/Galaxy/DataBank/Stargate/DxPure/#{sha1[0, 2]}/#{sha1}.sqlite3"
        if !File.exists?(File.dirname(filepath2)) then
            FileUtils.mkdir(File.dirname(filepath2))
        end

        FileUtils.mv(filepath1, filepath2)

        sha1
    end

    # DxPure_Url::toString(filepath)
    def self.toString(filepath)
        
    end

    # DxPure_Url::access(filepath)
    def self.access(filepath)
        
    end
end

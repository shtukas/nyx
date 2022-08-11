
# encoding: UTF-8

class DxPureUrl

    # ------------------------------------------------------------------
    # Making

    # DxPureUrl::issue(owner, url) # sha1, sha1 in the full filename of the pure immutable content-addressed data island, of the form <sha1>.sqlite3
    def self.issue(owner, url)

        randomValue  = SecureRandom.hex
        mikuType     = "DxPureUrl"
        unixtime     = Time.new.to_i
        datetime     = Time.new.utc.iso8601
        # owner
        # url

        filepath1 = "/tmp/#{SecureRandom.hex}.sqlite3"
        DxPure::makeNewPureFile(filepath1)

        DxPure::insertIntoPure(filepath1, "randomValue", randomValue)
        DxPure::insertIntoPure(filepath1, "mikuType", mikuType)
        DxPure::insertIntoPure(filepath1, "unixtime", unixtime)
        DxPure::insertIntoPure(filepath1, "datetime", datetime)
        DxPure::insertIntoPure(filepath1, "owner", owner)
        DxPure::insertIntoPure(filepath1, "url", url)

        DxPure::fsckFileRaiseError(filepath1)

        sha1 = Digest::SHA1.file(filepath1).hexdigest

        filepath2 = DxPure::sha1ToLocalFilepath(sha1)

        FileUtils.mv(filepath1, filepath2)

        sha1
    end

    # DxPureUrl::interactivelyIssueNewOrNull(owner) # null or sha1
    def self.interactivelyIssueNewOrNull(owner)
        url = LucilleCore::askQuestionAnswerAsString("url (empty to abort) : ")
        return nil if url == ""
        DxPureUrl::issue(owner, url)
    end

    # ------------------------------------------------------------------
    # Data

    # DxPureUrl::toString(filepath)
    def self.toString(filepath)
        "(url) #{DxPure::readValueOrNull(filepath, "url")}"
    end

    # ------------------------------------------------------------------
    # Operations

    # DxPureUrl::access(filepath)
    def self.access(filepath)
        url = DxPure::readValueOrNull(filepath, "url")
        puts "url: #{url}"
        CommonUtils::openUrlUsingSafari(url)
        LucilleCore::pressEnterToContinue()
    end
end

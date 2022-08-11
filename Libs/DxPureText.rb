
# encoding: UTF-8

class DxPureText

    # ------------------------------------------------------------------
    # Making

    # DxPureText::issue(owner, text) # sha1, sha1 in the full filename of the pure immutable content-addressed data island, of the form <sha1>.sqlite3
    def self.issue(owner, text)

        randomValue  = SecureRandom.hex
        mikuType     = "DxPureText"
        unixtime     = Time.new.to_i
        datetime     = Time.new.utc.iso8601
        # owner
        # text

        filepath1 = "/tmp/#{SecureRandom.hex}.sqlite3"
        DxPure::makeNewPureFile(filepath1)

        DxPure::insertIntoPure(filepath1, "randomValue", randomValue)
        DxPure::insertIntoPure(filepath1, "mikuType", mikuType)
        DxPure::insertIntoPure(filepath1, "unixtime", unixtime)
        DxPure::insertIntoPure(filepath1, "datetime", datetime)
        DxPure::insertIntoPure(filepath1, "owner", owner)
        DxPure::insertIntoPure(filepath1, "text", text)

        DxPure::fsckFileRaiseError(filepath1)

        sha1 = Digest::SHA1.file(filepath1).hexdigest

        filepath2 = DxPure::sha1ToLocalFilepath(sha1)

        FileUtils.mv(filepath1, filepath2)

        sha1
    end

    # DxPureText::interactivelyIssueNewOrNull(owner) # null or sha1
    def self.interactivelyIssueNewOrNull(owner)
        text = CommonUtils::editTextSynchronously(text)
        DxPureText::issue(owner, text)
    end

    # ------------------------------------------------------------------
    # Data

    # DxPureText::toString(filepath)
    def self.toString(filepath)
        "(text) #{File.basename(filepath)}"
    end

    # ------------------------------------------------------------------
    # Operations

    # DxPureText::access(filepath)
    def self.access(filepath)
        text = DxPure::readValueOrNull(filepath, "text")
        puts "--------------------------------------------"
        puts "text:\n#{text}"
        puts "--------------------------------------------"
        LucilleCore::pressEnterToContinue()
    end
end

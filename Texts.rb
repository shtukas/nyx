
# encoding: UTF-8

# require_relative "Bosons.rb"

require 'fileutils'
# FileUtils.mkpath '/a/b/c'
# FileUtils.cp(src, dst)
# FileUtils.mv 'oldname', 'newname'
# FileUtils.rm(path_to_image)
# FileUtils.rm_rf('dir/to/remove')

require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(4) #=> "eb693123"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"

require 'digest/sha1'
# Digest::SHA1.hexdigest 'foo'
# Digest::SHA1.file(myFile).hexdigest

require_relative "Quarks.rb"

require_relative "Cliques.rb"

require_relative "KeyValueStore.rb"
=begin
    KeyValueStore::setFlagTrue(repositorylocation or nil, key)
    KeyValueStore::setFlagFalse(repositorylocation or nil, key)
    KeyValueStore::flagIsTrue(repositorylocation or nil, key)

    KeyValueStore::set(repositorylocation or nil, key, value)
    KeyValueStore::getOrNull(repositorylocation or nil, key)
    KeyValueStore::getOrDefaultValue(repositorylocation or nil, key, defaultValue)
    KeyValueStore::destroy(repositorylocation or nil, key)
=end

require_relative "BTreeSets.rb"
=begin
    BTreeSets::values(repositorylocation or nil, setuuid: String): Array[Value]
    BTreeSets::set(repositorylocation or nil, setuuid: String, valueuuid: String, value)
    BTreeSets::getOrNull(repositorylocation or nil, setuuid: String, valueuuid: String): nil | Value
    BTreeSets::destroy(repositorylocation or nil, setuuid: String, valueuuid: String)
=end

# -----------------------------------------------------------------

class TextZ

    # TextZ::make(textid, text)
    def self.make(textid, text)
        namedhash = NyxBlobs::put(text)
        {
            "uuid"      => SecureRandom.uuid,
            "nyxNxSet"  => "ab01a47c-bb91-4a15-93f5-b98cd3eb1866",
            "unixtime"  => Time.new.to_f,
            "textid"    => textid,
            "namedhash" => namedhash
        }
    end

    # TextZ::issue(textid, text)
    def self.issue(textid, text)
        text = TextZ::make(textid, text)
        NyxObjects::put(text)
        text
    end

    # TextZ::getTextZForIdOrderedByTime(textid)
    def self.getTextZForIdOrderedByTime(textid)
        NyxObjects::getSet("ab01a47c-bb91-4a15-93f5-b98cd3eb1866")
            .select{|note| note["textid"] == textid }
            .sort{|n1,n2| n1["unixtime"] <=> n2["unixtime"] }
    end

    # TextZ::getMostRecentTextForIdOrNull(textid)
    def self.getMostRecentTextForIdOrNull(textid)
        texts = TextZ::getTextZForIdOrderedByTime(textid)
        return nil if texts.empty?
        NyxBlobs::getBlobOrNull(texts.last["namedhash"])
    end

    # TextZ::issueNewTextWithNewId()
    def self.issueNewTextWithNewId()
        textid = SecureRandom.uuid
        text = Miscellaneous::editTextUsingTextmate("")
        TextZ::make(textid, text)
    end
end

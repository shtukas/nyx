
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

class Notes

    # Notes::make(targetuuid, text)
    def self.make(targetuuid, text)
        namedhash = NyxBlobs::put(text)
        {
            "uuid"       => SecureRandom.uuid,
            "nyxNxSet"   => "c6fad718-1306-49cf-a361-76ce85e909ca",
            "unixtime"   => Time.new.to_f,
            "targetuuid" => targetuuid,
            "namedhash"  => namedhash
        }
    end

    # Notes::issue(targetuuid, text)
    def self.issue(targetuuid, text)
        note = Notes::make(targetuuid, text)
        NyxObjects::put(note)
        note
    end

    # Notes::getNotesForTargetOrderedByTime(targetuuid)
    def self.getNotesForTargetOrderedByTime(targetuuid)
        NyxObjects::getSet("c6fad718-1306-49cf-a361-76ce85e909ca")
            .select{|note| note["targetuuid"] == targetuuid }
            .sort{|n1,n2| n1["unixtime"] <=> n2["unixtime"] }
    end

    # Notes::getMostRecentTextForTargetOrNull(targetuuid)
    def self.getMostRecentTextForTargetOrNull(targetuuid)
        notes = Notes::getNotesForTargetOrderedByTime(targetuuid)
        return nil if notes.empty?
        note = notes.last
        NyxBlobs::getBlobOrNull(note["namedhash"])
    end
end

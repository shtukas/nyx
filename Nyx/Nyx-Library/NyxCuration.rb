#!/usr/bin/ruby

# encoding: UTF-8

require 'find'

require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(4) #=> "eb693123"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"

require 'json'

require 'time'

require 'colorize'

require 'fileutils'
# FileUtils.mkpath '/a/b/c'
# FileUtils.cp(src, dst)
# FileUtils.mv 'oldname', 'newname'
# FileUtils.rm(path_to_image)
# FileUtils.rm_rf('dir/to/remove')

require "/Users/pascal/Galaxy/LucilleOS/Software-Common/Ruby-Libraries/LucilleCore.rb"
# LucilleCore::askQuestionAnswerAsString(question)
# LucilleCore::askQuestionAnswerAsBoolean(announce, defaultValue = nil)

require "/Users/pascal/Galaxy/LucilleOS/Software-Common/Ruby-Libraries/BTreeSets.rb"
=begin
    BTreeSets::values(repositorylocation or nil, setuuid: String): Array[Value]
    BTreeSets::set(repositorylocation or nil, setuuid: String, valueuuid: String, value)
    BTreeSets::getOrNull(repositorylocation or nil, setuuid: String, valueuuid: String): nil | Value
    BTreeSets::destroy(repositorylocation, setuuid: String, valueuuid: String)
=end

require "/Users/pascal/Galaxy/LucilleOS/Software-Common/Ruby-Libraries/KeyValueStore.rb"
=begin
    KeyValueStore::setFlagTrue(repositorylocation or nil, key)
    KeyValueStore::setFlagFalse(repositorylocation or nil, key)
    KeyValueStore::flagIsTrue(repositorylocation or nil, key)

    KeyValueStore::set(repositorylocation or nil, key, value)
    KeyValueStore::getOrNull(repositorylocation or nil, key)
    KeyValueStore::getOrDefaultValue(repositorylocation or nil, key, defaultValue)
    KeyValueStore::destroy(repositorylocation or nil, key)
=end

require 'digest/sha1'
# Digest::SHA1.hexdigest 'foo'
# Digest::SHA1.file(myFile).hexdigest
# Digest::SHA256.hexdigest 'message'  
# Digest::SHA256.file(myFile).hexdigest

# --------------------------------------------------------------------

class NyxCuration

    # NyxCuration::curate()
    def self.curate()

        # ----------------------------------------------------------------------------------------
        # Remove permanodes with no targets
        NyxPermanodeOperator::permanodesEnumerator(PATH_TO_YMIR)
            .select{|permanode| permanode["targets"].size == 0 }
            .each{|permanode|
                puts "Destroying permanode '#{permanode["description"]}' (no targets)"
                NyxPermanodeOperator::destroyPermanodeAttempt(permanode)
            }

        # ----------------------------------------------------------------------------------------
        # Correct permanodes with descriptions with have more than one lines
        NyxPermanodeOperator::permanodesEnumerator(PATH_TO_YMIR)
            .select{|permanode|
                permanode["description"].lines.to_a.size > 1
            }
            .each{|permanode|
                puts "Correcting permanode description"
                permanode["description"] = NyxMiscUtils::editTextUsingTextmate(permanode["description"]).strip
                NyxMiscUtils::commitPermanodeToDiskWithMaintenance(permanode)
            }

    end
end

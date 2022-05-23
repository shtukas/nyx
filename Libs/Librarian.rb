
require 'digest/sha1'
# Digest::SHA1.hexdigest 'foo'
# Digest::SHA1.file(myFile).hexdigest
# Digest::SHA256.hexdigest 'message'  
# Digest::SHA256.file(myFile).hexdigest

require 'securerandom'
# SecureRandom.hex    #=> "eb693ec8252cd630102fd0d0fb7c3485"
# SecureRandom.hex(4) #=> "eb693123"
# SecureRandom.uuid   #=> "2d931510-d99f-494a-8c67-87feb05e1594"

require 'find'

require "/Users/pascal/Galaxy/LucilleOS/Libraries/Ruby-Libraries/XCache.rb"
=begin
    XCache::setFlagTrue(key)
    XCache::setFlagFalse(key)
    XCache::flagIsTrue(key)

    XCache::set(key, value)
    XCache::getOrNull(key)
    XCache::getOrDefaultValue(key, defaultValue)
    XCache::destroy(key)
=end

# ------------------------------------------------------------------------

class LibrarianCLI

    # LibrarianCLI::main()
    def self.main()

        if ARGV[0] == "show-object" and ARGV[1] then
            uuid = ARGV[1]
            object = LocalObjectsStore::getObjectIncludedDeletedByUUIDOrNull(uuid)
            if object then
                puts JSON.pretty_generate(object)
                LucilleCore::pressEnterToContinue()
            else
                puts "I could not find an object with this uuid"
                LucilleCore::pressEnterToContinue()
            end
            exit
        end

        if ARGV[0] == "edit-object" and ARGV[1] then
            uuid = ARGV[1]
            object = LocalObjectsStore::getObjectIncludedDeletedByUUIDOrNull(uuid)
            if object then
                object = DidactUtils::editTextSynchronously(JSON.pretty_generate(object))
                object = JSON.parse(object)
                LocalObjectsStore::commitWithoutUpdates(object)
            else
                puts "I could not find an object with this uuid"
                LucilleCore::pressEnterToContinue()
            end
            exit
        end

        if ARGV[0] == "destroy-object-by-uuid-i" then
            uuid = LucilleCore::askQuestionAnswerAsString("uuid: ")
            LocalObjectsStore::logicaldelete(uuid)
            exit
        end

        if ARGV[0] == "get-blob" and ARGV[1] then
            nhash = ARGV[1]
            blob = EnergyGridDatablobs::getBlobOrNull(nhash)
            if blob then
                puts blob
            else
                puts "I could not find a blob with nhash: #{nhash}"
                LucilleCore::pressEnterToContinue()
            end
            exit
        end

        puts "usage:"
        puts "    librarian get-blob <nhash>"
        puts "    librarian show-object <uuid>"
        puts "    librarian edit-object <uuid>"
        puts "    librarian destroy-object-by-uuid-i"
    end
end

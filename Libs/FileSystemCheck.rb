
# encoding: UTF-8

require "/Users/pascal/Galaxy/LucilleOS/Libraries/Ruby-Libraries/LucilleCore.rb"

require "/Users/pascal/Galaxy/LucilleOS/Libraries/Ruby-Libraries/AionCore.rb"
=begin

The operator is an object that has meet the following signatures

    .putBlob(blob: BinaryData) : Hash
    .filepathToContentHash(filepath) : Hash
    .readBlobErrorIfNotFound(nhash: Hash) : BinaryData
    .datablobCheck(nhash: Hash): Boolean

class Elizabeth

    def initialize()

    end

    def putBlob(blob)
        nhash = "SHA256-#{Digest::SHA256.hexdigest(blob)}"
        XCache::set("SHA256-#{Digest::SHA256.hexdigest(blob)}", blob)
        nhash
    end

    def filepathToContentHash(filepath)
        "SHA256-#{Digest::SHA256.file(filepath).hexdigest}"
    end

    def readBlobErrorIfNotFound(nhash)
        blob = XCache::getOrNull(nhash)
        raise "[Elizabeth error: fc1dd1aa]" if blob.nil?
        blob
    end

    def datablobCheck(nhash)
        begin
            readBlobErrorIfNotFound(nhash)
            true
        rescue
            false
        end
    end
end

AionCore::commitLocationReturnHash(operator, location)
AionCore::exportHashAtFolder(operator, nhash, targetReconstructionFolderpath)

AionFsck::structureCheckAionHash(operator, nhash)

=end

class FileSystemCheck

    # FileSystemCheck::exitIfMissingCanary()
    def self.exitIfMissingCanary()
        if !File.exists?("/Users/pascal/Desktop/Pascal.png") then # We use this file to interrupt long runs at a place where it would not corrupt any file system.
            puts "Interrupted after missing canary file.".green
            exit
        end
    end

    # FileSystemCheck::fsckNx111ExitAtFirstFailure(object, nx111)
    def self.fsckNx111ExitAtFirstFailure(object, nx111)
        return if nx111.nil?
        if !Nx111::types().include?(nx111["type"]) then
            puts "object has an incorrect nx111 value type".red
            puts JSON.pretty_generate(object).red
            exit 1
        end
        if nx111["type"] == "text" then
            nhash = nx111["nhash"]
            blob = EnergyGridUniqueBlobs::getBlobOrNull(nhash)
            if blob.nil? then
                puts "EnergyGridUniqueBlobs::getBlobOrNull(nhash): could not find the text data".red
                puts JSON.pretty_generate(object).red
                exit 1
            end
            return
        end
        if nx111["type"] == "url" then
            return
        end
        if nx111["type"] == "file" then
            dottedExtension = nx111["dottedExtension"]
            nhash = nx111["nhash"]
            parts = nx111["parts"]
            if dottedExtension[0, 1] != "." then
                puts "object:".red
                puts JSON.pretty_generate(object).red
                puts "primitive parts, dotted extension is malformed".red
                exit 1
            end
            elizabeth = EnergyGridImmutableDataIslandsOperator::getElizabethForPrimitiveFileParts(parts)
            parts.each{|nhash|
                blob = elizabeth.getBlobOrNull(nhash)
                if blob.nil? then
                    puts "object:".red
                    puts JSON.pretty_generate(object).red
                    puts "primitive parts, nhash not found: #{nhash}".red
                    exit 1
                end
            }
            return
        end
        if nx111["type"] == "aion-point" then
            rootnhash = nx111["rootnhash"]
            elizabeth = EnergyGridImmutableDataIslandsOperator::getElizabethForIslandForNhash(rootnhash)
            status = AionFsck::structureCheckAionHash(elizabeth, rootnhash)
            if !status then
                puts "object, could not validate aion-point".red
                puts JSON.pretty_generate(object).red
                exit 1
            end
            return
        end
        if nx111["type"] == "unique-string" then
            return
        end
        if nx111["type"] == "Dx8Unit" then
            unitId = nx111["unitId"]
            location = Dx8UnitsUtils::dx8UnitFolder(unitId)
            puts "location: #{location}"
            if !File.exists?(location) then
                puts "note: could not find location for Dx8Unit: #{unitId}".red
            end
            return
        end
        raise "(24500b54-9a88-4058-856a-a26b3901c23a: incorrect nx111 value: #{nx111})"
    end

    # FileSystemCheck::fsckLibrarianMikuObjectExitAtFirstFailure(item, verbose)
    def self.fsckLibrarianMikuObjectExitAtFirstFailure(item, verbose)

        puts "fsck: #{JSON.pretty_generate(item)}" if verbose

        if item["mikuType"].nil? then
            raise "(error: d24aa0a4-4a42-40aa-81ca-6ead2d3f7fee) item has no mikuType, #{JSON.pretty_generate(item)}" 
        end

        if item["mikuType"] == "Ax1Text" then
            nhash = item["nhash"]
            blob = EnergyGridUniqueBlobs::getBlobOrNull(nhash)
            if blob.nil? then
                puts "EnergyGridUniqueBlobs::getBlobOrNull(nhash): blob not found".red
                puts JSON.pretty_generate(item).red
                exit 1
            end
            return
        end

        if item["mikuType"] == "Nx07" then
            return
        end

        if item["mikuType"] == "NxAnniversary" then
            return
        end

        if item["mikuType"] == "NxEvent" then
            FileSystemCheck::fsckNx111ExitAtFirstFailure(item, item["nx111"])
            return
        end

        if item["mikuType"] == "NxCollection" then
            return
        end

        if item["mikuType"] == "NxDataNode" then
            FileSystemCheck::fsckNx111ExitAtFirstFailure(item, item["nx111"])
            return
        end

        if item["mikuType"] == "NxFrame" then
            FileSystemCheck::fsckNx111ExitAtFirstFailure(item, item["nx111"])
            return
        end

        if item["mikuType"] == "NxPerson" then
            return
        end

        if item["mikuType"] == "NxLink" then
            return
        end

        if item["mikuType"] == "NxTask" then
            FileSystemCheck::fsckNx111ExitAtFirstFailure(item, item["nx111"])
            return
        end

        if item["mikuType"] == "NxTimeline" then
            return
        end

        if item["mikuType"] == "TxDated" then
            FileSystemCheck::fsckNx111ExitAtFirstFailure(item, item["nx111"])
            return
        end

        if item["mikuType"] == "TxProject" then
            FileSystemCheck::fsckNx111ExitAtFirstFailure(item, item["nx111"])
            return
        end

        if item["mikuType"] == "TxQueue" then
            return
        end

        if item["mikuType"] == "Wave" then
            FileSystemCheck::fsckNx111ExitAtFirstFailure(item, item["nx111"])
            return
        end

        puts JSON.pretty_generate(item).red
        raise "(error: a10f607b-4bc5-4ed2-ac31-dfd72c0108fc) unsupported mikuType: #{item["mikuType"]}"
    end

    # FileSystemCheck::fsck(shouldReset)
    def self.fsck(shouldReset)
        runHash = XCache::getOrNull("76001cea-f0c6-4e68-862b-5060d3c8bcd5")

        if runHash.nil? then
            runHash = SecureRandom.hex
            XCache::set("76001cea-f0c6-4e68-862b-5060d3c8bcd5", runHash)
        end

        if shouldReset then
            puts "resetting fsck runhash"
            sleep 1
            runHash = SecureRandom.hex
            XCache::set("76001cea-f0c6-4e68-862b-5060d3c8bcd5", runHash)
        end

        Librarian::objects().each{|item|
            exit if !File.exists?("/Users/pascal/Desktop/Pascal.png")
            next if XCache::getFlag("#{runHash}:#{JSON.generate(item)}")
            FileSystemCheck::fsckLibrarianMikuObjectExitAtFirstFailure(item, true)
            XCache::setFlag("#{runHash}:#{JSON.generate(item)}", true)
        }
        puts "fsck completed successfully".green
    end
end

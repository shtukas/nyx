
# encoding: UTF-8

require "/Users/pascal/Galaxy/LucilleOS/Libraries/Ruby-Libraries/LucilleCore.rb"

require "/Users/pascal/Galaxy/LucilleOS/Libraries/Ruby-Libraries/AionCore.rb"
=begin

The operator is an object that has meet the following signatures

    .commitBlob(blob: BinaryData) : Hash
    .filepathToContentHash(filepath) : Hash
    .readBlobErrorIfNotFound(nhash: Hash) : BinaryData
    .datablobCheck(nhash: Hash): Boolean

class Elizabeth

    def initialize()

    end

    def commitBlob(blob)
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

$LibrarianObjectsFileSystemCheck2_IamTypes = [
    "navigation",
    "log",
    "description-only",
    "text",
    "url",
    "aion-point",
    "unique-string",
    "primitive-file",
    "carrier-of-primitive-files",
    "Dx8Unit"
]

class LibrarianObjectsFileSystemCheck2

    # LibrarianObjectsFileSystemCheck2::fsckExitAtFirstFailureIamValue(object, nx111, operator)
    def self.fsckExitAtFirstFailureIamValue(object, nx111, operator)
        if !$LibrarianObjectsFileSystemCheck2_IamTypes.include?(nx111["type"]) then
            puts "object has an incorrect iam value type".red
            puts JSON.pretty_generate(object).red
            exit 1
        end
        if nx111["type"] == "navigation" then
            return
        end
        if nx111["type"] == "log" then
            return
        end
        if nx111["type"] == "description-only" then
            return
        end
        if nx111["type"] == "text" then
            nhash = nx111["nhash"]
            if operator.getBlobOrNull(nhash).nil? then
                puts "object, could not find the text data".red
                puts JSON.pretty_generate(object).red
                exit 1
            end
            return
        end
        if nx111["type"] == "url" then
            return
        end
        if nx111["type"] == "aion-point" then
            rootnhash = nx111["rootnhash"]
            status = AionFsck::structureCheckAionHash(operator, rootnhash)
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
        if nx111["type"] == "primitive-file" then
            dottedExtension = nx111["dottedExtension"]
            nhash = nx111["nhash"]
            parts = nx111["parts"]
            if dottedExtension[0, 1] != "." then
                puts "object".red
                puts JSON.pretty_generate(object).red
                puts "primitive parts, dotted extension is malformed".red
                exit 1
            end
            parts.each{|nhash|
                if operator.getBlobOrNull(nhash).nil? then
                    puts "object".red
                    puts JSON.pretty_generate(object).red
                    puts "primitive parts, nhash not found: #{nhash}".red
                    exit 1
                end
            }
            return
        end
        if nx111["type"] == "carrier-of-primitive-files" then
            return
        end
        if nx111["type"] == "Dx8Unit" then
            return if object["lxDeleted"]
            if File.exists?(Dx8UnitsUtils::infinityRepository()) then
                unitId = nx111["unitId"]
                location = Dx8UnitsUtils::dx8UnitFolder(unitId)
                puts "location: #{location}"
                status = File.exists?(location)
                if !status then
                    puts "could not find location".red
                    puts JSON.pretty_generate(object).red
                    exit 1
                end
                status = LucilleCore::locationsAtFolder(location).size == 1
                if !status then
                    puts "expecting only one file at location".red
                    puts JSON.pretty_generate(object).red
                    exit 1
                end
            else
                puts "(warning) Infinity drive not visible. Skipping full Dx8Unit check."
            end
            return
        end
        raise "(24500b54-9a88-4058-856a-a26b3901c23a: incorrect iam value: #{nx111})"
    end

    # LibrarianObjectsFileSystemCheck2::exitIfMissingCanary()
    def self.exitIfMissingCanary()
        if !File.exists?("/Users/pascal/Desktop/Pascal.png") then # We use this file to interrupt long runs at a place where it would not corrupt any file system.
            puts "Interrupted after missing canary file.".green
            exit
        end
    end

    # LibrarianObjectsFileSystemCheck2::fsckExitAtFirstFailureLibrarianMikuObject(item, operator)
    def self.fsckExitAtFirstFailureLibrarianMikuObject(item, operator)

        puts JSON.pretty_generate(item)

        if item["mikuType"] == "Lx21" then
            return
        end

        if item["mikuType"] == "Nx60" then
            return
        end

        if item["mikuType"] == "Nx100" then
            if item["iam"].nil? then
                puts "Nx100 has not iam value".red
                puts JSON.pretty_generate(item).red
                exit 1
            end
            puts JSON.pretty_generate(item["iam"])
            LibrarianObjectsFileSystemCheck2::fsckExitAtFirstFailureIamValue(item, item["iam"], operator)
            return
        end

        if item["mikuType"] == "TxAttachment" then
            LibrarianObjectsFileSystemCheck2::fsckExitAtFirstFailureIamValue(item, item["iam"], operator)
            return
        end

        if item["mikuType"] == "TxDated" then
            LibrarianObjectsFileSystemCheck2::fsckExitAtFirstFailureIamValue(item, item["iam"], operator)
            return
        end

        if item["mikuType"] == "TxFloat" then
            LibrarianObjectsFileSystemCheck2::fsckExitAtFirstFailureIamValue(item, item["iam"], operator)
            return
        end

        if item["mikuType"] == "TxFyre" then
            LibrarianObjectsFileSystemCheck2::fsckExitAtFirstFailureIamValue(item, item["iam"], operator)
            return
        end

        if item["mikuType"] == "TxInbox2" then
            if item["aionrootnhash"] then
                status = AionFsck::structureCheckAionHash(operator, item["aionrootnhash"])
                if !status then
                    puts "aionrootnhash does not validate".red
                    puts JSON.pretty_generate(item).red
                    exit 1
                end
            end
            return
        end

        if item["mikuType"] == "TxOS01" then
            LibrarianObjectsFileSystemCheck2::fsckExitAtFirstFailureLibrarianMikuObject(item["payload"], operator)
            return
        end

        if item["mikuType"] == "TxTodo" then
            LibrarianObjectsFileSystemCheck2::fsckExitAtFirstFailureIamValue(item, item["iam"], operator)
            return
        end

        if item["mikuType"] == "Wave" then
            LibrarianObjectsFileSystemCheck2::fsckExitAtFirstFailureIamValue(item, item["iam"], operator)
            return
        end

        if item["mikuType"] == "Ax1Text" then
            nhash = item["nhash"]
            begin
                operator.readBlobErrorIfNotFound(nhash)
            rescue
                puts "nhash, blob not found".red
                puts JSON.pretty_generate(item).red
                exit 1
            end
            return
        end

        puts JSON.pretty_generate(item).red
        raise "(error: a10f607b-4bc5-4ed2-ac31-dfd72c0108fc)"
    end
end

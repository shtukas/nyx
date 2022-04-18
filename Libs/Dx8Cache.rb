
=begin

We have an array of folders, corresponding to an array of integers.

THere are at most 50 folders (for storing to up 50 Gb). The first 20 folders are referring to as "low indces".

When putting a new block
    If the block already exists in a "low index folder" , we move it to a high index folder
    If the block doesn't exist , we move it to the last, or a new folder.

=end

class Dx8Cache

    # Dx8Cache::repositoryFolderPath()
    def self.repositoryFolderPath()
        "/Users/pascal/x-space/Librarian-Dx8-Cache"
    end

    # Dx8Cache::lowIndicesToHighIndicesThreshold()
    def self.lowIndicesToHighIndicesThreshold()
        20
    end

    # Dx8Cache::folderMaxCapacity()
    def self.folderMaxCapacity()
        1000 # Given up to 1Mb per file, that's about a Gb
    end

    # Dx8Cache::maxNumberOfFolders()
    def self.maxNumberOfFolders()
        50
    end

    # Dx8Cache::getIndices()
    def self.getIndices()
        indices = LucilleCore::locationsAtFolder(Dx8Cache::repositoryFolderPath()).map{|location| File.basename(location).to_i }
        if indices.size == 0 then
            folderpath = "#{Dx8Cache::repositoryFolderPath()}/0"
            FileUtils.mkdir(folderpath)
            return [0]
        end
        indices
    end

    # Dx8Cache::isLowIndexFolder(ix)
    def self.isLowIndexFolder(ix)
        Dx8Cache::getIndices().first(Dx8Cache::lowIndicesToHighIndicesThreshold()).include?(ix)
    end

    # Dx8Cache::getFileCountAtIndex(ix)
    def self.getFileCountAtIndex(ix)
        folderpath = "#{Dx8Cache::repositoryFolderPath()}/#{ix}"
        if !File.exists?(folderpath) then
            FileUtils.mkdir(folderpath)
        end
        LucilleCore::locationsAtFolder(folderpath).size
    end

    # Dx8Cache::getTheLastestIndexOrANewerOneIfFull()
    def self.getTheLastestIndexOrANewerOneIfFull()
        latestIndex = Dx8Cache::getIndices().max
        if Dx8Cache::getFileCountAtIndex(latestIndex) >= Dx8Cache::folderMaxCapacity() then
            latestIndex = latestIndex + 1
            folderpath = "#{Dx8Cache::repositoryFolderPath()}/#{latestIndex}"
            FileUtils.mkdir(folderpath)
        end
        latestIndex
    end

    # Dx8Cache::getIndexWhereThisHashAlreadyExistsOrNull(nhash)
    def self.getIndexWhereThisHashAlreadyExistsOrNull(nhash)
        Dx8Cache::getIndices().each{|ix1|
            folderpath1 = "#{Dx8Cache::repositoryFolderPath()}/#{ix1}"
            filepath1 = "#{folderpath1}/#{nhash}.data"
            return ix1 if File.exists?(filepath1)
        }
        nil
    end

    # -------------------------------------------------------

    # Dx8Cache::decideIndexFolderForPut(nhash)
    def self.decideIndexFolderForPut(nhash)
        if Dx8Cache::getIndices().size > Dx8Cache::maxNumberOfFolders() then
            ix = Dx8Cache::getIndices().min
            folderpath = "#{Dx8Cache::repositoryFolderPath()}/#{ix}"
            LucilleCore::removeFileSystemLocation(folderpath)
        end
        ix1 = Dx8Cache::getIndexWhereThisHashAlreadyExistsOrNull(nhash)
        if ix1 then
            if Dx8Cache::isLowIndexFolder(ix1) then
                ix2 = Dx8Cache::getTheLastestIndexOrANewerOneIfFull()
                filepath2 = "#{Dx8Cache::repositoryFolderPath()}/#{ix2}/#{nhash}.data"
                FileUtils.mv(filepath1, filepath2)
                return ix2
            end
        else
            Dx8Cache::getTheLastestIndexOrANewerOneIfFull()
        end
    end

    # Dx8Cache::decideIndexForGetOrNull(nhash)
    def self.decideIndexForGetOrNull(nhash)
        Dx8Cache::getIndices().each{|ix1|
            folderpath1 = "#{Dx8Cache::repositoryFolderPath()}/#{ix1}"
            filepath1 = "#{folderpath1}/#{nhash}.data"
            next if !File.exists?(filepath1)
            # Before we return this, we just need to make sure that it's not the last folder otherwise we need to move the blob
            if Dx8Cache::isLowIndexFolder(ix1) then
                ix2 = Dx8Cache::getTheLastestIndexOrANewerOneIfFull()
                if ix2 != ix1 then
                    filepath2 = "#{Dx8Cache::repositoryFolderPath()}/#{ix2}/#{nhash}.data"
                    FileUtils.mv(filepath1, filepath2)
                    return ix2
                end
            end
            return ix1
        }
        nil
    end

    # -------------------------------------------------------

    # Dx8Cache::putBlob(blob)
    def self.putBlob(blob)
        nhash = "SHA256-#{Digest::SHA256.hexdigest(blob)}"
        ix = Dx8Cache::decideIndexFolderForPut(nhash)
        filepath = "#{Dx8Cache::repositoryFolderPath()}/#{ix}/#{nhash}.data"
        if !File.exists?(File.dirname(filepath)) then
            FileUtils.mkpath(File.dirname(filepath))
        end
        File.open(filepath, "w"){|f| f.write(blob) }
        nhash
    end

    # Dx8Cache::getBlobOrNull(nhash)
    def self.getBlobOrNull(nhash)
        ix = Dx8Cache::decideIndexForGetOrNull(nhash)
        return nil if ix.nil?
        filepath = "#{Dx8Cache::repositoryFolderPath()}/#{ix}/#{nhash}.data"
        if File.exists?(filepath) then
            blob = IO.read(filepath)
            return blob
        end
        nil
    end
end

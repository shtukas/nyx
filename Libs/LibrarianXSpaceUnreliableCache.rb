
=begin

We have an array of folders, corresponding to an array of indices.

An index is an element of the form 2022-04-10-114509310072, meaning a date time to microseconds.

When we read a block
    - If the block is read from today, we keep it in place, and return
    - If the block is read from a past day, we move it to today, and return

When we write a block
    - that has not been written, we write it at today (actually the latest folder, possibly creating a new one to avoid overflowed)
    - that has been written, we move it to today, before we rewrite it

We keep up to 50 folders (with a 1000 folder capacity; 50Gb), but we do not delete folders less than 48 hours old

=end

class LibrarianXSpaceUnreliableCache

    # LibrarianXSpaceUnreliableCache::repositoryFolderPath()
    def self.repositoryFolderPath()
        "/Users/pascal/x-space/Librarian-Cache-1-F35E"
    end

    # LibrarianXSpaceUnreliableCache::folderMaxCapacity()
    def self.folderMaxCapacity()
        1000
    end

    # LibrarianXSpaceUnreliableCache::repositoryMaxCapacityInGb()
    def self.repositoryMaxCapacityInGb()
        20
    end

    # LibrarianXSpaceUnreliableCache::generateNewIndex()
    def self.generateNewIndex()
        idx = "#{Time.new.to_s[0, 10]}-#{Time.new.strftime("%H%M%S%6N")}"
    end

    # LibrarianXSpaceUnreliableCache::getIndices()
    def self.getIndices()
        indices = LucilleCore::locationsAtFolder(LibrarianXSpaceUnreliableCache::repositoryFolderPath()).map{|location| File.basename(location)}
        if indices.size == 0 then
            idx = LibrarianXSpaceUnreliableCache::generateNewIndex()
            folderpath = "#{LibrarianXSpaceUnreliableCache::repositoryFolderPath()}/#{idx}"
            FileUtils.mkdir(folderpath)
            return [idx]
        end
        if indices.size > 50 then

        end
        indices
    end

    # LibrarianXSpaceUnreliableCache::indexIsToday(indx)
    def self.indexIsToday(indx)
        indx[0, 10] == Time.new.to_s[0, 10]
    end

    # LibrarianXSpaceUnreliableCache::getFileCountAtIndex(ix)
    def self.getFileCountAtIndex(ix)
        folderpath = "#{LibrarianXSpaceUnreliableCache::repositoryFolderPath()}/#{ix}"
        LucilleCore::locationsAtFolder(folderpath).size
    end

    # LibrarianXSpaceUnreliableCache::getTheLastestIndexOrANewerOneIfFullEnsureToday()
    def self.getTheLastestIndexOrANewerOneIfFullEnsureToday()
        latestIndex = LibrarianXSpaceUnreliableCache::getIndices().max

        if latestIndex[0, 10] != Time.new.to_s[0, 10] then
            latestIndex = LibrarianXSpaceUnreliableCache::generateNewIndex()
            folderpath = "#{LibrarianXSpaceUnreliableCache::repositoryFolderPath()}/#{latestIndex}"
            FileUtils.mkdir(folderpath)
        end

        if LibrarianXSpaceUnreliableCache::getFileCountAtIndex(latestIndex) >= LibrarianXSpaceUnreliableCache::folderMaxCapacity() then
            latestIndex = LibrarianXSpaceUnreliableCache::generateNewIndex()
            folderpath = "#{LibrarianXSpaceUnreliableCache::repositoryFolderPath()}/#{latestIndex}"
            FileUtils.mkdir(folderpath)
        end

        latestIndex
    end

    # -------------------------------------------------------

    # LibrarianXSpaceUnreliableCache::getFilepathForPut(nhash)
    def self.getFilepathForPut(nhash)
        filepath = nil
        
        # Checking if the blob is already in repository
        
        LibrarianXSpaceUnreliableCache::getIndices().each{|ix1|
            filepath1 = "#{LibrarianXSpaceUnreliableCache::repositoryFolderPath()}/#{ix1}/#{nhash}.data"
            if File.exists?(filepath1) then
                filepath = filepath1
            end
        }

        # If the filepath was null (no occurence of the blob), we make a new one
        
        if filepath.nil? then
            ix2 = LibrarianXSpaceUnreliableCache::getTheLastestIndexOrANewerOneIfFullEnsureToday()
            filepath = "#{LibrarianXSpaceUnreliableCache::repositoryFolderPath()}/#{ix2}/#{nhash}.data"
        end

        # Let's check in the path points at today
        # If it doesn't we make a today one and if a blob already existed, we move it

        if !LibrarianXSpaceUnreliableCache::indexIsToday(File.basename(File.dirname(filepath))) then
            ix2 = LibrarianXSpaceUnreliableCache::getTheLastestIndexOrANewerOneIfFullEnsureToday()
            filepath2 = "#{LibrarianXSpaceUnreliableCache::repositoryFolderPath()}/#{ix2}/#{nhash}.data"
            if File.exists?(filepath) then
                FileUtils.mv(filepath, filepath2)
                filepath = filepath2
            end
        end

        filepath
    end

    # LibrarianXSpaceUnreliableCache::getFilepathForGetOrNull(nhash)
    def self.getFilepathForGetOrNull(nhash)

        filepath = nil

        LibrarianXSpaceUnreliableCache::getIndices().each{|ix1|
            filepath1 = "#{LibrarianXSpaceUnreliableCache::repositoryFolderPath()}/#{ix1}/#{nhash}.data"
            if File.exists?(filepath1) then
                filepath = filepath1
            end
        }

        # Let's check in the path points at today
        # If it doesn't we make a today one and if a blob already existed, we move it

        if filepath and !LibrarianXSpaceUnreliableCache::indexIsToday(File.basename(File.dirname(filepath))) then
            ix2 = LibrarianXSpaceUnreliableCache::getTheLastestIndexOrANewerOneIfFullEnsureToday()
            filepath2 = "#{LibrarianXSpaceUnreliableCache::repositoryFolderPath()}/#{ix2}/#{nhash}.data"
            if File.exists?(filepath) then
                FileUtils.mv(filepath, filepath2)
                filepath = filepath2
            end
        end

        filepath
    end

    # -------------------------------------------------------

    # LibrarianXSpaceUnreliableCache::putBlob(blob)
    def self.putBlob(blob)
        nhash = "SHA256-#{Digest::SHA256.hexdigest(blob)}"
        filepath = LibrarianXSpaceUnreliableCache::getFilepathForPut(nhash)
        if !File.exists?(File.dirname(filepath)) then
            FileUtils.mkpath(File.dirname(filepath))
        end
        File.open(filepath, "w"){|f| f.write(blob) }
        nhash
    end

    # LibrarianXSpaceUnreliableCache::getBlobOrNull(nhash)
    def self.getBlobOrNull(nhash)
        filepath = LibrarianXSpaceUnreliableCache::getFilepathForGetOrNull(nhash)
        return nil if filepath.nil?
        if File.exists?(filepath) then
            blob = IO.read(filepath)

            # -------------------------------------------------------------
            # I put the following check in place because 
            # both LibrarianXSpaceUnreliableCache::getFilepathForPut and LibrarianXSpaceUnreliableCache::getFilepathForGetOrNull
            # move files and better safe than sorry

            if nhash != "SHA256-#{Digest::SHA256.hexdigest(blob)}" then
                raise "(error: 0b8fb33e-9fab-4c7c-b14f-e418d678c720) This should never happen!"
            end
            # -------------------------------------------------------------

            return blob
        end
        nil
    end
end

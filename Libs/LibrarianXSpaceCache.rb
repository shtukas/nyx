
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

class LibrarianXSpaceCache

    # LibrarianXSpaceCache::repositoryFolderPath()
    def self.repositoryFolderPath()
        "/Users/pascal/x-space/Librarian-Cache-1-F35E"
    end

    # LibrarianXSpaceCache::folderMaxCapacity()
    def self.folderMaxCapacity()
        1000
    end

    # LibrarianXSpaceCache::repositoryMaxCapacityInGb()
    def self.repositoryMaxCapacityInGb()
        20
    end

    # LibrarianXSpaceCache::generateNewIndex()
    def self.generateNewIndex()
        idx = "#{Time.new.to_s[0, 10]}-#{Time.new.strftime("%H%M%S%6N")}"
    end

    # LibrarianXSpaceCache::getIndices()
    def self.getIndices()
        indices = LucilleCore::locationsAtFolder(LibrarianXSpaceCache::repositoryFolderPath()).map{|location| File.basename(location)}
        if indices.size == 0 then
            idx = LibrarianXSpaceCache::generateNewIndex()
            folderpath = "#{LibrarianXSpaceCache::repositoryFolderPath()}/#{idx}"
            FileUtils.mkdir(folderpath)
            return [idx]
        end
        if indices.size > 50 then

        end
        indices
    end

    # LibrarianXSpaceCache::indexIsToday(indx)
    def self.indexIsToday(indx)
        indx[0, 10] == Time.new.to_s[0, 10]
    end

    # LibrarianXSpaceCache::getFileCountAtIndex(ix)
    def self.getFileCountAtIndex(ix)
        folderpath = "#{LibrarianXSpaceCache::repositoryFolderPath()}/#{ix}"
        LucilleCore::locationsAtFolder(folderpath).size
    end

    # LibrarianXSpaceCache::getTheLastestIndexOrANewerOneIfFullEnsureToday()
    def self.getTheLastestIndexOrANewerOneIfFullEnsureToday()
        latestIndex = LibrarianXSpaceCache::getIndices().max

        if latestIndex[0, 10] != Time.new.to_s[0, 10] then
            latestIndex = LibrarianXSpaceCache::generateNewIndex()
            folderpath = "#{LibrarianXSpaceCache::repositoryFolderPath()}/#{latestIndex}"
            FileUtils.mkdir(folderpath)
        end

        if LibrarianXSpaceCache::getFileCountAtIndex(latestIndex) >= LibrarianXSpaceCache::folderMaxCapacity() then
            latestIndex = LibrarianXSpaceCache::generateNewIndex()
            folderpath = "#{LibrarianXSpaceCache::repositoryFolderPath()}/#{latestIndex}"
            FileUtils.mkdir(folderpath)
        end

        latestIndex
    end

    # -------------------------------------------------------

    # LibrarianXSpaceCache::getFilepathForPut(nhash)
    def self.getFilepathForPut(nhash)
        filepath = nil
        
        # Checking if the blob is already in repository
        
        LibrarianXSpaceCache::getIndices().each{|ix1|
            filepath1 = "#{LibrarianXSpaceCache::repositoryFolderPath()}/#{ix1}/#{nhash}.data"
            if File.exists?(filepath1) then
                filepath = filepath1
            end
        }

        # If the filepath was null (no occurence of the blob), we make a new one
        
        if filepath.nil? then
            ix2 = LibrarianXSpaceCache::getTheLastestIndexOrANewerOneIfFullEnsureToday()
            filepath = "#{LibrarianXSpaceCache::repositoryFolderPath()}/#{ix2}/#{nhash}.data"
        end

        # Let's check in the path points at today
        # If it doesn't we make a today one and if a blob already existed, we move it

        if !LibrarianXSpaceCache::indexIsToday(File.basename(File.dirname(filepath))) then
            ix2 = LibrarianXSpaceCache::getTheLastestIndexOrANewerOneIfFullEnsureToday()
            filepath2 = "#{LibrarianXSpaceCache::repositoryFolderPath()}/#{ix2}/#{nhash}.data"
            if File.exists?(filepath) then
                FileUtils.mv(filepath, filepath2)
                filepath = filepath2
            end
        end

        filepath
    end

    # LibrarianXSpaceCache::getFilepathForGetOrNull(nhash)
    def self.getFilepathForGetOrNull(nhash)

        filepath = nil

        LibrarianXSpaceCache::getIndices().each{|ix1|
            filepath1 = "#{LibrarianXSpaceCache::repositoryFolderPath()}/#{ix1}/#{nhash}.data"
            if File.exists?(filepath1) then
                filepath = filepath1
            end
        }

        # Let's check in the path points at today
        # If it doesn't we make a today one and if a blob already existed, we move it

        if filepath and !LibrarianXSpaceCache::indexIsToday(File.basename(File.dirname(filepath))) then
            ix2 = LibrarianXSpaceCache::getTheLastestIndexOrANewerOneIfFullEnsureToday()
            filepath2 = "#{LibrarianXSpaceCache::repositoryFolderPath()}/#{ix2}/#{nhash}.data"
            if File.exists?(filepath) then
                FileUtils.mv(filepath, filepath2)
                filepath = filepath2
            end
        end

        filepath
    end

    # -------------------------------------------------------

    # LibrarianXSpaceCache::putBlob(blob)
    def self.putBlob(blob)
        nhash = "SHA256-#{Digest::SHA256.hexdigest(blob)}"
        filepath = LibrarianXSpaceCache::getFilepathForPut(nhash)
        if !File.exists?(File.dirname(filepath)) then
            FileUtils.mkpath(File.dirname(filepath))
        end
        File.open(filepath, "w"){|f| f.write(blob) }
        nhash
    end

    # LibrarianXSpaceCache::getBlobOrNull(nhash)
    def self.getBlobOrNull(nhash)
        filepath = LibrarianXSpaceCache::getFilepathForGetOrNull(nhash)
        return nil if filepath.nil?
        if File.exists?(filepath) then
            blob = IO.read(filepath)

            # -------------------------------------------------------------
            # I put the following check in place because 
            # both LibrarianXSpaceCache::getFilepathForPut and LibrarianXSpaceCache::getFilepathForGetOrNull
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

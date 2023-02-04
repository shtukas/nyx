
# encoding: UTF-8

class NyxDirectories

    # --------------------------------------------------------

    # NyxDirectories::directoryPath(directoryId)
    def self.directoryPath(directoryId)
        "#{Nyx::pathToNyx()}/Directories/#{directoryId}"
    end

    # NyxDirectories::access(directoryId)
    def self.access(directoryId)
        folderpath = NyxDirectories::directoryPath(directoryId)
        if !File.exist?(folderpath) then
            puts "There is not nyx directory for directoryId: #{directoryId}"
            LucilleCore::pressEnterToContinue()
            return
        end
        system("open '#{folderpath}'")
        LucilleCore::pressEnterToContinue()
    end

    # NyxDirectories::makeNew(directoryId) # folderpath
    def self.makeNew(directoryId)
        folderpath = NyxDirectories::directoryPath(directoryId)
        if !File.exist?(folderpath) then
            FileUtils.mkdir(folderpath)
        end
        folderpath
    end
end

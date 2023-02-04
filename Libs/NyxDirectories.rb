
# encoding: UTF-8

class NyxDirectories

    # --------------------------------------------------------

    # NyxDirectories::nyxDirectoryPath(directoryId)
    def self.nyxDirectoryPath(directoryId)
        "#{Nyx::pathToNyx()}/Directories/#{directoryId}"
    end

    # NyxDirectories::accessNyxDirectory(directoryId)
    def self.accessNyxDirectory(directoryId)
        folderpath = NyxDirectories::nyxDirectoryPath(directoryId)
        if !File.exist?(folderpath) then
            puts "There is not nyx directory for directoryId: #{directoryId}"
            LucilleCore::pressEnterToContinue()
            return
        end
        system("open '#{folderpath}'")
        LucilleCore::pressEnterToContinue()
    end

    # NyxDirectories::makeNewDirectory(directoryId) # folderpath
    def self.makeNewDirectory(directoryId)
        folderpath = NyxDirectories::nyxDirectoryPath(directoryId)
        if !File.exist?(folderpath) then
            FileUtils.mkdir(folderpath)
        end
        folderpath
    end
end

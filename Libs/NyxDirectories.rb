
# encoding: UTF-8

class NyxDirectories

    # --------------------------------------------------------

    # NyxDirectories::nyxDirectoryPath(uuid)
    def self.nyxDirectoryPath(uuid)
        "#{Nyx::pathToNyx()}/Directories/#{uuid}"
    end

    # NyxDirectories::accessNyxDirectory(uuid)
    def self.accessNyxDirectory(uuid)
        folderpath = NyxDirectories::nyxDirectoryPath(uuid)
        if !File.exist?(folderpath) then
            puts "There is not nyx directory for uuid: #{uuid}"
            LucilleCore::pressEnterToContinue()
            return
        end
        system("open '#{folderpath}'")
        LucilleCore::pressEnterToContinue()
    end

    # NyxDirectories::makeNewDirectory(uuid) # folderpath
    def self.makeNewDirectory(uuid)
        folderpath = NyxDirectories::nyxDirectoryPath(uuid)
        if !File.exist?(folderpath) then
            FileUtils.mkdir(folderpath)
        end
        folderpath
    end
end

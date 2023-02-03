
# encoding: UTF-8

class Desktop

    # Desktop::desktopFolderPath()
    def self.desktopFolderPath()
        "#{Config::pathToDataCenter()}/Desktop"
    end

    # Desktop::filepathOrNull()
    def self.filepathOrNull()
        filepath = "#{Desktop::desktopFolderPath()}/desktop.txt"
        File.exist?(filepath) ? filepath : nil
    end

    # Desktop::contentsOrNull()
    def self.contentsOrNull()
        filepath = Desktop::filepathOrNull()
        if filepath then
            IO.read(Desktop::filepathOrNull()).lines.first(10).join().strip
        else
            nil
        end
        
    end
end

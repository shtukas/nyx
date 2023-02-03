
# encoding: UTF-8

class Desktop

    # Desktop::desktopFolderPath()
    def self.desktopFolderPath()
        "#{Config::pathToDataCenter()}/Desktop"
    end

    # Desktop::filepaths()
    def self.filepaths()
        LucilleCore::locationsAtFolder("#{Config::pathToDataCenter()}/Desktop")
            .select{|filepath| filepath[-4, 4] == ".txt" }
    end

    # Desktop::contents()
    def self.contents()
        Desktop::filepaths()
            .map{|filepath| IO.read(filepath)}
            .join("\n\n")
            .strip
    end

end

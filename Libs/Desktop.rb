
# encoding: UTF-8

class Desktop

    # Desktop::desktopFolderPath()
    def self.desktopFolderPath()
        "#{Config::pathToDataCenter()}/Desktop"
    end

    # Desktop::filepath()
    def self.filepath()
        "#{Desktop::desktopFolderPath()}/desktop.txt"
    end

    # Desktop::contents()
    def self.contents()
        IO.read(Desktop::filepath()).lines.first(10).join().strip
    end
end

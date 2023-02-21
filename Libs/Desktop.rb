
# encoding: UTF-8

class Desktop

    # Desktop::filepath()
    def self.filepath()
        "#{Config::pathToDataCenter()}/desktop.txt"
    end

    # Desktop::contents()
    def self.contents()
        IO.read(Desktop::filepath()).lines.first(10).join().strip
    end
end

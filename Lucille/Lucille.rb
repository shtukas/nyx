
# encoding: UTF-8

require 'fileutils'
# FileUtils.mkpath '/a/b/c'
# FileUtils.cp(src, dst)
# FileUtils.mv 'oldname', 'newname'
# FileUtils.rm(path_to_image)
# FileUtils.rm_rf('dir/to/remove')


class Lucille

    # Lucille::applyNextTransformationToContent(content)
    def self.applyNextTransformationToContent(content)

        positionOfFirstNonSpaceCharacter = lambda{|line, size|
            return (size-1) if !line.start_with?(" " * size)
            positionOfFirstNonSpaceCharacter.call(line, size+1)
        }

        lines = content.strip.lines.to_a
        return content if lines.empty?
        slineWithIndex = lines
            .reject{|line| line.strip == "" }
            .each_with_index
            .map{|line, i| [line, i] }
            .reduce(nil) {|selectedLineWithIndex, cursorLineWithIndex|
                if selectedLineWithIndex.nil? then
                    cursorLineWithIndex
                else
                    if (positionOfFirstNonSpaceCharacter.call(selectedLineWithIndex.first, 1) < positionOfFirstNonSpaceCharacter.call(cursorLineWithIndex.first, 1)) and (selectedLineWithIndex[1] == cursorLineWithIndex[1]-1) then
                        cursorLineWithIndex
                    else
                        selectedLineWithIndex
                    end
                end
            }
        sline = slineWithIndex.first
        lines
            .reject{|line| line == sline }
            .join()
            .strip
    end

    # Lucille::garbageCollection()
    def self.garbageCollection()
        Lucille::locations()
            .each{|location|
                next if location[-4, 4] != ".txt"
                content = IO.read(location)
                next if content.nil?
                next if content.strip.size > 0
                FileUtils.rm(location)
            }
    end

    # Lucille::timeStringL22()
    def self.timeStringL22()
        "#{Time.new.strftime("%Y%m%d-%H%M%S-%6N")}"
    end

    # Lucille::ensurel22Filenames()
    def self.ensurel22Filenames()
        Lucille::locations()
            .each{|location|
                next if File.basename(location)[0, 3] == "202"
                location2 = "#{File.dirname(location)}/#{Lucille::timeStringL22()} #{File.basename(location)}"
                FileUtils.mv(location, location2)
            }
    end

    # Lucille::locations()
    def self.locations()
        Dir.entries("/Users/pascal/Galaxy/DataBank/Catalyst/Lucille/Items")
            .reject{|filename| filename[0, 1] == "." }
            .sort
            .map{|filename| "/Users/pascal/Galaxy/DataBank/Catalyst/Lucille/Items/#{filename}" }
    end

    # Lucille::locationToItem(location)
    def self.locationToItem(location)
        if location[-4, 4] == ".txt" then
            {
                "type" => "text",
                "content" => IO.read(location).strip
            }
        else
            {
                "type" => "location",
                "location" => location
            }
        end
    end

    # Lucille::deleteLucilleLocation(location)
    def self.deleteLucilleLocation(location)
        LucilleCore::removeFileSystemLocation(location)
        location2 = "/Users/pascal/Desktop/#{File.basename(location)}"
        if File.exists?(location2) then
            LucilleCore::removeFileSystemLocation(location2)
        end
    end
end







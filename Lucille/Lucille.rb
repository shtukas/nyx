
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
        Lucille::itemsFilepaths()
            .each{|filepath|
                content = IO.read(filepath)
                next if content.nil?
                next if content.strip.size > 0
                FileUtils.rm(filepath)
            }
    end

    # Lucille::itemsFilepaths()
    def self.itemsFilepaths()
        Dir.entries("/Users/pascal/Galaxy/DataBank/Catalyst/Lucille/Items")
            .reject{|filename| filename[0, 1] == "." }
            .sort
            .map{|filename| "/Users/pascal/Galaxy/DataBank/Catalyst/Lucille/Items/#{filename}" }
    end
end







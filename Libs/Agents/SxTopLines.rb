# encoding: UTF-8

class SxTopLines

    # SxTopLines::lineToUuid(line)
    def self.lineToUuid(line)
        Digest::SHA1.hexdigest("216B44F4-61DF-4549-81C9-54673FF950EB:#{Utils::today()}:#{line}")
    end

    # SxTopLines::catalystTxtNs16s()
    def self.catalystTxtNs16s()
        text = IO.read("/Users/pascal/Desktop/Top&Lines.txt")
        SectionsType0141::contentToSections(text)
            .map{|text| text.strip }
            .select{|text| text.size > 0 }
            .select{|text| text.lines.size == 1 }
            .map{|line|
                line = line.strip
                uuid = SxTopLines::lineToUuid(line)
                {
                    "uuid"        => uuid,
                    "NS198"       => "NS16:SxTopLines",
                    "announce"    => "(line) #{line}",
                    "commands"    => [".." , "done", "''"],
                    "line"        => line
                }
            }
    end

    # SxTopLines::rewriteSxTopLinesFileWithoutThisLine(line)
    def self.rewriteSxTopLinesFileWithoutThisLine(line)
        filepath = "/Users/pascal/Desktop/Top&Lines.txt"
        Utils::copyFileToBinTimeline(filepath)
        contents = IO.read(filepath)
        contents = contents.lines.reject{|l| l.strip == line }.join()
        File.open(filepath, "w"){|f| f.write(contents) }
    end
end



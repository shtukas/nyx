# encoding: UTF-8

class CatalystTxt

    # CatalystTxt::catalystTxtNs16s()
    def self.catalystTxtNs16s()
        IO.read("/Users/pascal/Desktop/Catalyst.txt")
            .strip
            .lines
            .select{|line| line.strip.size > 0 }
            .take_while{|line| !line.include?("@excluded:") }
            .map{|line|
                line = line.strip
                uuid = Digest::SHA1.hexdigest("216B44F4-61DF-4549-81C9-54673FF950EB:#{line}")
                {
                    "uuid"        => uuid,
                    "NS198"       => "Catalyst.txt:NS16",
                    "announce"    => "(catalyst.txt) #{line}",
                    "commands"    => [".." , "done"],
                    "line"        => line
                }
            }
    end

    # CatalystTxt::rewriteCatalystTxtFileWithoutThisLine(line)
    def self.rewriteCatalystTxtFileWithoutThisLine(line)
        filepath = "/Users/pascal/Desktop/Catalyst.txt"
        contents = IO.read(filepath)
        contents = contents.lines.reject{|l| l.strip == line }.join()
        File.open(filepath, "w"){|f| f.write(contents) }
    end
end



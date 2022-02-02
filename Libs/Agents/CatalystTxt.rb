# encoding: UTF-8

class CatalystTxt

    # CatalystTxt::lineToUuid(line)
    def self.lineToUuid(line)
        Digest::SHA1.hexdigest("216B44F4-61DF-4549-81C9-54673FF950EB:#{Utils::today()}:#{line}")
    end

    # CatalystTxt::getCachedDomainForLine(line)
    def self.getCachedDomainForLine(line)
        domain = KeyValueStore::getOrNull(nil, "f6985886-364d-48c1-aabd-70a16c81c6ab:#{line}")
        return domain if domain
        puts "mising domain for: #{line}"
        domain = DomainsX::interactivelySelectDomainX()
        KeyValueStore::set(nil, "f6985886-364d-48c1-aabd-70a16c81c6ab:#{line}", domain)
        domain
    end

    # CatalystTxt::catalystTxtNs16s()
    def self.catalystTxtNs16s()
        focus = DomainsX::focusOrNull()

        IO.read("/Users/pascal/Desktop/Catalyst.txt")
            .strip
            .lines
            .select{|line| line.strip.size > 0 }
            .take_while{|line| !line.include?("@excluded:") }
            .map{|line|
                line = line.strip
                domainx = CatalystTxt::getCachedDomainForLine(line)
                uuid = CatalystTxt::lineToUuid(line)
                {
                    "uuid"        => uuid,
                    "NS198"       => "NS16:CatalystTxt",
                    "announce"    => "(ct.txt) #{line}",
                    "commands"    => [".." , "done", "''"],
                    "line"        => line,
                    "domainx"     => domainx
                }
            }
            .select{|ns16| focus.nil? or (ns16["domainx"] == focus) }
    end

    # CatalystTxt::rewriteCatalystTxtFileWithoutThisLine(line)
    def self.rewriteCatalystTxtFileWithoutThisLine(line)
        filepath = "/Users/pascal/Desktop/Catalyst.txt"
        Utils::copyFileToBinTimeline(filepath)
        contents = IO.read(filepath)
        contents = contents.lines.reject{|l| l.strip == line }.join()
        File.open(filepath, "w"){|f| f.write(contents) }
    end
end



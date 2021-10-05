# encoding: UTF-8

class DomainPriorityFile

    # DomainPriorityFile::applyNextTransformation(filepath)
    def self.applyNextTransformation(filepath)
        contents = IO.read(filepath)
        return if contents.strip == ""
        contents = SectionsType0141::applyNextTransformationToText(contents)
        File.open(filepath, "w"){|f| f.puts(contents)}
    end

    # DomainPriorityFile::catalystSafe(filepath)
    def self.catalystSafe(filepath)
        FileUtils.cp(filepath, "/Users/pascal/x-space/catalyst-safe/#{LucilleCore::timeStringL22()}-#{File.basename(filepath)}")
    end

    # DomainPriorityFile::moveRecastSectionAsNx50(filepath, section, domain)
    def self.moveRecastSectionAsNx50(filepath, section, domain)
        DomainPriorityFile::catalystSafe(filepath)
        dx = Domains::interactivelySelectDomainOrNull() || domain
        unixtime = Nx50s::interactivelyDetermineNewItemUnixtime(dx)
        item = Nx50s::issueNx50UsingText(section.strip, unixtime, dx)
        puts JSON.pretty_generate(item)
        text = IO.read(filepath)
        text = text.gsub(section, "")
        File.open(filepath, "w"){|f| f.puts(text) }
    end

    # DomainPriorityFile::run(item, section, domain)
    def self.run(item, section, domain)

        filepath = item["filepath"]

        nxball = NxBalls::makeNxBall([item["bankaccount"]].compact)

        thr = Thread.new {
            loop {
                sleep 60

                if (Time.new.to_i - nxball["cursorUnixtime"]) >= 600 then
                    nxball = NxBalls::upgradeNxBall(nxball, false)
                end

                if (Time.new.to_i - nxball["startUnixtime"]) >= 3600 then
                    Utils::onScreenNotification("Catalyst", "Priority file section running for more than an hour")
                end
            }
        }

        loop {
            accessedit = lambda{|filepath, section|
                DomainPriorityFile::catalystSafe(filepath)
                section2 = Utils::editTextSynchronously(section)
                if section2 != section then
                    File.open(filepath, "w"){|f| f.puts(IO.read(filepath).gsub(section, section2)) }
                end
                section2
            }

            system("clear")

            break if section.strip.size == 0

            puts ""
            puts section.green
            puts ""
            puts "access (default) | [] | >Nx50 | exit".yellow
            command = LucilleCore::askQuestionAnswerAsString("> ")

            if command == "" then
                section = accessedit.call(filepath, section)
                next
            end

            if command == "exit" then
                break
            end

            if command == "[]" then
                DomainPriorityFile::catalystSafe(filepath)
                section2 = SectionsType0141::applyNextTransformationToText(section) + "\n"
                text = IO.read(filepath)
                text = text.gsub(section, section2)
                File.open(filepath, "w"){|f| f.puts(text) }
                section = section2
                next
            end

            if command == ">Nx50" then
                DomainPriorityFile::moveRecastSectionAsNx50(filepath, section, domain)
                break
            end

            if Interpreting::match("access", command) then
                section = accessedit.call(filepath, section)
                next
            end
        }

        thr.exit

        NxBalls::closeNxBall(nxball, true)
    end

    # DomainPriorityFile::itemToNS16s(item, domain)
    def self.itemToNS16s(item, domain)
        filepath = item["filepath"]
        text = IO.read(filepath)
        sections = SectionsType0141::contentToSections(text)

        shiftText = lambda{|text|
            line = text.lines.first
            lines = text.lines.drop(1)
            line + lines.map{|line| "      #{line}" }.join()
        }

        sections.map{|section|
            sectionSmall = section.strip
            {
                "uuid"        => Digest::SHA1.hexdigest("6a212fa7-ccbb-461d-8204-9f22a9713d55:#{section}:#{Utils::today()}"),
                "domain"      => item["domain"],
                "announce"    => (sectionSmall.lines.size == 1) ? sectionSmall.green : shiftText.call(sectionSmall).green,
                "commands"    => ["..", "[]", ">Nx50"],
                "interpreter" => lambda{|command|
                    if command == ".." then
                        DomainPriorityFile::run(item, section, domain)
                    end
                    if command == "[]" then
                        DomainPriorityFile::catalystSafe(filepath)
                        section2 = SectionsType0141::applyNextTransformationToText(section) + "\n"
                        text = IO.read(filepath)
                        text = text.gsub(section, section2)
                        File.open(filepath, "w"){|f| f.puts(text) }
                    end
                    if command == ">Nx50" then
                        DomainPriorityFile::moveRecastSectionAsNx50(filepath, section, domain)
                    end
                },
                "run" => lambda {
                    DomainPriorityFile::run(item, section, domain)
                }
            }
        }
    end

    # DomainPriorityFile::ns16s2()
    def self.ns16s2()
        domain = Domains::getCurrentActiveDomain()
        Domains::items()
            .select{|item| item["domain"] == domain }
            .map{|item| DomainPriorityFile::itemToNS16s(item, domain) }
            .flatten
    end
end

# encoding: UTF-8

class PriorityFile

    # PriorityFile::applyNextTransformation(filepath)
    def self.applyNextTransformation(filepath)
        contents = IO.read(filepath)
        return if contents.strip == ""
        contents = SectionsType0141::applyNextTransformationToText(contents)
        File.open(filepath, "w"){|f| f.puts(contents)}
    end

    # PriorityFile::catalystSafe(filepath)
    def self.catalystSafe(filepath)
        targetFilePath = "/Users/pascal/x-space/catalyst-safe/#{Time.new.to_s[0, 4]}/#{Time.new.to_s[0, 7]}/#{LucilleCore::timeStringL22()}-#{File.basename(filepath)}"
        if !File.exists?(File.dirname(targetFilePath)) then
            FileUtils.mkpath(File.dirname(targetFilePath))
        end
        FileUtils.cp(filepath, targetFilePath)
    end

    # PriorityFile::recastSectionAsOndate(filepath, section)
    def self.recastSectionAsOndate(filepath, section)
        PriorityFile::catalystSafe(filepath)
        date = NxOnDate::interactivelySelectADateOrNull()
        return if date.nil?
        item = NxOnDate::issueItemUsingText(section.strip, Time.new.to_i, date)
        puts JSON.pretty_generate(item)
        text = IO.read(filepath)
        text = text.gsub(section, "")
        File.open(filepath, "w"){|f| f.puts(text) }
    end

    # PriorityFile::recastSectionAsNx50(filepath, section)
    def self.recastSectionAsNx50(filepath, section)
        PriorityFile::catalystSafe(filepath)
        unixtime = Nx50s::interactivelyDetermineNewItemUnixtime()
        item = Nx50s::issueItemUsingText(section.strip, unixtime)
        puts JSON.pretty_generate(item)
        text = IO.read(filepath)
        text = text.gsub(section, "")
        File.open(filepath, "w"){|f| f.puts(text) }
    end

    # PriorityFile::run(filepath, section)
    def self.run(filepath, section)

        nxball = NxBalls::makeNxBall([])

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
                PriorityFile::catalystSafe(filepath)
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
            puts "access | [] | >ondate | >Nx50 | exit (default)".yellow
            command = LucilleCore::askQuestionAnswerAsString("> ")

            if command == "" then
                break
            end

            if Interpreting::match("access", command) then
                section = accessedit.call(filepath, section)
                next
            end

            if command == "[]" then
                PriorityFile::catalystSafe(filepath)
                section2 = SectionsType0141::applyNextTransformationToText(section) + "\n"
                text = IO.read(filepath)
                text = text.gsub(section, section2)
                File.open(filepath, "w"){|f| f.puts(text) }
                section = section2
                next
            end

            if command == ">ondate" then
                PriorityFile::recastSectionAsOndate(filepath, section)
                break
            end

            if command == ">Nx50" then
                PriorityFile::recastSectionAsNx50(filepath, section)
                break
            end

            if command == "exit" then
                break
            end
        }

        thr.exit

        NxBalls::closeNxBall(nxball, true)
    end

    # PriorityFile::ns16s(domain)
    def self.ns16s(domain)
        filepath = "/Users/pascal/Desktop/#{domain}.txt"
        text = IO.read(filepath)
        sections = SectionsType0141::contentToSections(text)

        shiftText = lambda{|text|
            line = text.lines.first
            lines = text.lines.drop(1)
            line + lines.map{|line| "      #{line}" }.join()
        }

        sections.map{|section|
            sectionSmall = section.strip
            uuid = Digest::SHA1.hexdigest("6a212fa7-ccbb-461d-8204-9f22a9713d55:#{sectionSmall}:#{Utils::today()}")
            {
                "uuid"        => uuid,
                "announce"    => (sectionSmall.lines.size == 1) ? sectionSmall.green : shiftText.call(sectionSmall).green,
                "commands"    => ["..", "[]", ">ondate", ">Nx50"],
                "interpreter" => lambda{|command|
                    if command == ".." then
                        PriorityFile::run(filepath, section)
                    end
                    if command == "[]" then
                        PriorityFile::catalystSafe(filepath)
                        section2 = SectionsType0141::applyNextTransformationToText(section) + "\n"
                        text = IO.read(filepath)
                        text = text.gsub(section, section2)
                        File.open(filepath, "w"){|f| f.puts(text) }
                    end
                    if command == ">ondate" then
                        PriorityFile::recastSectionAsOndate(filepath, section)
                    end
                    if command == ">Nx50" then
                        PriorityFile::recastSectionAsNx50(filepath, section)
                    end
                },
                "run" => lambda {
                    PriorityFile::run(filepath, section)
                }
            }
        }
    end
end

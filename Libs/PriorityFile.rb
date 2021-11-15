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

    # PriorityFile::rewriteFileWithoutSection(filepath, section)
    def self.rewriteFileWithoutSection(filepath, section)
        PriorityFile::catalystSafe(filepath)
        text = IO.read(filepath)
        text = text.gsub(section, "")
        File.open(filepath, "w"){|f| f.puts(text) }
    end

    # PriorityFile::run(filepath, section)
    def self.run(filepath, section)

        puts "> identify the domain of this priority item"
        domain = Domain::interactivelySelectOrGetCachedDomain(section.strip)
        domainBankAccount = Domain::getDomainBankAccount(domain)

        nxball = NxBalls::makeNxBall([domainBankAccount])

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

            puts section.lines.first(10).join().strip.green
            puts ""
            puts "[] | access | >ondate | >Nx50 | exit (default)".yellow
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
                date = Dated::interactivelySelectADateOrNull()
                return if date.nil?
                item = Dated::issueItemUsingText(section.strip, Time.new.to_i, date)
                puts JSON.pretty_generate(item)

                PriorityFile::rewriteFileWithoutSection(filepath, section)
                break
            end

            if command == ">Nx50" then
                domain = Domain::interactivelySelectDomain()
                unixtime = Nx50s::interactivelyDetermineNewItemUnixtime(domain)
                item = Nx50s::issueItemUsingTextOrNull(section.strip, unixtime, domain)
                next if item.nil?
                puts JSON.pretty_generate(item)
                PriorityFile::rewriteFileWithoutSection(filepath, section)
                break
            end

            if command == "exit" then
                break
            end
        }

        thr.exit

        NxBalls::closeNxBall(nxball, true)
    end

    # PriorityFile::ns16s()
    def self.ns16s()
        filepath = "/Users/pascal/Desktop/Priority.txt"
        text = IO.read(filepath)
        sections = SectionsType0141::contentToSections(text)

        shiftText = lambda{|text, padding|
            text
                .lines
                .map{|line| "#{padding}#{line}" }
                .join()
        }

        getUnixtime = lambda{|section|
            unixtime = KeyValueStore::getOrNull(nil, "386410cf-7ccf-4bc6-88a8-4fd90e1c64fd:#{section}")
            if unixtime then
                return unixtime.to_f
            end
            unixtime = Time.new.to_f
            KeyValueStore::set(nil, "386410cf-7ccf-4bc6-88a8-4fd90e1c64fd:#{section}", unixtime)
            unixtime
        }

        textToAnnounce = lambda {|text|
            if (text.lines.size == 1) then
                "[prio] #{text}"
            else
                "[prio]\n#{shiftText.call(text.lines.first(5).join(), "             ")}"
            end
        }

        sections.map{|section|
            uuid = Digest::SHA1.hexdigest("6a212fa7-ccbb-461d-8204-9f22a9713d55:#{section.strip}:#{Utils::today()}")
            {
                "uuid"        => uuid,
                "announce"    => textToAnnounce.call(section.strip),
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
                        date = Dated::interactivelySelectADateOrNull()
                        return if date.nil?
                        item = Dated::issueItemUsingText(section.strip, Time.new.to_i, date)
                        puts JSON.pretty_generate(item)

                        PriorityFile::rewriteFileWithoutSection(filepath, section)
                    end
                    if command == ">Nx50" then
                        domain = Domain::interactivelySelectDomain()
                        unixtime = Nx50s::interactivelyDetermineNewItemUnixtime(domain)
                        item = Nx50s::issueItemUsingTextOrNull(section.strip, unixtime, domain)
                        return if item.nil?
                        puts JSON.pretty_generate(item)
                        PriorityFile::rewriteFileWithoutSection(filepath, section)
                    end
                },
                "run" => lambda {
                    PriorityFile::run(filepath, section)
                }
            }
        }
    end
end

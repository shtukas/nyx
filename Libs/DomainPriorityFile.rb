# encoding: UTF-8

class DomainPriorityFile

    # DomainPriorityFile::applyNextTransformation(filepath)
    def self.applyNextTransformation(filepath)
        contents = IO.read(filepath)
        return if contents.strip == ""
        contents = SectionsType0141::applyNextTransformationToText(contents)
        File.open(filepath, "w"){|f| f.puts(contents)}
    end

    # DomainPriorityFile::run(item)
    def self.run(item)

        filepath = item["filepath"]

        nxball = NxBalls::makeNxBall([item["bankaccount"]])

        thr = Thread.new {
            loop {
                sleep 60

                if (Time.new.to_i - nxball["cursorUnixtime"]) >= 600 then
                    nxball = NxBalls::upgradeNxBall(nxball, false)
                end

                if (Time.new.to_i - nxball["startUnixtime"]) >= 3600 then
                    Utils::onScreenNotification("Catalyst", "Priority file running for more than an hour")
                end
            }
        }

        loop {
            
            system("clear")

            text = IO.read(filepath).strip
            puts ""
            text = text.lines.first(10).join().strip
            puts text.green
            puts ""
            puts "[] | exit (default)".yellow
            command = LucilleCore::askQuestionAnswerAsString("> ")

            if command == "" then
                break
            end

            if command == "exit" then
                break
            end

            if Interpreting::match("[]", command) then
                DomainPriorityFile::applyNextTransformation(filepath)
                next
            end
        }

        thr.exit

        NxBalls::closeNxBall(nxball, true)
    end

    # DomainPriorityFile::itemToNS16OrNull(item, domain)
    def self.itemToNS16OrNull(item, domain)
        return nil if (item["domain"] != domain)
        filepath = item["filepath"]
        return nil if IO.read(item["filepath"]).strip.size == 0
        {
            "uuid"        => Digest::SHA1.hexdigest("25533ad6-50ff-463c-908f-ba3ba8858b7e:#{filepath}:#{IO.read(filepath)}"),
            "domain"      => item["domain"],
            "announce"    => "[prio] #{File.basename(filepath)}".green,
            "commands"    => [".."],
            "interpreter" => lambda{|command|
                if command == ".." then
                    DomainPriorityFile::run(item)
                end
            },
            "run" => lambda {
                DomainPriorityFile::run(item)
            }
        }
    end

    # DomainPriorityFile::ns16s()
    def self.ns16s()
        domain = Domains::getCurrentActiveDomain()
        Domains::items()
            .map{|item| DomainPriorityFile::itemToNS16OrNull(item, domain) }
            .compact
    end
end

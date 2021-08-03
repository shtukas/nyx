
# encoding: UTF-8

class InboxLines

    # InboxLines::getRecordByUUIDOrNull(uuid)
    def self.getRecordByUUIDOrNull(uuid)
        db = SQLite3::Database.new("/Users/pascal/Galaxy/DataBank/Axion/axion.sqlite3")
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = nil
        db.execute( "select * from _axion_ where _uuid_=?" , [uuid] ) do |row|
            answer = {
                "uuid"             => row["_uuid_"],
                "creationTime"     => row["_creationTime_"],
                "operationalTime"  => row["_operationalTime_"],
                "nxType"           => row["_nxType_"],
                "nxTypeParameters" => row["_nxTypeParameters_"],
                "nxContentType"    => row["_nxContentType_"],
                "nxContentPayload" => row["_nxContentPayload_"]
            }
        end
        db.close
        answer
    end

    # InboxLines::access(record)
    def self.access(record)

        uuid = record["uuid"]
        line = record["nxContentPayload"]

        nxball = NxBalls::makeNxBall(["Nx60-69315F2A-BE92-4874-85F1-54F140E3B243", Domains::getDomainUUIDForItemOrNull(uuid)].compact)
        thr = Thread.new {
            loop {
                sleep 60
                if (Time.new.to_i - nxball["cursorUnixtime"]) >= 600 then
                    nxball = NxBalls::upgradeNxBall(nxball, false)
                end
            }
        }

        system("clear")

        puts "[inbox] line: #{line}".green
        puts "Started at: #{Time.new.to_s}".yellow

        if Domains::getDomainUUIDForItemOrNull(uuid).nil? then
            domain = Domains::selectDomainOrNull()
            if domain then
                nxball["bankAccounts"] << domain["uuid"]
            end
        end

        puts ""

        loop {

            itemdomainuuid = Domains::getDomainUUIDForItemOrNull(uuid)

            break if (!itemdomainuuid.nil? and (itemdomainuuid != NS16sOperator::currentDomain()["uuid"]))

            puts "done | dispatch".yellow

            command = LucilleCore::askQuestionAnswerAsString("> ")

            if command == "done" then
                InboxLines::destroy(uuid)
                break
            end

            if command == "dispatch" then
                nx50 = Nx50s::issueNx50UsingTextInteractive(line)
                InboxLines::destroy(uuid)
                break
            end
        }

        thr.exit
        NxBalls::closeNxBall(nxball, true)
    end

    # InboxLines::issueNewLine(line)
    def self.issueNewLine(line)
        uuid = SecureRandom.uuid
        creationTime = Time.new.to_f
        operationalTime = Time.new.utc.iso8601
        nxType = "NxCatalystInbox"
        nxTypeParameters = nil
        nxContentType = "line"
        nxContentPayload = line

        db = SQLite3::Database.new("/Users/pascal/Galaxy/DataBank/Axion/axion.sqlite3")
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.transaction 
        db.execute "insert into _axion_ (_uuid_, _creationTime_, _operationalTime_, _nxType_, _nxTypeParameters_, _nxContentType_, _nxContentPayload_) values (?,?,?,?,?,?,?)", [uuid, creationTime, operationalTime, nxType, nxTypeParameters, nxContentType, nxContentPayload]
        db.commit 
        db.close
    end

    # InboxLines::getRecords()
    def self.getRecords()
        db = SQLite3::Database.new("/Users/pascal/Galaxy/DataBank/Axion/axion.sqlite3")
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.results_as_hash = true
        answer = []
        db.execute( "select * from _axion_ where _nxType_=? and _nxContentType_=? order by _creationTime_" , ["NxCatalystInbox", "line"] ) do |row|
            answer << {
                "uuid"             => row["_uuid_"],
                "creationTime"     => row["_creationTime_"],
                "operationalTime"  => row["_operationalTime_"],
                "nxType"           => row["_nxType_"],
                "nxTypeParameters" => row["_nxTypeParameters_"],
                "nxContentType"    => row["_nxContentType_"],
                "nxContentPayload" => row["_nxContentPayload_"]
            }
        end
        db.close
        answer
    end

    # InboxLines::destroy(uuid)
    def self.destroy(uuid)
        db = SQLite3::Database.new("/Users/pascal/Galaxy/DataBank/Axion/axion.sqlite3")
        db.busy_timeout = 117
        db.busy_handler { |count| true }
        db.transaction 
        db.execute "delete from _axion_ where _uuid_=?", [uuid]
        db.commit 
        db.close
    end

    # InboxLines::ns16s()
    def self.ns16s()
        InboxLines::getRecords().map{|record|
            uuid = record["uuid"]
            line = record["nxContentPayload"]
            unixtime = record["creationTime"]
            announce = "#{Domains::domainPrefix(uuid)} [inbx] line: #{line}"
            {
                "uuid"     => uuid,
                "announce" => announce,
                "access"   => lambda { InboxLines::access(record) },
                "done"     => lambda { InboxLines::destroy(uuid) },
                "domain"   => Domains::getItemDomainByIdOrNull(uuid),
                "inbox-unixtime" => unixtime
            }
        }
    end

end

class InboxFiles

    # InboxFiles::repositoryFolderpath()
    def self.repositoryFolderpath()
        "/Users/pascal/Desktop/Inbox"
    end

    # InboxFiles::locations()
    def self.locations()
        LucilleCore::locationsAtFolder(InboxFiles::repositoryFolderpath())
    end

    # InboxFiles::access(location)
    def self.access(location)

        uuid = "#{location}:#{Utils::today()}"

        nxball = NxBalls::makeNxBall(["Nx60-69315F2A-BE92-4874-85F1-54F140E3B243", Domains::getDomainUUIDForItemOrNull(uuid)].compact)

        thr = Thread.new {
            loop {
                sleep 60
                if (Time.new.to_i - nxball["cursorUnixtime"]) >= 600 then
                    nxball = NxBalls::upgradeNxBall(nxball, false)
                end

                if (Time.new.to_i - nxball["startUnixtime"]) >= 3600 then
                    Utils::onScreenNotification("Catalyst", "Inbox item running for more than an hour")
                end
            }
        }

        system("clear")

        puts "[inbox] file: #{location}".green

        if location.include?("'") then
            puts "Looking at: #{location}"
            if LucilleCore::askQuestionAnswerAsBoolean("remove quote ? ", true) then
                location2 = location.gsub("'", "-")
                FileUtils.mv(location, location2)
                location = location2
            end
        end

        if !location.include?("'") then
            system("open '#{location}'")
        end

        if Domains::getDomainUUIDForItemOrNull(uuid).nil? then
            domain = Domains::selectDomainOrNull()
            if domain then
                nxball["bankAccounts"] << domain["uuid"]
            end
        end

        puts ""

        loop {

            itemdomainuuid = Domains::getDomainUUIDForItemOrNull(uuid)

            break if (!itemdomainuuid.nil? and (itemdomainuuid != NS16sOperator::currentDomain()["uuid"]))

            puts "done | dispatch".yellow

            command = LucilleCore::askQuestionAnswerAsString("> ")

            if command == "done" then
                LucilleCore::removeFileSystemLocation(location)
                break
            end

            if command == "dispatch" then
                Nx50s::issueNx50UsingLocationInteractive(location)
                LucilleCore::removeFileSystemLocation(location)
                break
            end
        }

        thr.exit

        NxBalls::closeNxBall(nxball, true)
    end

    # InboxFiles::ns16s()
    def self.ns16s()
        InboxFiles::locations().map{|location|
            uuid = "#{Utils::today()}:#{location}"
            {
                "uuid"     => uuid,
                "announce" => "#{Domains::domainPrefix(uuid)} [inbx] file: #{File.basename(location)}",
                "access"   => lambda { InboxFiles::access(location) },
                "done"     => lambda { LucilleCore::removeFileSystemLocation(location) },
                "domain"   => Domains::getItemDomainByIdOrNull(uuid),
                "inbox-unixtime" => File.mtime(location).to_time.to_i
            }
        }
    end
end


class Inbox

    # Inbox::ns16s(domain)
    def self.ns16s(domain)
        (InboxLines::ns16s() + InboxFiles::ns16s())
            .sort{|i1, i2| i1["inbox-unixtime"] <=> i2["inbox-unixtime"] }
            .select{|ns16| ns16["domain"].nil? or ns16["domain"]["uuid"] == domain["uuid"] }
    end
end
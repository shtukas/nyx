# encoding: UTF-8

class Todos

    # Todos::todosCommonBankAccount()
    def self.todosCommonBankAccount()
        "20698c0669f72c05e214ecceaed9ca28"
    end

    # Todos::todosFolderPath()
    def self.todosFolderPath()
        "#{Utils::catalystDataCenterFolderpath()}/Todos"
    end

    # Todos::todoFilepaths()
    def self.todoFilepaths()
        LucilleCore::locationsAtFolder(Todos::todosFolderPath())
    end

    # Todos::filepathToString(filepath)
    def self.filepathToString(filepath)
        contents = IO.read(filepath)
        return "[todo] [empty] @ #{File.basename(filepath)}" if contents.strip == ""
        "[todo] #{contents.lines.first.strip}"
    end

    # Todos::interactivelyMakeNewTodoItem()
    def self.interactivelyMakeNewTodoItem()
        text = Utils::editTextSynchronously("")
        filepath = "#{Todos::todosFolderPath()}/#{LucilleCore::timeStringL22()}.txt"
        File.open(filepath, "w"){|f| f.puts(text)}
    end

    # Todos::applyNextTransformationToFile(filepath, hash1)
    def self.applyNextTransformationToFile(filepath, hash1)
        contents = IO.read(filepath)
        return if contents.strip == ""
        hash2 = Digest::SHA1.file(filepath).hexdigest
        return if hash1 != hash2
        contents = SectionsType0141::applyNextTransformationToText(contents)
        File.open(filepath, "w"){|f| f.puts(contents)}
    end

    # Todos::accessFilepath(filepath)
    def self.accessFilepath(filepath)
        startUnixtime = Time.new.to_f

        puts IO.read(filepath).strip.green
        puts ""

        uuid = File.basename(filepath)

        loop {

            hash1 = Digest::SHA1.file(filepath).hexdigest

            puts "[] | open | destroy".yellow

            command = LucilleCore::askQuestionAnswerAsString("> ")

            break if command == ""

            if Interpreting::match("[]", command) then
                system("open '#{File.dirname(filepath)}'")
                next
            end

            if Interpreting::match("open", command) then
                system("open '#{filepath}'")
                next
            end

            if Interpreting::match("destroy", command) then
                FileUtils.rm(filepath)
                $counterx.registerDone()
                break
            end
        }

        timespan = Time.new.to_f - startUnixtime

        puts "Time since start: #{timespan}"

        timespan = [timespan, 3600*2].min

        puts "putting #{timespan} seconds to uuid: #{uuid}: todo filepath: #{filepath}"
        Bank::put(uuid, timespan)
        Bank::put(Todos::todosCommonBankAccount(), timespan)

        $counterx.registerTimeInSeconds(timespan)
    end

    # Todos::filepathToNS16OrNull(filepath)
    def self.filepathToNS16OrNull(filepath)
        if IO.read(filepath).strip == "" then
            FileUtils.rm(filepath)
            return nil 
        end
        uuid = File.basename(filepath)
        recoveryTime = BankExtended::stdRecoveredDailyTimeInHours(uuid)
        {
            "uuid"         => uuid,
            "recoveryTime" => recoveryTime,
            "announce"     => "(#{"%5.3f" % recoveryTime}) #{Todos::filepathToString(filepath)}",
            "access"       => lambda { Todos::accessFilepath(filepath) },
            "done"         => lambda { Todos::accessFilepath(filepath) },
            "[]"           => lambda { Todos::applyNextTransformationToFile(filepath, Digest::SHA1.file(filepath).hexdigest) }
        }
    end

    # Todos::ns16s()
    def self.ns16s()
        Todos::todoFilepaths()
            .map{|filepath| Todos::filepathToNS16OrNull(filepath) }
            .compact
            .sort{|x1, x2| x1["recoveryTime"]<=>x2["recoveryTime"] }
            .select{|ns16| DoNotShowUntil::isVisible(ns16["uuid"]) }
    end

    # Todos::ns20()
    def self.ns20()
        {
            "announce"     => "Todos",
            "recoveryTime" => BankExtended::stdRecoveredDailyTimeInHours(Todos::todosCommonBankAccount()),
            "ns16s"        => Todos::ns16s()
        }
    end
end

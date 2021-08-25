# encoding: UTF-8

class PriorityFile

    # PriorityFile::applyNextTransformation(filepath)
    def self.applyNextTransformation(filepath)
        contents = IO.read(filepath)
        return if contents.strip == ""
        contents = SectionsType0141::applyNextTransformationToText(contents)
        File.open(filepath, "w"){|f| f.puts(contents)}
    end

    # PriorityFile::arrow(filepath)
    def self.arrow(filepath)
        startUnixtime = Time.new.to_f

        system("open '#{filepath}'")

        loop {
            system("clear")

            puts IO.read(filepath).strip.lines.first(10).join().strip.green
            puts ""

            puts "open | <datecode> | [] | (empty) # default # exit".yellow
            puts Interpreters::mainMenuCommands().yellow

            command = LucilleCore::askQuestionAnswerAsString("> ")

            break if command == ""

            if (unixtime = Utils::codeToUnixtimeOrNull(command.gsub(" ", ""))) then
                DoNotShowUntil::setUnixtime(uuid, unixtime)
                break
            end

            if Interpreting::match("open", command) then
                system("open '#{filepath}'")
            end

            if Interpreting::match("[]", command) then
                PriorityFile::applyNextTransformation(filepath)
            end
            
            Interpreters::mainMenuInterpreter(command)
        }

        timespan = Time.new.to_f - startUnixtime

        puts "Time since start: #{timespan}"

        timespan = [timespan, 3600*2].min

        puts "putting #{timespan} seconds to file '#{filepath}'"
        Bank::put(filepath, timespan)
    end

    # PriorityFile::ns16OrNull(filepath)
    def self.ns16OrNull(filepath)

        filename = File.basename(filepath)

        return nil if IO.read(filepath).strip == ""

        contents = IO.read(filepath)

        announce = "#{filename}\n#{contents.strip.lines.first(10).join().green}"

        uuid = "#{filepath}:#{Utils::today()}"

        return nil if !DoNotShowUntil::isVisible(uuid)

        {
            "uuid"        => uuid,
            "announce"    => announce,
            "commands"    => ["..", "[]"],
            "interpreter" => lambda{|command|
                if command == ".." then
                    PriorityFile::arrow(filepath)
                end
                if command == "[]" then
                    PriorityFile::applyNextTransformation(filepath)
                end
            },
            "run" => lambda {
                PriorityFile::arrow(filepath)
            }
        }
    end
end

# encoding: UTF-8

class TodoFiles

    # TodoFiles::todoFileToNS16OrNull(filepath, showFileContents)
    def self.todoFileToNS16OrNull(filepath, showFileContents)

        applyNextTransformation = lambda{|filepath, hash1|
            contents = IO.read(filepath)
            return if contents.strip == ""
            hash2 = Digest::SHA1.file(filepath).hexdigest
            return if hash1 != hash2
            contents = SectionsType0141::applyNextTransformationToText(contents)
            File.open(filepath, "w"){|f| f.puts(contents)}
        }

        raise "c2f47ddb-c278-4e03-b350-0a204040b224" if filepath.nil? # can happen because some of those filepath are unique string lookups
        filename = File.basename(filepath)
        contents = IO.read(filepath)
        return nil if contents.strip == ""
        hash1 = Digest::SHA1.file(filepath).hexdigest

        announce =
            if showFileContents then
                "\n#{contents.strip.lines.first(10).map{|line| "      #{line}" }.join().green}"
            else
                File.basename(filepath)
            end 
        
        uuid = hash1

        {
            "uuid"     => hash1,
            "announce" => announce,
            "access"    => lambda {

                startUnixtime = Time.new.to_f

                system("open '#{filepath}'")

                loop {
                    system("clear")

                    puts contents.strip.lines.first(10).strip.green
                    puts ""

                    puts "open | ++ / + datecode | [] | (empty) # default # exit".yellow

                    command = LucilleCore::askQuestionAnswerAsString("> ")

                    break if command == ""

                    if Interpreting::match("open", command) then
                        system("open '#{filepath}'")
                    end

                    if Interpreting::match("++", command) then
                        DoNotShowUntil::setUnixtime(uuid, Time.new.to_i+3600)
                        break
                    end

                    if Interpreting::match("+ *", command) then
                        _, input = Interpreting::tokenizer(command)
                        unixtime = Utils::codeToUnixtimeOrNull("+#{input}")
                        next if unixtime.nil?
                        DoNotShowUntil::setUnixtime(uuid, unixtime)
                        break
                    end

                    if Interpreting::match("+ * *", command) then
                        _, amount, unit = Interpreting::tokenizer(command)
                        unixtime = Utils::codeToUnixtimeOrNull("+#{amount}#{unit}")
                        return if unixtime.nil?
                        DoNotShowUntil::setUnixtime(uuid, unixtime)
                        break
                    end

                    if Interpreting::match("[]", command) then
                        applyNextTransformation.call(filepath, hash1)
                    end
                    
                    if Interpreting::match("", command) then
                        break
                    end
                }

                timespan = Time.new.to_f - startUnixtime

                puts "Time since start: #{timespan}"

                timespan = [timespan, 3600*2].min

                puts "putting #{timespan} seconds to uuid: #{uuid}: todo filepath: #{filepath}"
                Bank::put(uuid, timespan)
            },
            "done"     => lambda { },
            "[]"       => lambda { applyNextTransformation.call(filepath, hash1) }
        }
    end

    # TodoFiles::ns16s(filepath, showFileContents)
    def self.ns16s(filepath, showFileContents)
        [ TodoFiles::todoFileToNS16OrNull(filepath, showFileContents) ].compact
    end

    # TodoFiles::ns20OrNull(filepath, showFileContents)
    def self.ns20OrNull(filepath, showFileContents)
        ns16 = TodoFiles::todoFileToNS16OrNull(filepath, showFileContents)
        return nil if ns16.nil?
        bankAccount = filepath
        recoveryTime = BankExtended::stdRecoveredDailyTimeInHours(bankAccount)
        {
            "announce"     => File.basename(filepath),
            "recoveryTime" => recoveryTime,
            "ns16s"        => [ns16]
        }
    end

    # TodoFiles::docnetNS16s()
    def self.docnetNS16s()
        isWeekday = Utils::isWeekday()
        isDocNetTime = ((Time.new.hour >= 7) and ((isWeekday and Time.new.hour < 10) or (!isWeekday and Time.new.hour < 12)))
        return [] if !isDocNetTime
        [ TodoFiles::todoFileToNS16OrNull(Utils::locationByUniqueStringOrNull("ab25a8f8-0578"), true) ].compact
    end
end

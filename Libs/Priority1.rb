# encoding: UTF-8

class Priority1

    # Priority1::applyNextTransformation(filepath, hash1)
    def self.applyNextTransformation(filepath, hash1)
        contents = IO.read(filepath)
        return if contents.strip == ""
        hash2 = Digest::SHA1.file(filepath).hexdigest
        return if hash1 != hash2
        contents = SectionsType0141::applyNextTransformationToText(contents)
        File.open(filepath, "w"){|f| f.puts(contents)}
    end

    # Priority1::ns16OrNull()
    def self.ns16OrNull()

        filepath = "/Users/pascal/Desktop/Priority 1.txt"

        raise "c2f47ddb-c278-4e03-b350-0a204040b224" if filepath.nil? # can happen because some of those filepath are unique string lookups
        
        filename = File.basename(filepath)
        
        return nil if IO.read(filepath).strip == ""

        contents = IO.read(filepath)

        announce = "\n#{contents.strip.lines.first(10).map{|line| "      #{line}" }.join().green}"
        
        uuid = Digest::SHA1.hexdigest(contents.strip)

        {
            "uuid"      => uuid,
            "announce"  => announce,
            "access"    => lambda {

                startUnixtime = Time.new.to_f

                system("open '#{filepath}'")

                loop {
                    system("clear")

                    puts IO.read(filepath).strip.lines.first(10).join().strip.green
                    puts ""

                    puts "open | <datecode> | [] | (empty) # default # exit".yellow

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
                        Priority1::applyNextTransformation(filepath, Digest::SHA1.file(filepath).hexdigest)
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
            "[]"       => lambda { Priority1::applyNextTransformation(filepath, Digest::SHA1.file(filepath).hexdigest) }
        }
    end
end

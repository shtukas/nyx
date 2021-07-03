# encoding: UTF-8

class PriorityFile

    # PriorityFile::applyNextTransformation(filepath, hash1)
    def self.applyNextTransformation(filepath, hash1)
        contents = IO.read(filepath)
        return if contents.strip == ""
        hash2 = Digest::SHA1.file(filepath).hexdigest
        return if hash1 != hash2
        contents = SectionsType0141::applyNextTransformationToText(contents)
        File.open(filepath, "w"){|f| f.puts(contents)}
    end

    # PriorityFile::ns16OrNull(filepath)
    def self.ns16OrNull(filepath)

        filename = File.basename(filepath)
        
        return nil if IO.read(filepath).strip == ""

        contents = IO.read(filepath)

        announce = "#{filename}\n#{contents.strip.lines.first(10).map{|line| "      #{line}" }.join().green}"
        
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

                    puts "open | <datecode> | [] | (empty) # default # exit | ''".yellow

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
                        PriorityFile::applyNextTransformation(filepath, Digest::SHA1.file(filepath).hexdigest)
                    end
                    
                    if Interpreting::match("''", command) then
                        UIServices::operationalInterface()
                    end
                }

                timespan = Time.new.to_f - startUnixtime

                puts "Time since start: #{timespan}"

                timespan = [timespan, 3600*2].min

                puts "putting #{timespan} seconds to file '#{filepath}'"
                Bank::put(filepath, timespan)
            },
            "done"     => lambda { },
            "[]"       => lambda { PriorityFile::applyNextTransformation(filepath, Digest::SHA1.file(filepath).hexdigest) },
            ">>"       => lambda { 
                sections = SectionsType0141::contentToSections(contents)
                text = sections.first.strip
                puts "recasting section:"
                puts text.green
                status = LucilleCore::askQuestionAnswerAsBoolean("as todo item? ", true)
                if status then
                    Nx50s::textToNx50Interactive(text)
                    sections.shift
                    contents = sections.map{|section| section.strip }.join("\n\n")
                    File.open(filepath, "w"){|f| f.puts(contents)}
                end
            }
        }
    end
end

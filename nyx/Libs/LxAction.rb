
class LxAction

    # LxAction::action(command, object or nil)
    def self.action(command, object)

        # All objects sent to this are expected to have an mikyType attribute

        return if command.nil?

        if object and object["mikuType"].nil? then
            puts "Objects sent to LxAction::action if not null should have a mikuType attribute."
            puts "Got:"
            puts "command: #{command}"
            puts "object:"
            puts JSON.pretty_generate(object)
            puts "Aborting."
            exit
        end

        if command == "expose" then
            puts JSON.pretty_generate(object)
            LucilleCore::pressEnterToContinue()
            return
        end

        if command == "exit" then
            exit
        end

        if command == "landing" then

            if object["mikuType"] == "Ax1Text" then
                Ax1Text::landing(object)
                return
            end

            if object["mikuType"] == "Nx100" then
                Nx100s::landing(object)
                return
            end

            if object["mikuType"] == "TxAttachment" then
                TxAttachments::landing(object)
                return
            end

            if object["mikuType"] == "TxAttachment" then
                TxAttachments::landing(object)
                return
            end

            if object["mikuType"] == "TxOS01" then
                o = object["payload"]
                o["isSnapshot"] = true
                LxAction::action("landing", o)
                return
            end
        end

        if command == "nyx" then
            Nyx::program()
            return
        end

        if command == "search" then
            Search::classicInterface()
            return
        end

        puts "I do not know how to do action (command: #{command}, object: #{JSON.pretty_generate(object)})"
        LucilleCore::pressEnterToContinue()
    end
end
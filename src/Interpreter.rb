
# encoding: UTF-8

class Interpreter

    def initialize()
        @items = []
        @counter = 0
    end

    def registerExactCommand(command, xlambda)
        @items << {
            "type"    => "exact-command",
            "command" => command,
            "lambda"  => xlambda
        }
    end

    def indexDrivenMenuItem(announce, xlambda)
        @counter = @counter+1
        puts "[#{@counter.to_s.rjust(2)}] #{announce}"
        registerExactCommand(@counter.to_s, xlambda)
    end

    def prompt()
        # puts JSON.pretty_generate(@items)
        prompt = LucilleCore::askQuestionAnswerAsString("-> ")
        return if prompt == ""
        item = @items.select{|item| item["command"] == prompt }.first
        if item then
            item["lambda"].call()
            return true
        end
        false
    end
end


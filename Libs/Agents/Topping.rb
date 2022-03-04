# encoding: UTF-8

class Topping

    # The reason we are not just opening the files, is because those functions used to read and write 
    # from KeyValueStore. We kept the same logic and the same functions (and just added universe as argument)

    # Topping::getText(universe)
    def self.getText(universe)
        return nil if universe.nil?
        filepath = "/Users/pascal/Galaxy/DataBank/Catalyst/Multiverse/tops/#{universe}.txt"
        if !File.exists?(filepath) then
            FileUtils.touch(filepath)
        end
        IO.read(filepath)
    end

    # Topping::setText(universe, text)
    def self.setText(universe, text)
        filepath = "/Users/pascal/Galaxy/DataBank/Catalyst/Multiverse/tops/#{universe}.txt"
        File.open(filepath, "w") {|f| f.puts(text.strip) }
    end

    # Topping::applyTransformation(universe)
    def self.applyTransformation(universe)
        text = Topping::getText(universe)
        Utils::dropTextAtBinTimeline("Catalyst-Top-#{universe}.txt", text)
        text = SectionsType0141::applyNextTransformationToText(text)
        Topping::setText(universe, text)
    end

    # Topping::top(universe)
    def self.top(universe)
        text = Topping::getText(universe)
        Utils::dropTextAtBinTimeline("Catalyst-Top-#{universe}.txt", text)
        text = Utils::editTextSynchronously(text)
        Topping::setText(universe, text)
    end

    # Topping::runTop(universe)
    def self.runTop(universe)
        uuid = "846b76f4-0d69-49cc-91cc-f4109ec37ef4:#{universe}"
        description = "Top @ #{universe}"
        accounts = [UniverseAccounting::universeToAccountNumber(universe)]
        NxBallsService::issue(uuid, description, accounts)
    end
end



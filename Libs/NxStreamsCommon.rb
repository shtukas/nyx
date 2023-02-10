
class NxStreamsCommon

    # NxStreamsCommon::midpoint()
    def self.midpoint()
        0.5 * (NxTopStreams::endPosition() + NxTailStreams::frontPosition())
    end
end
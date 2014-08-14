require 'spec_helper'

describe ResultsPage do
  describe 'each' do
    let(:result_text) {
      StringIO.new(
        "\"Title\",\"Name\"\n" \
        "\"Prettygood Title\",\"B name\"\n" \
        "\"Notsogreat Title\",\"c name\"\n" \
        "\"RLYbad Title\",\"F name\"\n"
        )
    }
    let(:result_hashes) {
      [
        {"Title" => "Prettygood Title", "Name" => "B name"},
        {"Title" => "Notsogreat Title", "Name" => "c name"},
        {"Title" => "RLYbad Title", "Name" => "F name"}
      ]
    }

    it 'enumerates lines in a result and returns a hash' do
      page = ResultsPage.new(result_text)
      expect{|blk| page.each(&blk)}.
        to yield_successive_args(result_hashes[0], result_hashes[1], result_hashes[2])
    end

    it 'enumerates lines in chunks/slices if requested' do
      page = ResultsPage.new(result_text)
      expect{|blk| page.each_slice(2, &blk)}.
        to yield_successive_args(result_hashes[0..1], [result_hashes[2]])
    end
  end

end

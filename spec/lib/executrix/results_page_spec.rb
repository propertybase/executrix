require 'spec_helper'

describe ResultsPage do
  describe 'each' do
    let(:result_text) {
      StringIO.new(
        "\"Title\",\"Name\"\n" \
        "\"Prettygood Title\",\"B name\"\n" \
        "\"Notsogreat Title\",\"c name\"\n" \
        "\"RLYbad Title\",\"F name\"\n" \
        "\"Most Best Title\",\"\"\n"
        )
    }
    let(:result_hashes) {
      [
        {"Title" => "Prettygood Title", "Name" => "B name"},
        {"Title" => "Notsogreat Title", "Name" => "c name"},
        {"Title" => "RLYbad Title", "Name" => "F name"},
        {"Title" => "Most Best Title", "Name" => ""}
      ]
    }

    it 'enumerates lines in a result and returns a hash' do
      page = ResultsPage.new(result_text)
      expect{|blk| page.each(&blk)}.
        to yield_successive_args(result_hashes[0], result_hashes[1], result_hashes[2], result_hashes[3])
    end

    it 'enumerates lines in chunks/slices if requested' do
      page = ResultsPage.new(result_text)
      expect{|blk| page.each_slice(2, &blk)}.
        to yield_successive_args(result_hashes[0..1], result_hashes[2..3])
    end

    it 'rewinds StringIO for reading' do
      io = StringIO.new()
      io << result_text.string
      page = ResultsPage.new(io)
      expect{|blk| page.each(&blk)}.
        to yield_successive_args(result_hashes[0], result_hashes[1], result_hashes[2], result_hashes[3])
    end

    it 'can combine lines when first line has an escaped line ending' do
      io = StringIO.new(
        "\"Id\",\"Date\",\"Message\",\"ApprovedBy\",\"Id2\",\"Id3\"\n" \
        "\"0023666454AEF\",\"2014-06-24T15:35:27.000Z\",\"Jeremiah \"\"Jay\"\"\n Thanks \",\"\",\"0023643254AEF\",\"0027654454AEF\",\"\n"
      )

      hash_with_multiline = 
        {"Id"=>"0023666454AEF", "Date"=>"2014-06-24T15:35:27.000Z", "Message"=>"Jeremiah \"Jay\"\n Thanks ", "ApprovedBy"=>"", "Id2"=>"0023643254AEF", "Id3"=>"0027654454AEF\","}
      page = ResultsPage.new(io)

      expect{|blk| page.each(&blk)}.
        to yield_with_args(hash_with_multiline)

    end


  end

end

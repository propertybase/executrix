#encoding: utf-8
require 'spec_helper'

describe Executrix::Helper do
  describe '.records_to_csv' do
    it 'should return valid csv for single record' do
      input = [
        {'Title' => 'Awesome Title', 'Name' => 'A name'},
      ]

      expected_csv = "\"Title\",\"Name\"\n" \
      "\"Awesome Title\",\"A name\"\n"
      expect(described_class.records_to_csv(input)).to eq(expected_csv)
    end

    it 'should return valid csv for basic records' do
      input = [
        {'Title' => 'Awesome Title', 'Name' => 'A name'},
        {'Title' => 'A second Title', 'Name' => 'A second name'},
      ]

      expected_csv = "\"Title\",\"Name\"\n" \
      "\"Awesome Title\",\"A name\"\n" \
      "\"A second Title\",\"A second name\"\n"
      expect(described_class.records_to_csv(input)).to eq(expected_csv)
    end

    it 'should return valid csv when first row misses a key' do
      input = [
        {'Title' => 'Awesome Title', 'Name' => 'A name'},
        {'Title' => 'A second Title', 'Name' => 'A second name', 'Something' => 'Else'},
      ]

      expected_csv = "\"Title\",\"Name\",\"Something\"\n" \
      "\"Awesome Title\",\"A name\",\"\"\n" \
      "\"A second Title\",\"A second name\",\"Else\"\n"
      expect(described_class.records_to_csv(input)).to eq(expected_csv)
    end

    it 'should correctly convert Array to Multi-Picklist' do
      input = [
        {'Title' => 'Awesome Title', 'Picklist' => ['Several', 'Values']},
        {'Title' => 'A second Title', 'Picklist' => ['SingleValue']},
      ]

      expected_csv = "\"Title\",\"Picklist\"\n" \
        "\"Awesome Title\",\"Several;Values\"\n" \
        "\"A second Title\",\"SingleValue\"\n"
      expect(described_class.records_to_csv(input)).to eq(expected_csv)
    end

    it 'should return valid csv when order of keys varies' do
      input = [
        {'Title' => 'Awesome Title', 'Name' => 'A name'},
        {'Name' => 'A second name', 'Title' => 'A second Title'},
      ]

      expected_csv = "\"Title\",\"Name\"\n" \
      "\"Awesome Title\",\"A name\"\n" \
      "\"A second Title\",\"A second name\"\n"
      expect(described_class.records_to_csv(input)).to eq(expected_csv)
    end
  end

  describe '.fetch_instance_from_server_url' do
    let(:basic_api_server_url) {
      'https://cs7-api.salesforce.com/services/Soap/u/28.0/00CS00000095Y5b'
    }

    let(:basic_server_url) {
      'https://eu1.salesforce.com/services/Soap/u/28.0/00EU00000096Y8c'
    }

    let(:named_server_url) {
      'https://supercustomname.my.salesforce.com/services/Soap/u/28.0/00EH0000001jNQu'
    }

    it 'should return correct instance for regular salesforce server url' do
      expect(described_class.fetch_instance_from_server_url(basic_server_url))
        .to eq('eu1')
    end

    it 'should return correct instance for api salesforce server url' do
      expect(described_class.fetch_instance_from_server_url(basic_api_server_url))
        .to eq('cs7')
    end

    it 'should return correct instance for named salesforce server url' do
      expect(described_class.fetch_instance_from_server_url(named_server_url))
        .to eq('supercustomname.my')
    end
  end
end
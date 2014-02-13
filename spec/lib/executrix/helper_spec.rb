#encoding: utf-8
require 'spec_helper'

describe Executrix::Helper do
  describe '.records_to_csv' do
    it 'returns valid csv for single record' do
      input = [
        {'Title' => 'Awesome Title', 'Name' => 'A name'},
      ]

      expected_csv = "\"Title\",\"Name\"\n" \
      "\"Awesome Title\",\"A name\"\n"
      expect(described_class.records_to_csv(input)).to eq(expected_csv)
    end

    it 'returns valid csv for basic records' do
      input = [
        {'Title' => 'Awesome Title', 'Name' => 'A name'},
        {'Title' => 'A second Title', 'Name' => 'A second name'},
      ]

      expected_csv = "\"Title\",\"Name\"\n" \
      "\"Awesome Title\",\"A name\"\n" \
      "\"A second Title\",\"A second name\"\n"
      expect(described_class.records_to_csv(input)).to eq(expected_csv)
    end

    it 'returns valid csv when first row misses a key' do
      input = [
        {'Title' => 'Awesome Title', 'Name' => 'A name'},
        {'Title' => 'A second Title', 'Name' => 'A second name', 'Something' => 'Else'},
      ]

      expected_csv = "\"Title\",\"Name\",\"Something\"\n" \
      "\"Awesome Title\",\"A name\",\"\"\n" \
      "\"A second Title\",\"A second name\",\"Else\"\n"
      expect(described_class.records_to_csv(input)).to eq(expected_csv)
    end

    it 'correctly converts Array to Multi-Picklist' do
      input = [
        {'Title' => 'Awesome Title', 'Picklist' => ['Several', 'Values']},
        {'Title' => 'A second Title', 'Picklist' => ['SingleValue']},
      ]

      expected_csv = "\"Title\",\"Picklist\"\n" \
        "\"Awesome Title\",\"Several;Values\"\n" \
        "\"A second Title\",\"SingleValue\"\n"
      expect(described_class.records_to_csv(input)).to eq(expected_csv)
    end

    it 'returns valid csv when order of keys varies' do
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

    it 'returns correct instance for regular salesforce server url' do
      expect(described_class.fetch_instance_from_server_url(basic_server_url))
        .to eq('eu1')
    end

    it 'returns correct instance for api salesforce server url' do
      expect(described_class.fetch_instance_from_server_url(basic_api_server_url))
        .to eq('cs7')
    end

    it 'returns correct instance for named salesforce server url' do
      expect(described_class.fetch_instance_from_server_url(named_server_url))
        .to eq('supercustomname.my')
    end
  end

  describe '.attachment_keys' do
    let(:records_with_attachment) do
      prefix = Dir.tmpdir
      FileUtils.touch("#{prefix}/attachment.pdf")
      [
        {
          'normal_key' => 'normal_value1',
          'attachment_key' => nil,
        },
        {
          'normal_key' => 'normal_value2',
          'attachment_key' => File.new("#{prefix}/attachment.pdf"),
        }
      ]
    end

    let(:records_with_multiple_attachment) do
      prefix = Dir.tmpdir
      FileUtils.touch("#{prefix}/attachment1.pdf")
      FileUtils.touch("#{prefix}/attachment2.pdf")
      FileUtils.touch("#{prefix}/attachment3.pdf")
      [
        {
          'normal_key' => 'normal_value1',
          'attachment_key' => File.new("#{prefix}/attachment1.pdf"),
          'another_attachment_key' => File.new("#{prefix}/attachment2.pdf"),
        },
        {
          'normal_key' => 'normal_value2',
          'attachment_key' => File.new("#{prefix}/attachment3.pdf"),
        }
      ]
    end

    let(:records_without_attachment) do
      [
        {
          'normal_key' => 'normal_value1',
          'another_normal_key' => 'another_normal_value1',
        },
        {
          'normal_key' => 'normal_value2',
          'another_normal_key' => 'another_normal_value2',
        }
      ]
    end

    it 'returns correct keys for single attachment key' do
      expect(described_class.attachment_keys(records_with_attachment))
        .to eq(['attachment_key'])
    end

    it 'returns correct keys for multiple attachment keys' do
      expect(described_class.attachment_keys(records_with_multiple_attachment))
        .to eq(['attachment_key', 'another_attachment_key'])
    end

    it 'returns false for no attachment' do
      expect(described_class.attachment_keys(records_without_attachment))
        .to eq([])
    end
  end

  describe '.transform_values!' do
    let(:records_with_attachment) do
      prefix = Dir.tmpdir
      FileUtils.touch("#{prefix}/attachment.pdf")
      [
        {
          'normal_key' => 'normal_value1',
          'attachment_key' => nil,
        },
        {
          'normal_key' => 'normal_value2',
          'attachment_key' => File.new("#{prefix}/attachment.pdf"),
        }
      ]
    end

    it 'transforms values correctly' do
      expect(File).to receive(:absolute_path).and_return('/an/absolute/path')
      expected_output = [
        {
          'normal_key' => 'normal_value1',
          'attachment_key' => nil,
        },
        {
          'normal_key' => 'normal_value2',
          'attachment_key' => '#an/absolute/path',
        }
      ]

      input = records_with_attachment
      described_class.transform_values!(input,['attachment_key'])
      expect(input).to eq(expected_output)
    end

    it 'yields absolute path' do
      expect(File).to receive(:absolute_path).and_return('/an/absolute/path')
      input = records_with_attachment
      expect do |blk|
        described_class.transform_values!(input,['attachment_key'], &blk)
      end.to yield_with_args('/an/absolute/path')
    end
  end

  describe '.absolute_to_relative_path' do
    let(:unix_path) { '/a/unix/path' }
    let(:windows_path_backslash) { 'C:\a\backslash\path' }
    let(:windows_path_forwardslash) { 'C:/a/forwardslash/path' }

    it 'strips unix path correctly' do
      expect(described_class.absolute_to_relative_path(unix_path,'')).
        to eq('a/unix/path')
    end

    it 'strips windows path with backslash correctly' do
      expect(described_class.absolute_to_relative_path(windows_path_backslash,'')).
        to eq('a\backslash\path')
    end

    it 'strips windows path with forwardslash correctly' do
      expect(described_class.absolute_to_relative_path(windows_path_forwardslash,'')).
        to eq('a/forwardslash/path')
    end
  end

  describe '.parse_csv' do
    let(:csv_string) {
       "Id,my_external_id__c\n" \
       "003M000057GH39aIAD,K-00J799\n" \
       "003M001200KO82cIAD,K-015699"
    }
    let(:expected_result) {
      [
        { 'Id' => '003M000057GH39aIAD', 'my_external_id__c' => 'K-00J799' },
        { 'Id' => '003M001200KO82cIAD', 'my_external_id__c' => 'K-015699' },
      ]
    }
    it 'correctly transforms csv string' do
      expect(described_class.parse_csv(csv_string)).to eq(expected_result)
    end
  end
end
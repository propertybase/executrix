#encoding: utf-8
require 'spec_helper'

describe Executrix::Api do
  let(:empty_connection) do
    Executrix::Connection.new(nil, nil, nil, nil)
  end

  let(:empty_batch) do
    Object.new
  end

  {
    upsert: [nil,[{'no' => 'value'}], 'upsert_id'],
    update: [nil,[{'no' => 'value'}]],
    insert: [nil,[{'no' => 'value'}]],
    delete: [nil,[{'no' => 'value'}]],
  }.each do |method_name, values|
    describe "##{method_name}" do
      it 'delegates to #start_job' do
        expect(Executrix::Connection)
          .to receive(:connect)
          .and_return(empty_connection)
        s = described_class.new(nil, nil)
        expect(s).to receive(:start_job)
          .with(method_name.to_s, *values)
        s.send(method_name, *values)
      end

      it 'triggers correct workflow' do
        expect(Executrix::Connection)
          .to receive(:connect)
          .and_return(empty_connection)
        s = described_class.new(nil, nil)
        expect(empty_connection).to receive(:create_job).ordered
        expect(empty_connection).to receive(:add_batch).ordered
        expect(empty_connection).to receive(:close_job).ordered
        res = s.send(method_name, *values)
        expect(res).to be_a(Executrix::Batch)
      end
    end
  end

  describe '#query' do
    it 'triggers correct workflow' do
        expect(Executrix::Connection)
          .to receive(:connect)
          .and_return(empty_connection)
        expect(Executrix::Batch)
          .to receive(:new)
        .and_return(empty_batch)

      s = described_class.new(nil, nil)
      sobject_input = 'sobject_stub'
      query_input = 'query_stub'
      expect(empty_connection).to receive(:create_job).ordered
      expect(empty_connection).to receive(:add_query).ordered
      expect(empty_connection).to receive(:close_job).ordered
      expect(empty_batch).to receive(:final_status).ordered
      s.query(sobject_input, query_input)
    end
  end

  context 'file upload' do
    describe '#insert' do
      prefix = Dir.tmpdir
      FileUtils.touch("#{prefix}/attachment.pdf")
      attachment_data = {
        'ParentId' => '00Kk0001908kqkDEAQ',
        'Name' => 'attachment.pdf',
        'Body' => File.new("#{prefix}/attachment.pdf")
      }

      {
        upsert: [nil,[attachment_data.dup], 'upsert_id'],
        update: [nil,[attachment_data.dup]],
        insert: [nil,[attachment_data.dup]],
        delete: [nil,[attachment_data.dup]],
      }.each do |method_name, values|
        describe "##{method_name}" do
          it 'delegates to #start_job' do
            expect(Executrix::Connection)
              .to receive(:connect)
              .and_return(empty_connection)
            s = described_class.new(nil, nil)
            expect(s).to receive(:start_job)
              .with(method_name.to_s, *values)
            s.send(method_name, *values)
          end

          it 'triggers correct workflow' do
            expect(Executrix::Connection)
              .to receive(:connect)
              .and_return(empty_connection)
            s = described_class.new(nil, nil)
            expect(empty_connection).to receive(:create_job).ordered
            expect(empty_connection).to receive(:add_file_upload_batch).ordered
            expect(empty_connection).to receive(:close_job).ordered
            res = s.send(method_name, *values)
            expect(res).to be_a(Executrix::Batch)
          end
        end
      end
    end
  end
end
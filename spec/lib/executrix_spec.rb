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
      it 'should delegate to #start_job' do
        Executrix::Connection
          .should_receive(:connect)
          .and_return(empty_connection)
        s = described_class.new(nil, nil)
        s.should_receive(:start_job)
          .with(method_name.to_s, *values)
        s.send(method_name, *values)
      end

      it 'should trigger correct workflow' do
        Executrix::Connection
          .should_receive(:connect)
          .and_return(empty_connection)
        s = described_class.new(nil, nil)
        empty_connection.should_receive(:create_job).ordered
        empty_connection.should_receive(:add_batch).ordered
        empty_connection.should_receive(:close_job).ordered
        res = s.send(method_name, *values)
        expect(res).to be_a(Executrix::Batch)
      end
    end
  end

  describe '#query' do
    it 'should trigger correct workflow' do
      Executrix::Connection
          .should_receive(:connect)
          .and_return(empty_connection)
      Executrix::Batch
        .should_receive(:new)
        .and_return(empty_batch)

      s = described_class.new(nil, nil)
      sobject_input = 'sobject_stub'
      query_input = 'query_stub'
      empty_connection.should_receive(:create_job).ordered
      empty_connection.should_receive(:add_query).ordered
      empty_connection.should_receive(:close_job).ordered
      empty_batch.should_receive(:final_status).ordered
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
          it 'should delegate to #start_job' do
            Executrix::Connection
              .should_receive(:connect)
              .and_return(empty_connection)
            s = described_class.new(nil, nil)
            s.should_receive(:start_job)
              .with(method_name.to_s, *values)
            s.send(method_name, *values)
          end

          it 'should trigger correct workflow' do
            Executrix::Connection
              .should_receive(:connect)
              .and_return(empty_connection)
            s = described_class.new(nil, nil)
            empty_connection.should_receive(:create_job).ordered
            empty_connection.should_receive(:add_file_upload_batch).ordered
            empty_connection.should_receive(:close_job).ordered
            res = s.send(method_name, *values)
            expect(res).to be_a(Executrix::Batch)
          end
        end
      end
    end
  end
end
#encoding: utf-8
require 'spec_helper'

describe Executrix::Batch do
  describe '#final_status' do
    it 'returns the final status if it already exists' do
      b = described_class.new nil, nil, nil
      expected_status = {w: :tf}
      expect(b).not_to receive(:status)
      b.instance_variable_set '@final_status', expected_status
      expect(b.final_status).to eq(expected_status)
    end

    it 'returns specific final status for -1 batch id' do
      b = described_class.new nil, nil, -1
      expected_status = {
          state: 'Completed',
          state_message: 'Empty Request',
        }
      expect(b).not_to receive(:status)
      expect(b.final_status).to eq(expected_status)
    end

    it 'queries the status correctly' do
      b = described_class.new nil, nil, nil
      expect(b).to receive(:status).once.and_return({w: :tf})
      # TODO lookup the actual result
      expect(b).to receive(:results).once.and_return({g: :tfo})
      expect(b.final_status).to eq({w: :tf, results: {g: :tfo}})
    end

    it 'yields status correctly' do
      expected_running_state = {
          state: 'InProgress'
        }
      expected_final_state = {
          state: 'Completed'
        }
      b = described_class.new nil, nil, nil
      expect(b).to receive(:status).once.and_return(expected_running_state)
      expect(b).to receive(:status).once.and_return(expected_running_state)
      expect(b).to receive(:status).once.and_return(expected_final_state)
      expect(b).to receive(:results).once.and_return({g: :tfo})
      expect{|blk| b.final_status(0, &blk)}
        .to yield_successive_args(expected_running_state, expected_final_state)
    end

    it 'raises exception when batch fails' do
      b = described_class.new nil, nil, nil
      expected_error_message = 'Generic Error Message'
      expect(b).to receive(:status).once.and_return(
        {
          state: 'Failed',
          state_message: expected_error_message})
      expect{b.final_status}
        .to raise_error(StandardError, expected_error_message)
    end
  end

  [:request, :result].each do |action|
    let(:connection) { double('Executrix::Connection') }
    let(:request_result) { 'Generic Result/Request' }
    describe "#raw_#{action}" do

      it 'sends correct messages to connection' do
        b = described_class.new nil, nil, nil
        b.instance_variable_set '@connection', connection
        expect(connection).to receive(:"raw_#{action}").and_return(request_result)
        expect(b.send(:"raw_#{action}")).to eq(request_result)
      end
    end
  end

  describe '#results' do
    let(:job_id) {"12345"}
    let(:batch_id) {"67890"}
    let(:connection) {stub("connection")}
    subject {described_class.new connection, job_id, batch_id}

    context 'with a single page of results' do
      let(:result_id) {"M75200000001Vgt"}
      let(:single_result) {{:Id=>"M75200000001Vgt", :name=>"Joe"}}

      it 'returns the results' do
        expect(connection).to receive(:query_batch_result_id).
          with(job_id, batch_id).
          and_return({:result => result_id})

        expect(connection).to receive(:query_batch_result_data).
          once.
          with(job_id, batch_id, result_id).
          and_return(single_result)

        expect(subject.results).to eq([single_result])
      end
    end

    context 'with an array of page of results' do
      let(:result_ids) {["M75200000001Vgt", "M76500000001Vgt", "M73400000001Vgt"]}
      let(:multiple_results) {[{:Id=>"AAA11123", :name=>"Joe"},
        {:Id=>"AAA11124", :name=>"Sam"},
        {:Id=>"AAA11125", :name=>"Mike"}]}

      it 'returns concatenated results' do
        expect(connection).to receive(:query_batch_result_id).
          with(job_id, batch_id).
          and_return({:result => result_ids})

        expect(connection).to receive(:query_batch_result_data).
          ordered.
          with(job_id, batch_id, result_ids[0]).
          and_return(multiple_results[0])

        expect(connection).to receive(:query_batch_result_data).
          ordered.
          with(job_id, batch_id, result_ids[1]).
          and_return(multiple_results[1])

        expect(connection).to receive(:query_batch_result_data).
          ordered.
          with(job_id, batch_id, result_ids[2]).
          and_return(multiple_results[2])

        expect(subject.results).to eq(multiple_results)
      end
    end
  end
end 

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

    it 'returns itself once it has finished' do
      b = described_class.new nil, nil, nil
      expect(b).to receive(:status).once.and_return({w: :tf})
      expect(b.final_status).to eq(b)
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

  let(:connection) { double('Executrix::Connection') }
  let(:request_result) { 'Generic Request' }
  describe "#raw_request" do

    it 'sends correct messages to connection' do
      b = described_class.new nil, nil, nil
      b.instance_variable_set '@connection', connection
      expect(connection).to receive(:"raw_request").and_return(request_result)
      expect(b.send(:"raw_request")).to eq(request_result)
    end
  end

  describe '#results' do
    let(:job_id) {"12345"}
    let(:batch_id) {"67890"}
    let(:connection) {stub("connection")}
    subject {described_class.new connection, job_id, batch_id}

    context 'with a single page of results' do
      let(:result_id) {"M75200000001Vgt"}
      let(:results) {
        StringIO.new(
          "\"Title\",\"Name\"\n\"Awesome Title\",\"A name\"\n"
          )
      }
      let!(:results_page) {
        ResultsPage.new(results)
      }

      it 'yields the results page' do
        expect(ResultsPage).to receive(:new).with(results).
          and_return results_page
        expect(connection).to receive(:query_batch_result_id).
          with(job_id, batch_id).
          and_return({:result => result_id})

        expect(connection).to receive(:query_batch_result_data).
          once.
          with(job_id, batch_id, result_id).
          and_return(results)

        expect{|blk| subject.results(&blk)}.
          to yield_with_args(results_page)
      end
    end

    context 'with several pages of results' do
      let(:result_ids) {["M75200000001Vgt", "M76500000001Vgt"]}
      let(:results_1) {
        StringIO.new("\"Title\",\"Name\"\n\"Awesome Title\",\"A name\"\n")
      }
      let(:results_2) {
        StringIO.new(
          "\"Title\",\"Name\"\n" \
          "\"Prettygood Title\",\"B name\"\n" \
          "\"Notsogreat Title\",\"c name\"\n"
        )
      }
      let!(:results_page1) {
        ResultsPage.new(results_1)
      }
      let!(:results_page2) {
        ResultsPage.new(results_2)
      }

      it 'returns concatenated results' do
        expect(connection).to receive(:query_batch_result_id).
          with(job_id, batch_id).
          and_return({:result => result_ids})

        expect(connection).to receive(:query_batch_result_data).
          ordered.
          with(job_id, batch_id, result_ids[0]).
          and_return(results_1)

        expect(connection).to receive(:query_batch_result_data).
          ordered.
          with(job_id, batch_id, result_ids[1]).
          and_return(results_2)
        expect(ResultsPage).to receive(:new).with(results_1).
          and_return results_page1
        expect(ResultsPage).to receive(:new).with(results_2).
          and_return results_page2

        expect{|blk| subject.results(&blk)}.
          to yield_successive_args(results_page1, results_page2)
      end
    end
  end
end 

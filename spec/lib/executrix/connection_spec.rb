#encoding: utf-8
require 'spec_helper'

describe Executrix::Connection do
  let(:subject) { described_class.new nil, nil, nil, nil }

  {
    login: 0,
    create_job: 3,
    close_job: 1,
    query_batch: 2,
    query_batch_result_id: 2,
    query_batch_result_data: 3,
  }.each do |method_name, num_of_params|
    describe "##{method_name}" do
      it 'should delegate correctly to Http class' do
        Executrix::Http.
          should_receive(method_name).
          and_return({})
        subject.send(method_name, *Array.new(num_of_params))
      end
    end
  end

  describe '#add_query' do
    it 'should delegate correctly to Http class' do
      Executrix::Http.should_receive(:add_batch).
          and_return({})
      subject.add_query(nil, nil)
    end
  end

  describe '#org_id' do
    it 'should raise exception when not logged in' do
      expect {subject.org_id}.to raise_error(RuntimeError)
    end

    it 'should return correct OrgId after login' do
      org_id = '00D50000000IehZ'
      Executrix::Http
      .should_receive(:login)
      .and_return({session_id: "#{org_id}!AQcAQH0dMHZfz972Szmpkb58urFRkgeBGsxL_QJWwYMfAbUeeG7c1E6LYUfiDUkWe6H34r1AAwOR8B8fLEz6n04NPGRrq0FM"})
      expect(subject.login.org_id).to eq(org_id)
    end
  end


  describe '#add_batch' do
    it 'should delegate correctly to underlying classes' do
      Executrix::Http.should_receive(:add_batch).
          and_return({})
      Executrix::Helper.should_receive(:records_to_csv).
        and_return('My,Awesome,CSV')
      subject.add_batch(nil, 'non emtpy records')
    end

    it 'should return -1 for nil input' do
      return_code = subject.add_batch(nil, nil)
      expect(return_code).to eq(-1)
    end

    it 'should return -1 for empty input' do
      return_code = subject.add_batch(nil, [])
      expect(return_code).to eq(-1)
    end
  end
end
require 'executrix/version'
require 'executrix/helper'
require 'executrix/batch'
require 'executrix/http'
require 'executrix/connection'

module Executrix
  class Api
    SALESFORCE_API_VERSION = '28.0'

    def initialize(username, password, sandbox = false, api_version = SALESFORCE_API_VERSION)
      @connection = Executrix::Connection.connect(
        username,
        password,
        api_version,
        sandbox)
    end

    def org_id
      @connection.org_id
    end

    def upsert(sobject, records, external_field)
      start_job('upsert', sobject, records, external_field)
    end

    def update(sobject, records)
      start_job('update', sobject, records)
    end

    def insert(sobject, records)
      start_job('insert', sobject, records)
    end

    def delete(sobject, records)
      start_job('delete', sobject, records)
    end

    def query(sobject, query)
      job_id = @connection.create_job(
        'query',
        sobject,
        nil)
      batch_id = @connection.add_query(job_id, query)
      @connection.close_job job_id
      batch_reference = Executrix::Batch.new @connection, job_id, batch_id
      batch_reference.final_status
    end

    private
    def start_job(operation, sobject, records, external_field=nil)
      job_id = @connection.create_job(
        operation,
        sobject,
        external_field)
      batch_id = @connection.add_batch job_id, records
      @connection.close_job job_id
      Executrix::Batch.new @connection, job_id, batch_id
    end
  end
end
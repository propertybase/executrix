require 'executrix/version'
require 'executrix/helper'
require 'executrix/batch'
require 'executrix/http'
require 'executrix/connection'
require 'zip'

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
        'CSV',
        nil)
      batch_id = @connection.add_query(job_id, query)
      @connection.close_job job_id
      batch_reference = Executrix::Batch.new @connection, job_id, batch_id
      batch_reference.final_status
    end

    private
    def start_job(operation, sobject, records, external_field=nil)
      attachment_keys = Executrix::Helper.attachment_keys(records)

      content_type = 'CSV'
      zip_filename = nil
      request_filename = nil
      batch_id = -1
      if not attachment_keys.empty?
        tmp_filename = Dir::Tmpname.make_tmpname('bulk_upload', '.zip')
        zip_filename = "#{Dir.tmpdir}/#{tmp_filename}"
        Zip::File.open(zip_filename, Zip::File::CREATE) do |zipfile|
          Executrix::Helper.transform_values!(records, attachment_keys) do |path|
            zipfile.add(Executrix::Helper.absolute_to_relative_path(path, ''), path)
          end
          tmp_filename = Dir::Tmpname.make_tmpname('request', '.txt')
          request_filename = "#{Dir.tmpdir}/#{tmp_filename}"
          File.open(request_filename, 'w') do |file|
            file.write(Executrix::Helper.records_to_csv(records))
          end
          zipfile.add('request.txt', request_filename)
        end

        content_type = 'ZIP_CSV'
      end

      job_id = @connection.create_job(
        operation,
        sobject,
        content_type,
        external_field)
      if zip_filename
        batch_id = @connection.add_file_upload_batch job_id, zip_filename
        [zip_filename, request_filename].each do |file|
          File.delete(file) if file
        end
      else
        batch_id = @connection.add_batch job_id, records
      end

      @connection.close_job job_id
      Executrix::Batch.new @connection, job_id, batch_id
    end
  end
end
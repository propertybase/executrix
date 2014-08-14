module Executrix
  class Batch
    attr_reader :job_id

    def initialize connection, job_id, batch_id
      @connection = connection
      @job_id = job_id
      @batch_id = batch_id

      if @batch_id == -1
        @final_status = {
          state: 'Completed',
          state_message: 'Empty Request'
        }
      end
    end

    def final_status poll_interval=2
      return @final_status if @final_status

      @final_status = self.status
      while ['Queued', 'InProgress'].include?(@final_status[:state])
        sleep poll_interval
        @final_status = self.status
        yield @final_status if block_given?
      end

      raise @final_status[:state_message] if @final_status[:state] == 'Failed'

      self
    end

    def status
      @connection.query_batch @job_id, @batch_id
    end

    # results returned from Salesforce can be a single page id, or an array of ids.
    # if it's an array of ids, we will enumerate them.
    def results &block
      page_ids = Array(query_result_ids)
      page_ids.each do |page_id|
        results = @connection.query_batch_result_data(@job_id, @batch_id, page_id)
        page = ResultsPage.new(results)
        if block_given?
          block.call page
        else
          yield page
        end
      end
    end

    def raw_request
      @connection.raw_request
    end

    private
    def query_result_ids
      result_raw = @connection.query_batch_result_id(@job_id, @batch_id)
      result_raw[:result] if result_raw
    end
  end
end

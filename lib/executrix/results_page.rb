class ResultsPage
  include Enumerable

  def initialize(io)
    @io = io
    @io.rewind
    @header = Executrix::Helper.split_csv_line(@io.readline("\"\n"))
  end

  def each
    @io.lines("\"\n").each do |line|

      if @previous_line
        line.insert(0, @previous_line)
        @previous_line = nil
      end

      if Executrix::Helper.valid_line_ending?(line)
        yield Executrix::Helper.csv_to_hash line, @header
      else
        @previous_line = Executrix::Helper.escape_line_ending(line)
        next
      end
    end
  end
end

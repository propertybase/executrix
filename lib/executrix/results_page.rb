class ResultsPage
  include Enumerable

  def initialize(io)
    @io = io
    @header = Executrix::Helper.split_csv_line(@io.readline("\"\n"))
  end

  def each
    @io.lines("\"\n").each do |line|
      yield Executrix::Helper.csv_to_hash line, @header
    end
  end
end

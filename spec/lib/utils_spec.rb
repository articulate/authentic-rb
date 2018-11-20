# frozen_string_literal: true

describe 'utils' do
  describe 'human_time_to_seconds' do
    [
      %w[10h 36000],
      %w[10m 600],
      %w[10s 10],
      %w[10m10s 610],
      %w[10h10m10s 36610]
    ].each do |a, b|
      describe "Given inputs #{a}" do
        it "returns #{b}" do
          expect(human_time_to_seconds(a)).to be(b.to_i)
        end
      end
    end
  end
end

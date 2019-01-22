# frozen_string_literal: true

describe 'utils' do
  describe 'human_time_to_seconds' do
    {
      '10h' => 36_000,
      '10m' => 600,
      '10s' => 10,
      '10m10s' => 610,
      '10h10m10s' => 36_610
    }.each do |a, b|
      describe "Given inputs #{a}" do
        it "returns #{b}" do
          expect(Authentic::KeyStore.new(a).human_time_to_seconds(a)).to be(b.to_i)
        end
      end
    end
  end
end

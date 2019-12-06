RSpec.describe DistanceCalculator do
  DEFAULT_COORDS = [["2.78788", "3.578787"], ["3.6565", "55.6434"]]
  DEFAULT_RESULT = 5780.2

  before(:each) do
    DistanceCalculator.clear_cache
    WebMock.disable_net_connect!
  end

  it "has a version number" do
    expect(DistanceCalculator::VERSION).not_to be nil
  end

  it "checks constructor raises on incorrect args" do
    expect { DistanceCalculator.new([]) }.to raise_error(DistanceCalculator::NoEnoughCoordinatesError)
    expect { DistanceCalculator.new((1..DistanceCalculator::MAX_COORDINATE_PAIRS).to_a) }.not_to raise_error
    expect {
      DistanceCalculator.new((1..DistanceCalculator::MAX_COORDINATE_PAIRS+1).to_a)
    }.to raise_error(DistanceCalculator::TooManyCoordinatePairsError)
  end

  it "checks calculate_distance_with_math to return valid result" do
    expect(DistanceCalculator.get_cache.keys).to be_empty

    coords = [DEFAULT_COORDS]

    result = DistanceCalculator.new(coords).calculate_distance_with_math

    expect(result).to be_an(Array)
    expect(result).to all(
      be_an(Array)
      .and all(be_within(0.1).of(DEFAULT_RESULT))
    )
    coords.each {|c| expect(DistanceCalculator.get_cache.keys).to include(c)}
  end

  it "checks calculate_distance_with_api is not implemented" do
    expect(DistanceCalculator.get_cache.keys).to be_empty

    stub_request(:get, //).to_return(
      body: "{\"paths\":[{\"distance\": #{DEFAULT_RESULT}}]}",
      status: 200
    )

    coords = [DEFAULT_COORDS, DEFAULT_COORDS, DEFAULT_COORDS]

    result = DistanceCalculator.new(coords).calculate_distance_with_api

	# Only one request has been made, others cached
    expect(a_request(:get, //)).to have_been_made.once

    expect(result).to be_an(Array)
    expect(result).to all(
      be_an(Array)
      .and all(be_within(0.1).of(DEFAULT_RESULT))
    )
    coords.each {|c| expect(DistanceCalculator.get_cache.keys).to include(c)}
  end
end

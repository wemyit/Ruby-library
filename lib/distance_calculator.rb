require "distance_calculator/version"
require 'geocoder'
require 'json'

Geocoder.configure(units: :km)

class DistanceCalculator
  class Error < StandardError; end
  class NoEnoughCoordinatesError < Error; end
  class NoBlockSuplied < Error; end
  class TooManyCoordinatePairsError < Error; end
  class ApiRequestError < Error; end
  class IncorrectApiResponse < Error; end

  MAX_COORDINATE_PAIRS = 100

  @@cache = {}

  class << self
    def clear_cache
      @@cache = {}
    end

    def get_cache
      @@cache
    end
  end

  def initialize(coords)
    raise NoEnoughCoordinatesError if coords.empty?
    raise TooManyCoordinatePairsError if coords.length > MAX_COORDINATE_PAIRS
    @coords = coords
  end

  def calculate_distance_with_math
    calculate_distance do |from, to|
      Geocoder::Calculations.distance_between(from, to)
    end
  end

  def calculate_distance(&block)
    raise NoBlockSuplied unless block

    @coords.map do |coords|
      (from, to) = coords
      result = @@cache[coords] ||= block.call(from, to)
      [ result ]
    end
  end

  def calculate_distance_with_api
    calculate_distance do |from, to|
      distance_from_api_request(from, to)
    end
  end

  def distance_from_api_request(from, to)
    points_str = [from, to].map(&->(points){"points=#{points.join(',')}"}).join('&')
    uri = URI.parse("https://graphhopper.com/api/1/route?#{points_str}&type=json&locale=en-US&vehicle=car&weighting=fastest&instructions=false&key=0dc4f299-a491-452f-97e0-515c296c9453")
    response = Net::HTTP.get_response(uri)
    raise ApiRequestError if "#{response.code}" != "200"
    begin
      content = JSON.parse(response.body)
      result = content.dig("paths", 0, "distance")
      raise if not result
      result
    rescue
      raise IncorrectApiResponse
    end
  end
end

# frozen_string_literal: true

require File.expand_path('../../test_helper', File.dirname(__FILE__))

class RedisTest < Minitest::Test
  REDIS_STORAGE_FORMAT_VERSION = Coverband::Adapters::RedisStore::REDIS_STORAGE_FORMAT_VERSION

  def setup
    super
    @redis = Redis.new
    @store = Coverband::Adapters::RedisStore.new(@redis)
  end

  def test_coverage
    mock_file_hash
    expected = basic_coverage
    @store.save_report(expected)
    assert_equal expected.keys, @store.coverage.keys
    @store.coverage.each_pair do |key, data|
      assert_equal expected[key], data['data']
    end
  end

  def test_coverage_increments
    mock_file_hash
    expected = basic_coverage.dup
    @store.save_report(basic_coverage.dup)
    assert_equal expected.keys, @store.coverage.keys
    @store.coverage.each_pair do |key, data|
      assert_equal expected[key], data['data']
    end
    @store.save_report(basic_coverage.dup)
    assert_equal [0, 2, 4], @store.coverage['app_path/dog.rb']['data']
  end

  def test_store_coverage_by_type
    mock_file_hash
    expected = basic_coverage
    @store.type = :eager_loading
    @store.save_report(expected)
    assert_equal expected.keys, @store.coverage.keys
    @store.coverage.each_pair do |key, data|
      assert_equal expected[key], data['data']
    end

    @store.type = nil
    assert_equal [], @store.coverage.keys
  end

  def test_covered_lines_for_file
    mock_file_hash
    expected = basic_coverage
    @store.save_report(expected)
    assert_equal example_line, @store.covered_lines_for_file('app_path/dog.rb')
  end

  def test_covered_lines_when_null
    assert_equal [], @store.covered_lines_for_file('app_path/dog.rb')
  end

  def test_clear
    @redis.expects(:del).with(REDIS_STORAGE_FORMAT_VERSION).once
    @store.clear!
  end


end

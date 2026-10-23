require_relative "test_helper"

class Tripletex::OsloDateTest < Minitest::Test
  HOUR = 3600

  def test_moves_to_summer_time_at_one_utc_on_the_last_sunday_of_march
    assert_equal HOUR, Tripletex::OsloDate.utc_offset(Time.utc(2026, 3, 29, 0, 59, 59))
    assert_equal 2 * HOUR, Tripletex::OsloDate.utc_offset(Time.utc(2026, 3, 29, 1))
  end

  def test_moves_back_to_winter_time_at_one_utc_on_the_last_sunday_of_october
    assert_equal 2 * HOUR, Tripletex::OsloDate.utc_offset(Time.utc(2026, 10, 25, 0, 59, 59))
    assert_equal HOUR, Tripletex::OsloDate.utc_offset(Time.utc(2026, 10, 25, 1))
  end

  def test_finds_the_last_sunday_when_the_month_ends_on_one
    assert_equal HOUR, Tripletex::OsloDate.utc_offset(Time.utc(2024, 3, 31, 0, 59, 59))
    assert_equal 2 * HOUR, Tripletex::OsloDate.utc_offset(Time.utc(2024, 3, 31, 1))
  end

  def test_starts_tomorrow_at_oslo_midnight_in_winter
    assert_equal Date.new(2026, 3, 29), Tripletex::OsloDate.tomorrow(Time.utc(2026, 3, 28, 22, 59))
    assert_equal Date.new(2026, 3, 30), Tripletex::OsloDate.tomorrow(Time.utc(2026, 3, 28, 23))
    assert_equal Date.new(2026, 10, 26), Tripletex::OsloDate.tomorrow(Time.utc(2026, 10, 25, 22, 59))
    assert_equal Date.new(2026, 10, 27), Tripletex::OsloDate.tomorrow(Time.utc(2026, 10, 25, 23))
  end

  def test_starts_tomorrow_at_oslo_midnight_in_summer
    assert_equal Date.new(2026, 3, 30), Tripletex::OsloDate.tomorrow(Time.utc(2026, 3, 29, 21, 59))
    assert_equal Date.new(2026, 3, 31), Tripletex::OsloDate.tomorrow(Time.utc(2026, 3, 29, 22))
    assert_equal Date.new(2026, 10, 25), Tripletex::OsloDate.tomorrow(Time.utc(2026, 10, 24, 21, 59))
    assert_equal Date.new(2026, 10, 26), Tripletex::OsloDate.tomorrow(Time.utc(2026, 10, 24, 22))
  end

  def test_reads_a_time_in_any_zone_as_the_same_instant
    assert_equal Date.new(2026, 10, 6), Tripletex::OsloDate.tomorrow(Time.new(2026, 10, 4, 15, 30, 0, "-07:00"))
    assert_equal Date.new(2026, 10, 5), Tripletex::OsloDate.tomorrow(Time.new(2026, 10, 5, 9, 0, 0, "+13:00"))
  end

  def test_crosses_into_the_new_year
    assert_equal Date.new(2027, 1, 2), Tripletex::OsloDate.tomorrow(Time.utc(2026, 12, 31, 23, 30))
  end
end

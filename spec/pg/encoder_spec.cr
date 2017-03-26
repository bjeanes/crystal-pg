require "../spec_helper"

private def test_insert_and_read(datatype, value, extension = nil, file = __FILE__, line = __LINE__)
  it "inserts #{datatype}", file, line do
    begin
      PG_DB.exec "create extension \"#{extension}\"" if extension

      with_connection do |conn|
        conn.exec "drop table if exists test_table"
        conn.exec "create table test_table (v #{datatype})"

        # Read casting the value
        conn.exec "insert into test_table values ($1)", [value]
        actual_value = conn.query_one "select v from test_table", as: value.class
        actual_value.should eq(value)

        # Read without casting the value
        actual_value = conn.query_one "select v from test_table", &.read
        actual_value.should eq(value)
      end
    ensure
      PG_DB.exec "drop extension \"#{extension}\" cascade" if extension
    end
  end
end

describe PG::Driver, "encoder" do
  test_insert_and_read "int4", 123
  test_insert_and_read "float", 12.34
  test_insert_and_read "varchar", "hello world"
  test_insert_and_read "citext", "hello world", extension: "citext"
  test_insert_and_read "integer[]", [] of Int32
  test_insert_and_read "integer[]", [1, 2, 3]
  test_insert_and_read "integer[]", [[1, 2], [3, 4]]
  test_insert_and_read "point", PG::Geo::Point.new(1.2, 3.4)
  if Helper.db_version_gte(9, 4)
    test_insert_and_read "line", PG::Geo::Line.new(1.2, 3.4, 5.6)
  end
  test_insert_and_read "circle", PG::Geo::Circle.new(1.2, 3.4, 5.6)
  test_insert_and_read "lseg", PG::Geo::LineSegment.new(1.2, 3.4, 5.6, 7.8)
  test_insert_and_read "box", PG::Geo::Box.new(1.2, 3.4, 5.6, 7.8)
  test_insert_and_read "path", PG::Geo::Path.new([
    PG::Geo::Point.new(1.2, 3.4),
    PG::Geo::Point.new(5.6, 7.8),
  ], closed: false)
  test_insert_and_read "path", PG::Geo::Path.new([
    PG::Geo::Point.new(1.2, 3.4),
    PG::Geo::Point.new(5.6, 7.8),
  ], closed: true)
  test_insert_and_read "polygon", PG::Geo::Polygon.new([
    PG::Geo::Point.new(1.2, 3.4),
    PG::Geo::Point.new(5.6, 7.8),
  ])
  test_insert_and_read "timestamp", Time.new(2015, 2, 3, 17, 15, 13, kind: Time::Kind::Utc)
  test_insert_and_read "timestamp", Time.new(2015, 2, 3, 17, 15, 13, 11, Time::Kind::Utc)
end

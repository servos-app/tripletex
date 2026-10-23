require_relative "test_helper"

class Tripletex::ResourceTest < Minitest::Test
  include TripletexTestHelpers

  def setup
    respond_with_sessions("session-token")
    @customers = tripletex_client.customers
  end

  def test_retrieves_one_object_by_id
    respond_with_json({value: {id: 1, name: "Fjellstua"}})

    assert_equal({"id" => 1, "name" => "Fjellstua"}, @customers.retrieve(1, fields: "id,name"))
    assert_tripletex_request last_request, "GET", "/customer/1", query: {fields: "id,name"}
  end

  def test_lists_one_page_of_objects
    respond_with_json({values: [{id: 1}]})

    assert_equal [{"id" => 1}], @customers.list(email: "post@example.com")
    assert_tripletex_request last_request, "GET", "/customer", query: {email: "post@example.com"}
  end

  def test_walks_every_page_until_a_short_one
    full_page = Array.new(Tripletex::Resource::Listable::PAGE_SIZE) { |index| {id: index} }
    respond_with_json({values: full_page})
    respond_with_json({values: [{id: 1000}]})

    assert_equal 1001, @customers.each(isInactive: false).count
    assert_tripletex_request requests[1], "GET", "/customer", query: {isInactive: "false", from: "0", count: "1000"}
    assert_tripletex_request requests[2], "GET", "/customer", query: {isInactive: "false", from: "1000", count: "1000"}
    assert_equal 3, requests.size
  end

  def test_creates_an_object
    respond_with_json({value: {id: 1}}, status: 201)

    assert_equal({"id" => 1}, @customers.create({name: "Fjellstua"}))
    assert_tripletex_request last_request, "POST", "/customer", body: {name: "Fjellstua"}
  end

  def test_updates_an_object
    respond_with_json({value: {id: 1, version: 4}})

    assert_equal({"id" => 1, "version" => 4}, @customers.update(1, {version: 3, name: "Fjellstua"}))
    assert_tripletex_request last_request, "PUT", "/customer/1", body: {version: 3, name: "Fjellstua"}
  end

  def test_deletes_an_object
    transport.respond_with(status: 204)

    assert_nil @customers.delete(1)
    assert_tripletex_request last_request, "DELETE", "/customer/1"
  end
end

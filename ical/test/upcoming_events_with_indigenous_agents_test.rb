require 'minitest/autorun'
require 'linkeddata'
require_relative 'utils.rb'

class UpcomingEventsWithIndigenousAgentsTest < Minitest::Test
  def setup
    # file_path = File.expand_path("../upcoming_events_with_indigenous_agents.sparql", __dir__)
     file_path = File.expand_path("../test_sequence.sparql", __dir__)
    replacement_text = "values ?indigenousAgent { <http://example.com/performer-valid> <http://example.com/organizer-valid> }"  
    stubbed_sparql = Utils::replace_federated_service_call(File.read(file_path), replacement_text)
    stubbed_sparql.gsub!("from onto:explicit", "")
    @sparql_simplified = SPARQL.parse(stubbed_sparql)
  end


  def test_upcoming_events
    graph = RDF::Graph.load("./ical/test/fixtures/events.jsonld")
    results = graph.query(@sparql_simplified)
    assert  results.count > 0, "Expected at least one upcoming event with indigenous agents"
  end
end



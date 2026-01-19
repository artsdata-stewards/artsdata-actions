require 'minitest/autorun'
require 'linkeddata'
require_relative 'utils.rb'

class UpcomingEventsWithIndigenousInvolvementTest < Minitest::Test

  def setup
    # Load the SPARQL file 
    file_path = File.expand_path("../upcoming_events_with_indigenous_involvement.sparql", __dir__)
    replacement_text = "values ?indigenousAgent { <http://example.com/performer-valid> <http://example.com/organizer-valid> <http://example.com/performer-minimal> <http://example.com/performer-dual> <http://example.com/organizer-dual> <http://example.com/performer-multi-1> <http://example.com/performer-multi-2> <http://example.com/organizer-multi-1> <http://example.com/organizer-multi-2> }"  
    stubbed_sparql = Utils::replace_federated_service_call(File.read(file_path), replacement_text)
    stubbed_sparql.gsub!("from onto:explicit", "")
    @sparql_simplified = SPARQL.parse(stubbed_sparql)
    
    # Load the test fixture once
    @graph = RDF::Graph.load("./ical/test/fixtures/test_upcoming_events_with_indigenous_involvement.jsonld")
  end

  def test_upcoming_events_with_indigenous_involvement
   # puts "Loaded graph with #{@graph.count} triples"
    
    # Execute the simplified query
    results = @graph.query(@sparql_simplified)
    
    # Find all events
    event_uris = results.query([nil, RDF.type, RDF::Vocab::SCHEMA.Event]).map(&:subject).uniq

    # Show details of first few events
    event_uris.first(5).each do |event_uri|
      event_name = results.query([event_uri, RDF::Vocab::SCHEMA.name, nil]).first&.object
      event_date = results.query([event_uri, RDF::Vocab::SCHEMA.startDate, nil]).first&.object
      performers = results.query([event_uri, RDF::Vocab::SCHEMA.performer, nil]).map(&:object)
      organizers = results.query([event_uri, RDF::Vocab::SCHEMA.organizer, nil]).map(&:object)
      
      # puts "\nEvent: #{event_name}"
      # puts "  URI: #{event_uri}"
      # puts "  Date: #{event_date}"
      # puts "  Performers: #{performers.count}"
      # puts "  Organizers: #{organizers.count}"
    end
    
    # Assertions
    assert results.count > 0, "Expected some results from the CONSTRUCT query"
    assert event_uris.count > 0, "Expected to find at least one event with indigenous involvement"
  end

  def test_events_have_required_properties
    results = @graph.query(@sparql_simplified)
    
    event_uris = results.query([nil, RDF.type, RDF::Vocab::SCHEMA.Event]).map(&:subject).uniq
    
    event_uris.first(3).each do |event_uri|
      # Check required properties
      assert results.query([event_uri, RDF::Vocab::SCHEMA.name, nil]).count > 0, 
             "Event #{event_uri} should have a name"
      assert results.query([event_uri, RDF::Vocab::SCHEMA.startDate, nil]).count > 0,
             "Event #{event_uri} should have a startDate"
      assert results.query([event_uri, RDF::Vocab::SCHEMA.url, nil]).count > 0,
             "Event #{event_uri} should have a url"
    end
  end

  def test_no_events_with_indigenous_involvement
    # Query for the non-indigenous event in the fixture
    results = @graph.query(@sparql_simplified)
    event_uris = results.query([nil, RDF.type, RDF::Vocab::SCHEMA.Event]).map(&:subject).uniq
    
    # The non-indigenous event should NOT be in the results
    non_indigenous_event = RDF::URI("http://example.com/event-non-indigenous")
    refute event_uris.include?(non_indigenous_event), "Should not find events without indigenous involvement"
  end

  def test_event_with_missing_optional_properties
    # Query for the minimal event in the fixture
    results = @graph.query(@sparql_simplified)
    event_uris = results.query([nil, RDF.type, RDF::Vocab::SCHEMA.Event]).map(&:subject).uniq
    
    minimal_event = RDF::URI("http://example.com/event-minimal")
    assert event_uris.include?(minimal_event), "Should find event even if optional properties are missing"
    
    # Verify it has the basic required properties
    assert_equal "Minimal Indigenous Event", results.query([minimal_event, RDF::Vocab::SCHEMA.name, nil]).first.object.to_s
  end

  def test_event_with_both_performer_and_organizer_indigenous
    results = @graph.query(@sparql_simplified)
    event_uris = results.query([nil, RDF.type, RDF::Vocab::SCHEMA.Event]).map(&:subject).uniq
    
    dual_event = RDF::URI("http://example.com/event-dual")
    assert event_uris.include?(dual_event), "Should find event with both indigenous performer and organizer"
    
    assert_equal "Dual Indigenous Event", results.query([dual_event, RDF::Vocab::SCHEMA.name, nil]).first.object.to_s
    assert results.query([dual_event, RDF::Vocab::SCHEMA.performer, nil]).count > 0
    assert results.query([dual_event, RDF::Vocab::SCHEMA.organizer, nil]).count > 0
  end

  def test_event_with_multiple_indigenous_performers_and_organizers
    results = @graph.query(@sparql_simplified)
    event_uris = results.query([nil, RDF.type, RDF::Vocab::SCHEMA.Event]).map(&:subject).uniq
    
    multi_event = RDF::URI("http://example.com/event-multi")
    assert event_uris.include?(multi_event), "Should find event with multiple indigenous performers and organizers"
    
    assert_equal 2, results.query([multi_event, RDF::Vocab::SCHEMA.performer, nil]).count
    assert_equal 2, results.query([multi_event, RDF::Vocab::SCHEMA.organizer, nil]).count
  end

  def test_with_indigenous_calendar_events
    named_graph = RDF::Graph.load("./ical/test/fixtures/indigenous_calendar_event.jsonld")

    results = named_graph.query(@sparql_simplified)
    event_uris = results.query([nil, RDF.type, RDF::Vocab::SCHEMA.Event]).map(&:subject).uniq
    
    indigenous_calendar_event = RDF::URI("http://example.com/event-indigenous-calendar")
    assert event_uris.include?(indigenous_calendar_event), "Should find event from Indigenous Calendar"
    
  end

  def test_with_both_wikidata_agents_and_indigenous_calendar_events
    @graph << RDF::Graph.load("./ical/test/fixtures/indigenous_calendar_event.jsonld")

    results = @graph.query(@sparql_simplified)
    event_uris = results.query([nil, RDF.type, RDF::Vocab::SCHEMA.Event]).map(&:subject).uniq
   
    assert event_uris.include?(RDF::URI("http://example.com/event-indigenous-calendar")), "Should find event from Indigenous Calendar"
    assert event_uris.include?(RDF::URI("http://example.com/event-multi")), "Should find event with multiple indigenous performers and organizers"
   
  end

  def test_event_series_with_super_event
    graph = RDF::Graph.load("./ical/test/fixtures/event_series.jsonld")

    results = graph.query(@sparql_simplified)
    # puts "Results: #{results.dump(:ttl)}"

    event_uris = results.query([nil, RDF.type, RDF::Vocab::SCHEMA.Event]).map(&:subject).uniq
    assert event_uris.include?(RDF::URI("http://example.com/event-valid")), "Should find event event-valid"
    
    url = results.query([RDF::URI("http://example.com/event-valid"), RDF::Vocab::SCHEMA.url, nil]).first&.object&.to_s
    assert_equal "http://example.com/event/super-event-valid",url,"URL should be from super-event"

  end

end
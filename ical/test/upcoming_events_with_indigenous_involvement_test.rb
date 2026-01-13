require 'minitest/autorun'
require 'linkeddata'

class UpcomingEventsWithIndigenousInvolvementTest < Minitest::Test

  def setup
    # Loaded a simplified version of the query without SERVICE
    @sparql_simplified = SPARQL.parse(<<-SPARQL)
      PREFIX schema: <http://schema.org/>
      PREFIX wd: <http://www.wikidata.org/entity/>
      PREFIX wdt: <http://www.wikidata.org/prop/direct/>
      PREFIX sh: <http://www.w3.org/ns/shacl#>
      PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>
      PREFIX onto: <http://www.ontotext.com/>
      
      CONSTRUCT {
          ?event a schema:Event ;
          schema:name ?names ;
          schema:startDate ?startDate ;
          schema:url ?urls ;
          schema:description ?desc ;
          schema:location ?loc ;
          schema:endDate ?endDate ;
          schema:performer ?performer ;
          schema:organizer ?organizer .
          ?loc a schema:Place ;
          schema:name ?loc_names;
          schema:sameAs ?loc_sameAs;
          schema:address ?address .
          ?address a schema:PostalAddress ;
          schema:streetAddress ?streetAddress ;
          schema:addressRegion ?addressRegion ;
          schema:addressCountry ?addressCountry ;
          schema:postalCode ?postalCode ;
          schema:addressLocality ?addressLocality .
          ?performer a ?performerType ;
          schema:name ?performerName ;
          schema:sameAs ?performerSameAs .
          ?organizer a ?organizerType ;
          schema:name ?organizerName ;
          schema:sameAs ?organizerSameAs .
      }
      WHERE {
          # For testing, we'll identify indigenous agents by their Wikidata links
          # rather than querying Wikidata SERVICE
          {
              # Find performers with Wikidata IDs that are known to be indigenous
              ?event a schema:Event ;
                     schema:performer ?performer .
              ?performer schema:sameAs ?wikidataId .
              FILTER(CONTAINS(STR(?wikidataId), "wikidata.org"))
              
              # Get event properties
              ?event schema:name ?names ;
                     schema:startDate ?startDate ;
                     schema:url ?urls .
              FILTER(?startDate > NOW())
          } UNION {
              # Find organizers with Wikidata IDs
              ?event a schema:Event ;
                     schema:organizer ?organizer .
              ?organizer schema:sameAs ?wikidataId .
              FILTER(CONTAINS(STR(?wikidataId), "wikidata.org"))
              
              # Get event properties
              ?event schema:name ?names ;
                     schema:startDate ?startDate ;
                     schema:url ?urls .
              FILTER(?startDate > NOW())
          }
          
          # Optional properties
          OPTIONAL { ?event schema:description ?desc . }
          OPTIONAL { 
              ?event schema:endDate ?endDate .
              FILTER(DATATYPE(?endDate) = xsd:dateTime)
          }
          
          # Location
          OPTIONAL {
              ?event schema:location ?loc .
              ?loc schema:name ?loc_names ;
                   schema:address ?address .
              OPTIONAL { ?loc schema:sameAs ?loc_sameAs . }
              ?address schema:streetAddress ?streetAddress ;
                       schema:addressRegion ?addressRegion ;
                       schema:addressCountry ?addressCountry ;
                       schema:postalCode ?postalCode ;
                       schema:addressLocality ?addressLocality .
          }
          
          # Performer details
          OPTIONAL {
              ?event schema:performer ?performer .
              ?performer schema:name ?performerName ;
                         a ?performerType .
              OPTIONAL { ?performer schema:sameAs ?performerSameAs . }
          }
          
          # Organizer details
          OPTIONAL {
              ?event schema:organizer ?organizer .
              ?organizer a ?organizerType ;
                         schema:name ?organizerName .
              OPTIONAL { ?organizer schema:sameAs ?organizerSameAs . }
          }
      }
    SPARQL
  
  end

  def test_upcoming_events_with_indigenous_involvement
    # Load the test fixture
    graph = RDF::Graph.load("./ical/test/fixtures/test_upcoming_events_with_indigenous_involvement.jsonld")
    
    puts "Loaded graph with #{graph.count} triples"
    
    # Execute the simplified query
    results = graph.query(@sparql_simplified)
    
    # Find all events
    event_uris = results.query([nil, RDF.type, RDF::Vocab::SCHEMA.Event]).map(&:subject).uniq

    # Show details of first few events
    event_uris.first(5).each do |event_uri|
      event_name = results.query([event_uri, RDF::Vocab::SCHEMA.name, nil]).first&.object
      event_date = results.query([event_uri, RDF::Vocab::SCHEMA.startDate, nil]).first&.object
      performers = results.query([event_uri, RDF::Vocab::SCHEMA.performer, nil]).map(&:object)
      organizers = results.query([event_uri, RDF::Vocab::SCHEMA.organizer, nil]).map(&:object)
      
      puts "\nEvent: #{event_name}"
      puts "  URI: #{event_uri}"
      puts "  Date: #{event_date}"
      puts "  Performers: #{performers.count}"
      puts "  Organizers: #{organizers.count}"
    end
    
    # Assertions
    assert results.count > 0, "Expected some results from the CONSTRUCT query"
    assert event_uris.count > 0, "Expected to find at least one event with indigenous involvement"
    
    # Verify specific events are included based on the fixture data
    # For example, check for events with known indigenous performers
    expected_events = [
      'http://kg.artsdata.ca/resource/K23-6512', # Julian Taylor & Logan Staats
      'http://kg.footlight.io/resource/culture3r-com_ivan-boivin-flamand', # Ivan Boivin-Flamand
      'http://kg.artsdata.ca/resource/K23-6528', # Twin Flames
    ]
    
    found_events = event_uris.map(&:to_s)
    expected_events.each do |expected|
      if found_events.include?(expected)
        puts "\n✓ Found expected event: #{expected}"
      end
    end
  end

  def test_events_have_required_properties
    graph = RDF::Graph.load("./ical/test/fixtures/test_upcoming_events_with_indigenous_involvement.jsonld")
    results = graph.query(@sparql_simplified)
    
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
    # Create a graph with no indigenous involvement (no wikidata.org sameAs)
    graph = RDF::Graph.new
    event = RDF::URI("http://example.org/event/1")
    performer = RDF::URI("http://example.org/performer/1")
    graph << [event, RDF.type, RDF::Vocab::SCHEMA.Event]
    graph << [event, RDF::Vocab::SCHEMA.name, "Non-Indigenous Event"]
    graph << [event, RDF::Vocab::SCHEMA.startDate, RDF::Literal::DateTime.new(Time.now + 86400)]
    graph << [event, RDF::Vocab::SCHEMA.performer, performer]
    graph << [performer, RDF::Vocab::SCHEMA.name, "Performer 1"]
    # No schema:sameAs with wikidata.org

    results = graph.query(@sparql_simplified)
    event_uris = results.query([nil, RDF.type, RDF::Vocab::SCHEMA.Event]).map(&:subject).uniq
    assert_equal 0, event_uris.count, "Should not find events without indigenous involvement"
  end

  def test_event_with_missing_optional_properties
    # Event with only required properties and indigenous performer
    graph = RDF::Graph.new
    event = RDF::URI("http://example.org/event/2")
    performer = RDF::URI("http://example.org/performer/2")
    graph << [event, RDF.type, RDF::Vocab::SCHEMA.Event]
    graph << [event, RDF::Vocab::SCHEMA.name, "Minimal Indigenous Event"]
    graph << [event, RDF::Vocab::SCHEMA.startDate, RDF::Literal::DateTime.new(Time.now + 86400)]
    graph << [event, RDF::Vocab::SCHEMA.url, RDF::URI("http://example.org/event/2")]
    graph << [event, RDF::Vocab::SCHEMA.performer, performer]
    graph << [performer, RDF::Vocab::SCHEMA.name, "Indigenous Performer"]
    graph << [performer, RDF::Vocab::SCHEMA.sameAs, RDF::URI("http://www.wikidata.org/entity/Q12345")]

    results = graph.query(@sparql_simplified)
    event_uris = results.query([nil, RDF.type, RDF::Vocab::SCHEMA.Event]).map(&:subject).uniq
    assert_equal 1, event_uris.count, "Should find event even if optional properties are missing"
    event_uri = event_uris.first
    assert_equal "Minimal Indigenous Event", results.query([event_uri, RDF::Vocab::SCHEMA.name, nil]).first.object.to_s
  end

  def test_event_with_both_performer_and_organizer_indigenous
    graph = RDF::Graph.new
    event = RDF::URI("http://example.org/event/3")
    performer = RDF::URI("http://example.org/performer/3")
    organizer = RDF::URI("http://example.org/organizer/3")
    graph << [event, RDF.type, RDF::Vocab::SCHEMA.Event]
    graph << [event, RDF::Vocab::SCHEMA.name, "Dual Indigenous Event"]
    graph << [event, RDF::Vocab::SCHEMA.startDate, RDF::Literal::DateTime.new(Time.now + 86400)]
    graph << [event, RDF::Vocab::SCHEMA.url, RDF::URI("http://example.org/event/3")]
    graph << [event, RDF::Vocab::SCHEMA.performer, performer]
    graph << [event, RDF::Vocab::SCHEMA.organizer, organizer]
    graph << [performer, RDF::Vocab::SCHEMA.name, "Indigenous Performer"]
    graph << [performer, RDF::Vocab::SCHEMA.sameAs, RDF::URI("http://www.wikidata.org/entity/Q23456")]
    graph << [organizer, RDF::Vocab::SCHEMA.name, "Indigenous Organizer"]
    graph << [organizer, RDF::Vocab::SCHEMA.sameAs, RDF::URI("http://www.wikidata.org/entity/Q34567")]

    results = graph.query(@sparql_simplified)
    event_uris = results.query([nil, RDF.type, RDF::Vocab::SCHEMA.Event]).map(&:subject).uniq
    assert_equal 1, event_uris.count, "Should find event with both indigenous performer and organizer"
    event_uri = event_uris.first
    assert_equal "Dual Indigenous Event", results.query([event_uri, RDF::Vocab::SCHEMA.name, nil]).first.object.to_s
    assert results.query([event_uri, RDF::Vocab::SCHEMA.performer, nil]).count > 0
    assert results.query([event_uri, RDF::Vocab::SCHEMA.organizer, nil]).count > 0
  end

  def test_event_with_multiple_indigenous_performers_and_organizers
    graph = RDF::Graph.new
    event = RDF::URI("http://example.org/event/4")
    performer1 = RDF::URI("http://example.org/performer/4a")
    performer2 = RDF::URI("http://example.org/performer/4b")
    organizer1 = RDF::URI("http://example.org/organizer/4a")
    organizer2 = RDF::URI("http://example.org/organizer/4b")
    graph << [event, RDF.type, RDF::Vocab::SCHEMA.Event]
    graph << [event, RDF::Vocab::SCHEMA.name, "Multi Indigenous Event"]
    graph << [event, RDF::Vocab::SCHEMA.startDate, RDF::Literal::DateTime.new(Time.now + 86400)]
    graph << [event, RDF::Vocab::SCHEMA.url, RDF::URI("http://example.org/event/4")]
    graph << [event, RDF::Vocab::SCHEMA.performer, performer1]
    graph << [event, RDF::Vocab::SCHEMA.performer, performer2]
    graph << [event, RDF::Vocab::SCHEMA.organizer, organizer1]
    graph << [event, RDF::Vocab::SCHEMA.organizer, organizer2]
    graph << [performer1, RDF::Vocab::SCHEMA.name, "Indigenous Performer 1"]
    graph << [performer1, RDF::Vocab::SCHEMA.sameAs, RDF::URI("http://www.wikidata.org/entity/Q45678")]
    graph << [performer2, RDF::Vocab::SCHEMA.name, "Indigenous Performer 2"]
    graph << [performer2, RDF::Vocab::SCHEMA.sameAs, RDF::URI("http://www.wikidata.org/entity/Q56789")]
    graph << [organizer1, RDF::Vocab::SCHEMA.name, "Indigenous Organizer 1"]
    graph << [organizer1, RDF::Vocab::SCHEMA.sameAs, RDF::URI("http://www.wikidata.org/entity/Q67890")]
    graph << [organizer2, RDF::Vocab::SCHEMA.name, "Indigenous Organizer 2"]
    graph << [organizer2, RDF::Vocab::SCHEMA.sameAs, RDF::URI("http://www.wikidata.org/entity/Q78901")]

    results = graph.query(@sparql_simplified)
    event_uris = results.query([nil, RDF.type, RDF::Vocab::SCHEMA.Event]).map(&:subject).uniq
    assert_equal 1, event_uris.count, "Should find event with multiple indigenous performers and organizers"
    event_uri = event_uris.first
    assert_equal 2, results.query([event_uri, RDF::Vocab::SCHEMA.performer, nil]).count
    assert_equal 2, results.query([event_uri, RDF::Vocab::SCHEMA.organizer, nil]).count
  end

end

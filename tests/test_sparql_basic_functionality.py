"""Basic functionality tests for SPARQL queries."""

import pytest
from pathlib import Path
from rdflib import Graph, Namespace, RDF, URIRef, Literal
from rdflib.namespace import XSD
from tests.utils import replace_federated_service_call


SCHEMA = Namespace("http://schema.org/")


class TestSPARQLBasicFunctionality:
    """Test basic SPARQL query functionality with simple test data."""
    
    def test_simple_select_query_execution(self):
        """Test executing a simplified SELECT query."""
        # Create simple test data
        graph = Graph()
        graph.bind("schema", SCHEMA)
        
        event = URIRef("http://example.com/event1")
        graph.add((event, RDF.type, SCHEMA.Event))
        graph.add((event, SCHEMA.name, Literal("Test Event")))
        graph.add((event, SCHEMA.startDate, Literal("2026-06-01T19:00:00", datatype=XSD.dateTime)))
        
        # Simple query
        query = """
        PREFIX schema: <http://schema.org/>
        SELECT ?event ?name WHERE {
            ?event a schema:Event ;
                   schema:name ?name .
        }
        """
        
        results = list(graph.query(query))
        assert len(results) == 1, "Should find one event"
        assert results[0][1] == Literal("Test Event"), "Should match event name"
    
    def test_simple_construct_query_execution(self):
        """Test executing a simplified CONSTRUCT query."""
        # Create simple test data
        graph = Graph()
        graph.bind("schema", SCHEMA)
        
        event = URIRef("http://example.com/event1")
        performer = URIRef("http://example.com/performer1")
        
        graph.add((event, RDF.type, SCHEMA.Event))
        graph.add((event, SCHEMA.name, Literal("Test Event")))
        graph.add((event, SCHEMA.performer, performer))
        graph.add((performer, SCHEMA.name, Literal("Test Performer")))
        
        # Simple CONSTRUCT query
        query = """
        PREFIX schema: <http://schema.org/>
        CONSTRUCT {
            ?event a schema:Event ;
                   schema:name ?name ;
                   schema:performer ?performer .
            ?performer schema:name ?performerName .
        }
        WHERE {
            ?event a schema:Event ;
                   schema:name ?name ;
                   schema:performer ?performer .
            ?performer schema:name ?performerName .
        }
        """
        
        results = graph.query(query)
        result_graph = Graph()
        for triple in results:
            result_graph.add(triple)
        
        # Verify constructed graph
        events = list(result_graph.subjects(RDF.type, SCHEMA.Event))
        assert len(events) == 1, "Should construct one event"
        assert result_graph.value(events[0], SCHEMA.name) == Literal("Test Event")
    
    def test_filtered_query_with_date(self):
        """Test query with date filtering (future events)."""
        graph = Graph()
        graph.bind("schema", SCHEMA)
        
        # Past event
        past_event = URIRef("http://example.com/event-past")
        graph.add((past_event, RDF.type, SCHEMA.Event))
        graph.add((past_event, SCHEMA.name, Literal("Past Event")))
        graph.add((past_event, SCHEMA.startDate, Literal("2020-01-01T19:00:00", datatype=XSD.dateTime)))
        
        # Future event
        future_event = URIRef("http://example.com/event-future")
        graph.add((future_event, RDF.type, SCHEMA.Event))
        graph.add((future_event, SCHEMA.name, Literal("Future Event")))
        graph.add((future_event, SCHEMA.startDate, Literal("2026-12-31T19:00:00", datatype=XSD.dateTime)))
        
        # Query for events after June 2026
        query = """
        PREFIX schema: <http://schema.org/>
        PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>
        SELECT ?event ?name WHERE {
            ?event a schema:Event ;
                   schema:name ?name ;
                   schema:startDate ?date .
            FILTER(?date > "2026-06-01T00:00:00"^^xsd:dateTime)
        }
        """
        
        results = list(graph.query(query))
        assert len(results) == 1, "Should find only future event"
        assert results[0][1] == Literal("Future Event")
    
    def test_optional_properties(self):
        """Test query with optional properties."""
        graph = Graph()
        graph.bind("schema", SCHEMA)
        
        # Event with URL
        event1 = URIRef("http://example.com/event1")
        graph.add((event1, RDF.type, SCHEMA.Event))
        graph.add((event1, SCHEMA.name, Literal("Event 1")))
        graph.add((event1, SCHEMA.url, URIRef("http://example.com/url1")))
        
        # Event without URL
        event2 = URIRef("http://example.com/event2")
        graph.add((event2, RDF.type, SCHEMA.Event))
        graph.add((event2, SCHEMA.name, Literal("Event 2")))
        
        # Query with optional URL
        query = """
        PREFIX schema: <http://schema.org/>
        SELECT ?event ?name ?url WHERE {
            ?event a schema:Event ;
                   schema:name ?name .
            OPTIONAL { ?event schema:url ?url . }
        }
        """
        
        results = list(graph.query(query))
        assert len(results) == 2, "Should find both events"
        
        # Check that one has URL and one doesn't
        urls = [r[2] for r in results]
        assert URIRef("http://example.com/url1") in urls
        assert None in urls

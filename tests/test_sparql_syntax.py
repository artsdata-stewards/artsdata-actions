"""Tests for SPARQL query syntax validation."""

import pytest
from pathlib import Path
from rdflib.plugins.sparql import prepareQuery
from tests.utils import replace_federated_service_call


class TestSPARQLSyntax:
    """Test suite for validating SPARQL query syntax."""
    
    def test_upcoming_events_with_indigenous_agents_select_syntax(self):
        """Test that the SELECT query parses correctly."""
        sparql_file = Path(__file__).parent.parent / "queries" / "upcoming_events_with_indigenous_agents.sparql"
        sparql_text = sparql_file.read_text()
        
        # Replace federated SERVICE call
        replacement_text = "values ?indigenousAgent { <http://example.com/test> }"
        stubbed_sparql = replace_federated_service_call(sparql_text, replacement_text)
        stubbed_sparql = stubbed_sparql.replace("from onto:explicit", "")
        
        # Test that the query parses without errors
        try:
            query = prepareQuery(stubbed_sparql)
            assert query is not None, "Query should parse successfully"
        except Exception as e:
            pytest.fail(f"Query failed to parse: {e}")
    
    def test_upcoming_events_with_indigenous_agents_construct_syntax(self):
        """Test that the CONSTRUCT query parses correctly."""
        sparql_file = Path(__file__).parent.parent / "ical" / "upcoming_events_with_indigenous_agents.sparql"
        sparql_text = sparql_file.read_text()
        
        # Replace federated SERVICE call
        replacement_text = "values ?indigenousAgent { <http://example.com/test> }"
        stubbed_sparql = replace_federated_service_call(sparql_text, replacement_text)
        stubbed_sparql = stubbed_sparql.replace("from onto:explicit", "")
        
        # Test that the query parses without errors
        try:
            query = prepareQuery(stubbed_sparql)
            assert query is not None, "Query should parse successfully"
        except Exception as e:
            pytest.fail(f"Query failed to parse: {e}")
    
    def test_replace_federated_service_call(self):
        """Test that the utility function replaces SERVICE blocks correctly."""
        test_sparql = """
        PREFIX wd: <http://www.wikidata.org/entity/>
        SELECT * WHERE {
            SERVICE <https://query.wikidata.org/sparql> {
                ?s ?p ?o .
                { ?nested ?in ?block }
            }
            ?other ?triples ?here .
        }
        """
        
        replacement = "VALUES ?s { <http://example.com/test> }"
        result = replace_federated_service_call(test_sparql, replacement)
        
        # Verify SERVICE block was replaced
        assert "SERVICE" not in result, "SERVICE keyword should be removed"
        assert "VALUES ?s" in result, "Replacement text should be present"
        assert "?other ?triples ?here" in result, "Other parts should be preserved"

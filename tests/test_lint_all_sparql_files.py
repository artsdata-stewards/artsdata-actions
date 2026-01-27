"""Tests to lint all SPARQL files in queries/ and ical/ directories."""

import pytest
from pathlib import Path
from rdflib.plugins.sparql import prepareQuery
from tests.utils import replace_federated_service_call


# Get the project root directory
PROJECT_ROOT = Path(__file__).parent.parent

# Discover all SPARQL files in queries/ and ical/ directories
QUERIES_DIR = PROJECT_ROOT / "queries"
ICAL_DIR = PROJECT_ROOT / "ical"

def get_all_sparql_files():
    """Get all SPARQL files from queries/ and ical/ directories."""
    sparql_files = []
    
    # Get files from queries/ directory
    if QUERIES_DIR.exists():
        sparql_files.extend(QUERIES_DIR.glob("*.sparql"))
    
    # Get files from ical/ directory
    if ICAL_DIR.exists():
        sparql_files.extend(ICAL_DIR.glob("*.sparql"))
    
    return sorted(sparql_files)


# Generate test parameters (file path and name for test ID)
SPARQL_FILES = [(f, f.stem) for f in get_all_sparql_files()]


class TestLintAllSPARQLFiles:
    """Test suite for linting all SPARQL files."""
    
    @pytest.mark.parametrize("sparql_file,file_name", SPARQL_FILES, ids=[name for _, name in SPARQL_FILES])
    def test_sparql_file_syntax(self, sparql_file, file_name):
        """Test that each SPARQL file has valid syntax."""
        # Read the SPARQL file
        sparql_text = sparql_file.read_text()
        
        # Check if file uses RDF-star syntax (not supported by rdflib)
        # RDF-star uses quoted triples like << ?s ?p ?o >>
        if "<<" in sparql_text and ">>" in sparql_text:
            # Basic validation: check that file has valid prefixes and basic structure
            assert "PREFIX" in sparql_text or "prefix" in sparql_text, \
                f"Query from {sparql_file.name} should have PREFIX declarations"
            assert ("select" in sparql_text.lower() or "construct" in sparql_text.lower() or 
                    "ask" in sparql_text.lower() or "describe" in sparql_text.lower()), \
                f"Query from {sparql_file.name} should have a query type (SELECT/CONSTRUCT/ASK/DESCRIBE)"
            assert "where" in sparql_text.lower() or "WHERE" in sparql_text, \
                f"Query from {sparql_file.name} should have a WHERE clause"
            # Mark as valid since basic structure is correct (RDF-star syntax requires advanced parser)
            pytest.skip(f"Skipping {sparql_file.name}: uses RDF-star syntax not supported by rdflib")
            return
        
        # Replace federated SERVICE call with stub data if present
        # This is needed because rdflib cannot parse SERVICE calls without network access
        replacement_text = "VALUES ?stub { <http://example.com/stub> }"
        stubbed_sparql = replace_federated_service_call(sparql_text, replacement_text)
        
        # Remove vendor-specific 'from onto:explicit' clause that rdflib doesn't understand
        stubbed_sparql = stubbed_sparql.replace("from onto:explicit", "")
        
        # Test that the query parses without errors
        try:
            query = prepareQuery(stubbed_sparql)
            assert query is not None, f"Query from {sparql_file.name} should parse successfully"
        except Exception as e:
            pytest.fail(f"Query from {sparql_file.name} failed to parse: {e}")
    
    def test_all_sparql_files_discovered(self):
        """Verify that SPARQL files are being discovered from both directories."""
        sparql_files = get_all_sparql_files()
        
        # Count files from each directory
        queries_files = [f for f in sparql_files if "queries" in str(f)]
        ical_files = [f for f in sparql_files if "ical" in str(f)]
        
        assert len(sparql_files) > 0, "Should discover at least one SPARQL file"
        assert len(queries_files) > 0, "Should discover SPARQL files in queries/ directory"
        assert len(ical_files) > 0, "Should discover SPARQL files in ical/ directory"
        
        print(f"\nDiscovered {len(sparql_files)} SPARQL files:")
        print(f"  - {len(queries_files)} files in queries/")
        print(f"  - {len(ical_files)} files in ical/")

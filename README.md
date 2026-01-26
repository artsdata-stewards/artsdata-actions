# artsdata-actions

This repository contains SPARQL queries and actions for working with Artsdata.

## Testing

This repository includes both Ruby and Python unit tests for SPARQL queries.

### Python Tests

Python tests are located in the `tests/` directory and test SPARQL query syntax and basic functionality.

#### Prerequisites

- Python 3.7 or higher
- pip (Python package manager)

#### Setup

1. Install Python dependencies:

```bash
pip install -r requirements.txt
```

This will install:
- `rdflib` - RDF library for parsing and querying
- `pytest` - Testing framework

#### Running Tests

To run all Python tests:

```bash
pytest tests/
```

To run tests with verbose output:

```bash
pytest tests/ -v
```

To run a specific test file:

```bash
pytest tests/test_sparql_syntax.py -v
```

#### Test Structure

The Python tests include:

- **`test_sparql_syntax.py`** - Validates that SPARQL queries parse correctly
  - Tests syntax of SELECT queries
  - Tests syntax of CONSTRUCT queries
  - Tests the utility function for replacing federated SERVICE calls

- **`test_sparql_basic_functionality.py`** - Tests basic SPARQL query functionality
  - Tests simple SELECT query execution
  - Tests simple CONSTRUCT query execution
  - Tests filtering with date conditions
  - Tests optional properties in queries

- **`tests/utils.py`** - Utility functions for testing
  - `replace_federated_service_call()` - Replaces Wikidata SERVICE blocks with test data

- **`tests/fixtures/`** - Test data in Turtle (`.ttl`) format
  - Event data for testing queries
  - Uses Turtle format to avoid network dependencies

### Ruby Tests

Ruby tests are located in the `ical/test/` directory.

#### Prerequisites

- Ruby (version specified in `.ruby-version`)
- Bundler

#### Setup

1. Install Ruby dependencies:

```bash
bundle install
```

#### Running Tests

To run all Ruby tests:

```bash
rake test
```

Or use bundle:

```bash
bundle exec rake test
```

## SPARQL Queries

SPARQL queries are located in two directories:

- **`queries/`** - General SPARQL queries (mostly SELECT queries)
- **`ical/`** - SPARQL queries for iCal generation (mostly CONSTRUCT queries)

### Example Queries

- `queries/upcoming_events_with_indigenous_agents.sparql` - SELECT query for finding upcoming events with indigenous performers or organizers
- `ical/upcoming_events_with_indigenous_agents.sparql` - CONSTRUCT query for building event data for iCal export

## Contributing

When adding new SPARQL queries:

1. Add the `.sparql` file to the appropriate directory (`queries/` or `ical/`)
2. Add Python tests in `tests/` to validate syntax
3. Add Ruby tests in `ical/test/` if the query is for iCal generation
4. Run all tests to ensure they pass

## License

[Add license information here]

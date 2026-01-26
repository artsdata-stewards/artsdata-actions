"""Utility functions for SPARQL testing."""

import re


def replace_federated_service_call(sparql_text: str, replacement_text: str) -> str:
    """
    Replace a federated SERVICE call with stub data.
    
    This function finds a SERVICE <https://query.wikidata.org/sparql> block
    and replaces it with the provided replacement text. This allows testing
    SPARQL queries without making actual federated queries.
    
    Args:
        sparql_text: The SPARQL query text containing a SERVICE call
        replacement_text: The text to replace the SERVICE block with
        
    Returns:
        The modified SPARQL query text
    """
    start_tag = 'SERVICE <https://query.wikidata.org/sparql>'
    start_pos = sparql_text.find(start_tag)
    
    if start_pos == -1:
        return sparql_text
    
    # Find the opening brace of the SERVICE block
    service_start = sparql_text.find('{', start_pos)
    if service_start == -1:
        return sparql_text
    
    # Find the matching closing brace
    depth = 1
    i = service_start + 1
    
    while i < len(sparql_text) and depth > 0:
        char = sparql_text[i]
        if char == '{':
            depth += 1
        elif char == '}':
            depth -= 1
        i += 1
    
    if depth == 0:
        # Found the matching closing brace
        # Replace the entire SERVICE block (including SERVICE keyword and braces)
        return sparql_text[:start_pos] + replacement_text + sparql_text[i:]
    
    # No matching closing brace found
    return sparql_text

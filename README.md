# IMDB Actor/Show Network Analysis

This repository contains a R script `imdb_network_analysis.R` that analyzes the connections between different actors and television shows using data pulled directly from IMDB. This script takes a predefined list of television shows,
gathers data about the cast of each show, and then forms a network to analyze the relationships.

## Dependencies

The script requires the following R libraries:

- `tidyverse`
- `rvest` (which is included in tidyverse but listed here for clarity, it's used for web scraping)

Please make sure to install these before running the script.

## Usage

```bash
Rscript imdb_network_analysis.R
```

### Script Walkthrough

The script works as follows:

1. Defines a list of IMDB IDs for a set of television shows (default: "Brooklyn 99", "The Office", "Parks and Rec", "Superstore", "New Girl", "Modern Family", "Veep", "Good Place").
2. For each show, it scrapes the IMDB full credits page to get a list of the actors and the characters they play.
3. It then processes this data to create a tidy data frame with columns for the actor, character, show, and number of episodes in which the actor appeared.
4. This data is then transformed into a graph structure, with nodes for actors and shows, and edges representing an actor's appearance in a show. The graph is then exported as CSV files ready for importing into a Neo4j database.
5. The script then runs a command to import the graph into Neo4j. You must have Neo4j installed and running on your local machine for this step to work.

**NOTE:** The script is hardcoded to write the output CSV files to a specific location on a user's machine. You will need to modify this to suit your system's configuration. The location is set in the `dbs_location` variable.

## Output

The script outputs three CSV files: `programs.csv`, `actors.csv`, and `edges.csv`, representing the shows, actors, and the relationships between them respectively.

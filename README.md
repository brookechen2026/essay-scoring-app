# Essay Scoring and Exploration App

An R Shiny course project by Xiaoxi (Brooke) Chen for STAT 385 at the University of Illinois Urbana-Champaign (December 2025).

## Overview

The application combines interactive exploration of essay scores with a rule-based scoring demonstration for custom text. It provides assignment and score-range filters, score-distribution charts, searchable essay previews, and summary statistics.

## Features

- Filter the dataset by assignment and score range using reactive controls.
- Explore score distributions with ggplot2 and essay previews with DT tables.
- Enter custom text to calculate word count, sentence count, character count, and average sentence length.
- Generate a heuristic score from 1 to 6 and a corresponding feedback category.

## Implementation

`app.R` defines the Shiny interface, data preparation, reactive filters, and visualizations. `R/scoring_functions.R` contains reusable text-statistics and scoring functions. The application uses shiny, shinythemes, DT, ggplot2, dplyr, readr, and stringr.

## Run locally

1. Install R and optionally RStudio.
2. Install the required packages in an R console:

```r
install.packages(c("shiny", "shinythemes", "DT", "ggplot2", "dplyr", "readr", "stringr"))
```

3. Place the original project dataset at `data/essays.csv`. See `data/README.md` for the required columns. The dataset is not bundled here.
4. From the project directory, run:

```r
shiny::runApp(".")
```

## Data and scope

The original local CSV contains 24,728 records. The application filters records with missing scores or very short text and samples up to 2,000 records for interactive performance. The original project documentation identifies the data as ASAP 2.0; its exact source and redistribution terms should be confirmed with the original provider before sharing the dataset.

The custom scoring function uses fixed thresholds for word count, sentence count, and average sentence length. It is not a trained machine-learning model, has not been validated against human ratings, and does not evaluate factual accuracy, reasoning, or relevance to a prompt. Its labels are demonstration outputs rather than validated assessments of writing quality.

The original preprocessing also assigns random grade values where an assignment name does not specify a grade. These values are not observed student grades and are not used in the displayed filters or scoring function.

## Project files

- `app.R`: application UI and server
- `R/scoring_functions.R`: text statistics and heuristic scoring
- `about.Rmd` and `about.html`: in-app project description
- `essay-scorer.Rproj`: RStudio project
- `data/README.md`: local dataset setup

# Essay Scoring App

An interactive R Shiny app for exploring essay scores and analyzing custom writing. Built by Xiaoxi Chen for STAT 385 at UIUC, Fall 2025.

## Overview

![Essay scoring dashboard with score distribution and custom essay analysis](docs/images/essay-scoring-overview.jpg)

- Explore score distributions by assignment and score range.
- Browse essay previews and summary statistics.
- Analyze custom text with word counts, sentence statistics, and a rule-based score from 1–6.

**Scoring:** Uses text-length and sentence-length heuristics, rather than a trained machine-learning model.

## Run locally

Place the original dataset at `data/essays.csv` (not included). See [data setup](data/README.md) for required columns. From the project directory, run:

```r
install.packages(c("shiny", "shinythemes", "DT", "ggplot2", "dplyr", "readr", "stringr"))
shiny::runApp()
```

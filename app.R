# Load required libraries
library(shiny)
library(shinythemes)
library(DT)
library(ggplot2)
library(dplyr)
library(readr)
library(stringr)

# Source helper functions
source("R/scoring_functions.R")

# Load data
essays_data <- read_csv("data/essays.csv", show_col_types = FALSE)

# Clean and prepare data
essays_data <- essays_data %>%
  # Create essay_set from assignment if needed
  mutate(
    essay_set = as.numeric(as.factor(assignment)),
    holistic_score = score,
    source_text = coalesce(full_text, source_text_1, "No text available"),
    grade = case_when(
      str_detect(assignment, "grade") ~ as.numeric(str_extract(assignment, "\\d+")),
      TRUE ~ sample(6:12, n(), replace = TRUE)  # Assign random grade if not specified
    )
  ) %>%
  filter(!is.na(holistic_score), nchar(source_text) > 10)

# Sample some data for better performance (optional)
if(nrow(essays_data) > 2000) {
  set.seed(42)
  essays_data <- essays_data %>% sample_n(2000)
}

# Define UI
ui <- navbarPage(
  "Essay Scoring Application",
  theme = shinythemes::shinytheme("flatly"),
  
  # Main Analysis Tab
  tabPanel("Essay Analysis",
    sidebarLayout(
      sidebarPanel(
        width = 4,
        h3("Input Controls"),
        
        # Input 1: Assignment Selection
        selectInput("essay_set", 
                   "Select Assignment:",
                   choices = sort(unique(essays_data$assignment)),
                   selected = essays_data$assignment[1]),
        
        # Input 2: Score Range (conditional on assignment)
        uiOutput("score_selector"),
        
        # Input 3: Custom Essay Text Input
        textAreaInput("custom_essay", 
                     "Enter Custom Essay Text:",
                     value = "Type your essay here to get an automated score...",
                     height = "200px",
                     resize = "vertical"),
        
        br(),
        actionButton("analyze_btn", "Analyze Essay", 
                    class = "btn-primary btn-lg")
      ),
      
      mainPanel(
        width = 8,
        fluidRow(
          column(12,
            h2("Essay Analysis Results"),
            br()
          )
        ),
        
        fluidRow(
          # Output 1: Graphical Output (ggplot2)
          column(8,
            h3("Score Distribution"),
            plotOutput("score_plot", height = "400px")
          ),
          
          # Custom Essay Analysis Results
          column(4,
            h3("Custom Essay Analysis"),
            uiOutput("custom_analysis_display")
          )
        ),
        
        br(),
        
        fluidRow(
          column(12,
            h3("Selected Essays"),
            DT::dataTableOutput("filtered_essays_table")
          )
        )
      )
    )
  ),
  
  # Statistics Tab
  tabPanel("Statistics",
    fluidRow(
      column(12,
        h2("Essay Statistics"),
        br(),
        DT::dataTableOutput("essay_stats_table")
      )
    )
  ),
  
  # About Tab
  tabPanel("About",
    includeHTML("about.html")
  )
)

# Define Server Logic
server <- function(input, output, session) {
  
  # Reactive: Filter essays based on assignment
  filtered_essays <- reactive({
    essays_data %>%
      filter(assignment == input$essay_set)
  })
  
  # Dynamic UI: Score range selector based on assignment
  output$score_selector <- renderUI({
    available_scores <- filtered_essays() %>%
      pull(holistic_score) %>%
      unique() %>%
      sort()
    
    sliderInput("score_range",
               "Score Range:",
               min = min(available_scores, na.rm = TRUE),
               max = max(available_scores, na.rm = TRUE),
               value = c(min(available_scores, na.rm = TRUE), max(available_scores, na.rm = TRUE)),
               step = 1)
  })
  
  # Reactive: Further filter by score range if selected
  score_filtered_essays <- reactive({
    req(input$score_range)
    
    filtered_essays() %>%
      filter(holistic_score >= input$score_range[1] & holistic_score <= input$score_range[2])
  })
  
  # Reactive value to store custom essay analysis results
  custom_analysis_results <- reactiveVal(NULL)
  
  # Button click event for analyzing custom essay
  observeEvent(input$analyze_btn, {
    req(input$custom_essay)
    
    if(nchar(trimws(input$custom_essay)) > 10) {
      stats <- calculate_essay_stats(input$custom_essay)
      predicted_score <- predict_essay_score(
        stats$word_count,
        stats$sentence_count, 
        stats$avg_words_per_sentence
      )
      quality <- categorize_essay_quality(predicted_score)
      
      result <- data.frame(
        Essay_Type = "Custom Essay",
        Predicted_Score = predicted_score,
        Quality_Category = quality,
        Word_Count = stats$word_count,
        Sentence_Count = stats$sentence_count,
        Character_Count = stats$character_count,
        Avg_Words_Per_Sentence = stats$avg_words_per_sentence,
        Avg_Chars_Per_Word = stats$avg_chars_per_word
      )
      
      # Store the analysis results
      custom_analysis_results(result)
      
      # Show notification
      showNotification("✅ Custom essay analysis completed! Check the results in the right panel.", 
                      type = "message", duration = 5)
    } else {
      showNotification("Please enter a longer essay (more than 10 characters).", type = "warning")
    }
  })
  
  # Reactive: Get custom essay analysis
  custom_essay_analysis <- reactive({
    custom_analysis_results()
  })
  
  # Output: Custom Analysis Display
  output$custom_analysis_display <- renderUI({
    analysis <- custom_essay_analysis()
    
    if(is.null(analysis)) {
      div(
        style = "padding: 20px; border: 2px dashed #ccc; text-align: center; color: #666;",
        p("No custom essay analyzed yet."),
        p("Enter text and click 'Analyze Essay' to see results here.")
      )
    } else {
      div(
        style = "padding: 15px; border: 2px solid #3498db; border-radius: 8px; background-color: #f8f9fa;",
        h4("Analysis Results", style = "color: #2c3e50; margin-top: 0;"),
        
        div(
          style = "margin: 10px 0;",
          strong("Predicted Score: "), 
          span(analysis$Predicted_Score, style = "color: #e74c3c; font-size: 18px; font-weight: bold;")
        ),
        
        div(
          style = "margin: 10px 0;",
          strong("Quality: "), 
          span(analysis$Quality_Category, style = "color: #27ae60; font-weight: bold;")
        ),
        
        hr(),
        
        div(
          style = "margin: 5px 0;",
          strong("Word Count: "), analysis$Word_Count
        ),
        
        div(
          style = "margin: 5px 0;",
          strong("Sentences: "), analysis$Sentence_Count
        ),
        
        div(
          style = "margin: 5px 0;",
          strong("Avg Words/Sentence: "), analysis$Avg_Words_Per_Sentence
        )
      )
    }
  })
  
  # Output 1: Score Distribution Plot (ggplot2)
  output$score_plot <- renderPlot({
    data_to_plot <- score_filtered_essays()
    
    if(nrow(data_to_plot) > 0) {
      # Create score distribution plot
      ggplot(data_to_plot, aes(x = factor(holistic_score))) +
        geom_bar(fill = "#3498db", alpha = 0.7, color = "white") +
        labs(
          title = paste("Score Distribution for", input$essay_set),
          x = "Holistic Score",
          y = "Number of Essays"
        ) +
        theme_minimal() +
        theme(
          plot.title = element_text(size = 14, face = "bold"),
          axis.text = element_text(size = 12),
          axis.title = element_text(size = 12)
        ) +
        scale_x_discrete(drop = FALSE)
    } else {
      # Empty plot if no data
      ggplot() + 
        geom_blank() +
        labs(title = "No data available for selected filters") +
        theme_minimal()
    }
  })
  
  # Output 2: Essay Statistics Table
  output$essay_stats_table <- DT::renderDataTable({
    
    # Combine dataset stats with custom essay analysis if available
    dataset_stats <- score_filtered_essays() %>%
      summarise(
        Essay_Type = "Dataset Summary",
        Avg_Score = round(mean(holistic_score, na.rm = TRUE), 2),
        Total_Essays = n(),
        Min_Score = min(holistic_score, na.rm = TRUE),
        Max_Score = max(holistic_score, na.rm = TRUE),
        .groups = 'drop'
      )
    
    # If custom essay analysis is available, add it
    if(!is.null(custom_essay_analysis())) {
      custom_stats <- custom_essay_analysis() %>%
        select(Essay_Type, Predicted_Score, Quality_Category, Word_Count, Sentence_Count)
      
      # Create a combined summary
      combined_stats <- bind_rows(
        data.frame(
          Metric = c("Dataset Essays", "Custom Essay Score", "Custom Essay Quality", 
                    "Custom Word Count", "Custom Sentences"),
          Value = c(
            paste(dataset_stats$Total_Essays, "essays"),
            if(nrow(custom_stats) > 0) custom_stats$Predicted_Score[1] else "N/A",
            if(nrow(custom_stats) > 0) custom_stats$Quality_Category[1] else "N/A",
            if(nrow(custom_stats) > 0) custom_stats$Word_Count[1] else "N/A",
            if(nrow(custom_stats) > 0) custom_stats$Sentence_Count[1] else "N/A"
          )
        )
      )
    } else {
      combined_stats <- data.frame(
        Metric = c("Total Essays", "Average Score", "Score Range"),
        Value = c(
          dataset_stats$Total_Essays,
          dataset_stats$Avg_Score,
          paste(dataset_stats$Min_Score, "-", dataset_stats$Max_Score)
        )
      )
    }
    
    DT::datatable(
      combined_stats,
      options = list(
        dom = 't',
        pageLength = 10,
        searching = FALSE,
        ordering = FALSE
      ),
      rownames = FALSE
    )
  })
  
  # Additional output: Filtered Essays Table
  output$filtered_essays_table <- DT::renderDataTable({
    data_to_show <- score_filtered_essays() %>%
      select(essay_id, assignment, holistic_score, source_text) %>%
      mutate(
        source_text = str_trunc(source_text, 100),
        essay_id = as.character(essay_id)
      ) %>%
      arrange(desc(holistic_score))
    
    DT::datatable(
      data_to_show,
      options = list(
        pageLength = 5,
        scrollX = TRUE,
        dom = 'ltip'
      ),
      colnames = c("Essay ID", "Assignment", "Score", "Text Preview"),
      rownames = FALSE
    )
  })
}

# Run the application
shinyApp(ui = ui, server = server)

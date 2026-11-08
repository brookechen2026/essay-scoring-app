# Essay Scoring Helper Functions

# Function to calculate basic essay statistics
calculate_essay_stats <- function(text) {
  # Basic text analysis
  word_count <- length(unlist(strsplit(text, "\\s+")))
  sentence_count <- length(unlist(strsplit(text, "[.!?]+")))
  char_count <- nchar(text)
  
  # Calculate averages
  avg_words_per_sentence <- ifelse(sentence_count > 0, word_count / sentence_count, 0)
  avg_chars_per_word <- ifelse(word_count > 0, char_count / word_count, 0)
  
  return(data.frame(
    word_count = word_count,
    sentence_count = sentence_count,
    character_count = char_count,
    avg_words_per_sentence = round(avg_words_per_sentence, 2),
    avg_chars_per_word = round(avg_chars_per_word, 2)
  ))
}

# Function to predict essay score based on simple heuristics
predict_essay_score <- function(word_count, sentence_count, avg_words_per_sentence) {
  # Simple scoring algorithm based on length and complexity
  base_score <- 1
  
  # Word count contribution (0-2 points)
  if (word_count >= 300) {
    base_score <- base_score + 2
  } else if (word_count >= 150) {
    base_score <- base_score + 1
  }
  
  # Sentence structure contribution (0-2 points)
  if (avg_words_per_sentence >= 15 && avg_words_per_sentence <= 25) {
    base_score <- base_score + 2
  } else if (avg_words_per_sentence >= 10) {
    base_score <- base_score + 1
  }
  
  # Sentence count contribution (0-1 point)
  if (sentence_count >= 8) {
    base_score <- base_score + 1
  }
  
  return(min(base_score, 6))  # Cap at 6
}

# Function to categorize essay quality
categorize_essay_quality <- function(score) {
  if (score >= 5) {
    return("Excellent")
  } else if (score >= 4) {
    return("Good")
  } else if (score >= 3) {
    return("Average")
  } else if (score >= 2) {
    return("Below Average")
  } else {
    return("Poor")
  }
}

# Column name transformation function
transform_column_names <- function(names) {
  # CamelCase to snake_case
  names <- gsub("([a-z])([A-Z])", "\\1_\\2", names)
  
  # Convert to lowercase
  names <- tolower(names)
  
  # Replace + with _plus
  names <- gsub("\\+", "_plus_", names)

  # Replace K-BB with k_minus_bb
  names <- gsub("k_bb", "k_minus_bb", names)

  # Replace trailing - with _minus
  names <- gsub("\\-$", "_minus", names)
  
  # Replace + with _plus
  names <- gsub("\\%", "_pct", names)
  
  # Replace - with _
  names <- gsub("-", "_", names)
  
  # Replace special characters with _
  names <- gsub("[^a-z0-9_]", "_", names)
  
  # Remove multiple underscores
  names <- gsub("_+", "_", names)
  
  # Remove trailing underscores
  names <- gsub("_$", "", names)
  
  # Handle columns starting with numbers
  names <- ifelse(grepl("^1b$", names), "singles", names)
  names <- ifelse(grepl("^2b$", names), "doubles", names)
  names <- ifelse(grepl("^3b$", names), "triples", names)
  
  # Handle PostgreSQL reserved words
  names <- ifelse(names == "pos", "pos_num", names)
  names <- ifelse(names == "position", "pos", names)
  
  return(names)
}

# Test with your columns
test_columns <- c("Season", "team_name", "Bats", "xMLBAMID", "PlayerNameRoute", "PlayerName", 
                  "playerid", "Age", "AgeRng", "SeasonMin", "SeasonMax", "G", "AB", "PA", "H", 
                  "1B", "2B", "3B", "HR", "R", "RBI", "BB", "SO", "SB", "CS", "AVG", "BB_pct", 
                  "K_pct", "BB_K", "OBP", "SLG", "OPS", "ISO", "BABIP", "TTO_pct", "wOBA", 
                  "wRAA", "wRC", "Batting", "Fielding", "Replacement", "Positional", "wLeague", 
                  "Defense", "Offense", "RAR", "WAR", "WAROld", "BaseRunning", "Spd", "wRC+", 
                  "wBsR", "AVG+", "BB_pct+", "K_pct+", "OBP+", "SLG+", "ISO+", "BABIP+", 
                  "rFTeamV", "rBTeamV", "rTV", "Events", "Q", "TG", "TPA", "position", 
                  "team_name_abb", "teamid", "Pos", "HBP", "SH", "GDP", "IBB", "SF", "WPA", 
                  "WPA-", "WPA+", "RE24", "REW", "pLI", "PH", "WPA/LI", "Clutch", "phLI", 
                  "GB", "FB", "LD", "IFFB", "Pitches", "Balls", "Strikes", "IFH", "BU", "BUH", 
                  "GB/FB", "LD%", "GB%", "FB%", "IFFB%", "HR/FB", "IFH%", "BUH%", "Dollars", 
                  "FB%1", "FBv", "SL%", "SLv", "CB%", "CBv", "CH%", "CHv", "SF%", "SFv", 
                  "XX%", "wFB", "wSL", "wCB", "wCH", "wSF", "wFB/C", "wSL/C", "wCB/C", 
                  "wCH/C", "wSF/C", "O-Swing%", "Z-Swing%", "Swing%", "O-Contact%", 
                  "Z-Contact%", "Contact%", "Zone%", "F-Strike%", "SwStr%", "CStr%", 
                  "C+SwStr%", "Pull", "Cent", "Oppo", "Soft", "Med", "Hard", "bipCount", 
                  "Pull%", "Cent%", "Oppo%", "Soft%", "Med%", "Hard%", "UBR", "GDPRuns", 
                  "LD%+", "GB%+", "FB%+", "HR/FB%+", "Pull%+", "Cent%+", "Oppo%+", "Soft%+", 
                  "Med%+", "Hard%+", "KN%", "KNv", "wKN", "wKN/C", "PO%", "CT%", "CTv", 
                  "wCT", "wCT/C", "DGV")

transformed <- transform_column_names(test_columns)
cat("Original -> Transformed:\n")
for(i in 1:length(test_columns)) {
  cat(sprintf("%-15s -> %s\n", test_columns[i], transformed[i]))
}
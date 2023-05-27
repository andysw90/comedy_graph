library(tidyverse)

imdb_dict <- list("Brooklyn 99"="tt2467372",
                  "The Office"="tt0386676",
                  "Parks and Rec"="tt1266020",
                  "Superstore"="tt4477976",
                  "New Girl"="tt1826940",
                  "Modern Family"="tt1442437",
                  "Good Place"="tt4955642",
                  "Veep"="tt1759761")

get_data <- function(program){
  # program <- "Brooklyn 99"
  imdb_code <- imdb_dict[program]
  imdb_url <- paste0("https://www.imdb.com/title/",imdb_code,"/fullcredits/")
  imdb_page <- read_html(imdb_url)
  imdb_cast_raw <- 
    imdb_page %>%
    html_nodes("table") %>%
    .[3] %>%
    html_table()
  imdb_cast_raw <- imdb_cast_raw[[1]]
  imdb_cast_raw <- imdb_cast_raw[-which(imdb_cast_raw[,4]==""),-c(1,3)]
  imdb_cast_raw_split <- strsplit(as.character(imdb_cast_raw$X4),split="\n")
  character_names <- sapply(imdb_cast_raw_split,
                            "[[",1)
  episode_count <- suppressWarnings(as.numeric(sapply(imdb_cast_raw_split,
                                                      function(x) trimws(strsplit(x[2],
                                                                                  split = " episode")[[1]][1]))))
  cast_out <- data.frame(character = character_names,
                         actor = imdb_cast_raw$X2,
                         actorId = tolower(gsub(pattern = " ",
                                                replacement = "",
                                                x = gsub("[[:punct:]]", "", imdb_cast_raw$X2))),
                         program = program,
                         programId = tolower(gsub(pattern = " ",
                                                  replacement = "",
                                                  x = program)),
                         episodes = episode_count,stringsAsFactors = FALSE)
  episode_NA <- which(is.na(cast_out$episodes))
  if(length(episode_NA)>0){
    cast_out <- cast_out[-which(is.na(cast_out$episodes)),]
  }
  return(cast_out)
}
programs <- c("Brooklyn 99","The Office",
              "Parks and Rec","Superstore",
              "New Girl","Modern Family",
              "Veep","Good Place")
casts <- sapply(programs,get_data,simplify = FALSE,USE.NAMES = TRUE)
casts_collated <- do.call(rbind,casts)

prolific_actors <- casts_collated$actor[which(casts_collated$episodes>2)]
casts_collated <- casts_collated[which(casts_collated$actor %in% prolific_actors),]
dim(casts_collated)
# casts_collated2 <- casts_collated[casts_collated$episodes>1,]
rownames(casts_collated) <- NULL

# Make nodes
programs_nodes <- data.frame(`programId:ID` = tolower(gsub(pattern = " ",
                                                           replacement = "",
                                                           x = programs)),
                             program = programs,
                             `:LABEL` = "Show",
                             stringsAsFactors = FALSE,check.names = FALSE)
all_actors <- sort(unique(unlist(lapply(casts,"[[","actor"))))
actor_nodes <- data.frame(`actorId:ID` = tolower(gsub(pattern = " ",
                                                      replacement = "",
                                                      x = gsub("[[:punct:]]", "", all_actors))),
                          actor = all_actors,
                          `:LABEL` = "Actor",
                          stringsAsFactors = FALSE,check.names = FALSE)

# Make edges
edges <- data.frame(`:START_ID` = casts_collated$actorId,
                    character = casts_collated$character,
                    episode_count = casts_collated$episodes,
                    `:END_ID` = casts_collated$programId,
                    `:TYPE` = "ACTED_IN",stringsAsFactors = FALSE,check.names = FALSE)

dbs_location <- "/Users/andrewwalker/Library/Application\ Support/com.Neo4j.Relate/Data/dbmss/dbms-1a297352-f795-4d95-a478-d1ef53f106e0/"
dbs_location_esc <- "/Users/andrewwalker/Library/Application\\ Support/com.Neo4j.Relate/Data/dbmss/dbms-1a297352-f795-4d95-a478-d1ef53f106e0/"
formatted_time <- gsub(" ",replacement = "",x = gsub("[[:punct:]]", "", Sys.time()))

database_name <- paste0("DB",formatted_time)
#paste0(paste0(gsub(pattern = " ",
#replacement = "",
#  x = programs),collapse = "and"),"-",formatted_time)
message(paste0("Go to neo4j and make one called: ",database_name))
# Write files
write_csv(programs_nodes,paste0(dbs_location,"import/programs.csv"))
write_csv(actor_nodes,paste0(dbs_location,"import/actors.csv"))
write_csv(edges,paste0(dbs_location,"import/edges.csv"))

import_call <- paste0("export JAVA_HOME=`/usr/libexec/java_home -v 11.0.13`; ",
                      dbs_location_esc,"bin/neo4j-admin import --database='",database_name,"'",
                      " --nodes=",paste0(dbs_location_esc,"import/programs.csv"),
                      " --nodes=",paste0(dbs_location_esc,"import/actors.csv"),
                      " --relationships=",paste0(dbs_location_esc,"import/edges.csv"))
sys_out <- system(import_call, intern= TRUE)

## Find multi-linked actors
# match (s:Show)-[]-(a:Actor)-[]-(s2:Show) return s,a,s2

## Find highly linked actors
# match (a:Actor)-[]-(s:Show)
# with a,count(s) as rels,collect(s) as shows
# where rels > 1
# return a,shows,rels

# match (s:Show)-[]-(a:Actor)-[]-(s2:Show)-[]-(s3:Show) return s,a,s2,a,s3

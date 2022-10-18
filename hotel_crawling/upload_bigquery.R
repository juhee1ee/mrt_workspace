#### 항공 프로모션 copy, TNA에 맞게 수정해야함
######################################
#          Listly Get Data           #
######################################

library(readr)
library(httr)
library(rvest)
library(openssl)
library(stringr)
library(RCurl)
library(DBI)
library(data.table)
library(dplyr)
library(googlesheets4)
library(lubridate)
library(bigrquery)
library(gargle)

##########################################
# Connect to bigquery

bigauth <- "/home/chulmin/mrtdata-647838e9df70.json"
# authenticate
bigrquery::bq_auth(path = bigauth)
# set my project ID and dataset name
project_id <- 'mrtdata'
dataset_name <- 'business'

bq_business <- dbConnect(
  bigrquery::bigquery(),
  project = "mrtdata",
  dataset = "business"
)




# 테이블 전처리
result_table1 <- result_table[, c(12, 15)]
colnames(result_table1) <- c("url","hotel_nm", "first_price", "second_price")

result_table1$checkin<- regmatches(result_table1$url, regexpr("checkIn[=][0-9]+[-][0-9]+[-][0-9]+", result_table1$url))
result_table1$checkin <- gsub("checkIn=", "", result_table1$checkin)
result_table1$checkout<- regmatches(result_table1$url, regexpr("checkOut[=][0-9]+[-][0-9]+[-][0-9]+", result_table1$url))
result_table1$checkout <- gsub("checkOut=", "", result_table1$checkout)

result_table1$city<- regmatches(result_table1$url, regexpr("place%3A[_a-zA-Z]+&", result_table1$url))
result_table1$city <- gsub("place%3A", "", result_table1$city)
result_table1$city <- gsub("&", "", result_table1$city)

result_table1$first_price <- ifelse(result_table1$first_price == "", result_table1$second_price, result_table1$first_price)
result_table1$first_price <- gsub("원~", "", result_table1$first_price)
result_table1$second_price <- gsub("원~", "", result_table1$second_price)
result_table1$first_price <- gsub(",", "", result_table1$first_price)
result_table1$second_price <- gsub(",", "", result_table1$second_price)
result_table1$min_price <- result_table1$first_price 

result_table1$basis_date <- Sys.Date()
result_table1$updated_at <- Sys.time()

result_table1 <- result_table1 %>%
  select(basis_date, city, hotel_nm, checkin, checkout, min_price, updated_at)


###################################
# Update to bigquery table

# Need to create table
table_nm <- 'hotel_price_daily_crawling'

# Bigquery Table
keyword_ranking <- bq_table(project = project_id, dataset = dataset_name, table = table_nm)

colNms <- colnames(result_final_tb2)
classNm <- c("date", "string", "string", "date","date", "numeric", "datetime")

# Create bigquery table fields
table_fields <- lapply(1:length(colNms), function(x) bq_field(colNms[x], classNm[x]))

# Update Missing data
uploaded <- bq_table_upload(x = keyword_ranking, values = result_final_tb2,
                            fields = table_fields,
                            create_disposition='CREATE_IF_NEEDED', write_disposition='WRITE_APPEND')

# If failed then run again
if(uploaded$table == table_nm) {
  print(paste0("Table has been updated at ", Sys.time()))
} else {
  # Update Missing data
  uploaded <- bq_table_upload(x = schedule_detail, values = result,
                              fields = table_fields,
                              create_disposition='CREATE_IF_NEEDED', write_disposition='WRITE_APPEND')
}
